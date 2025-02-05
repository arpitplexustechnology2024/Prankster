//
//  CoverPrankVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import Alamofire
import AVFoundation
import Photos
import GoogleMobileAds

struct CustomCover {
    let image: UIImage
    let imageUrl: String?
    
    init(image: UIImage, imageUrl: String? = nil) {
        self.image = image
        self.imageUrl = imageUrl
    }
}

@available(iOS 15.0, *)
class CoverPrankVC: UIViewController {
    
    @IBOutlet weak var chipSelector: ChipSelectorView!
    @IBOutlet weak var emojiCoverAllCollectionView: UICollectionView!
    @IBOutlet weak var emojiCoverSlideCollectionview: UICollectionView!
    @IBOutlet weak var addcoverButton: UIButton!
    @IBOutlet weak var addcoverView: UIView!
    @IBOutlet weak var coverImageLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var suggestionCollectionView: UICollectionView!
    
    @IBOutlet weak var searchBarView: UIView!
    
    private var suggestions: [String] = []
    
    private var shouldShowGIF = true
    
    var buttonType: HomeVC.ButtonType?
    
    private var tagViewModule : TagViewModule!
    let interstitialAdUtility = InterstitialAdUtility()
    private let adsViewModel = AdsViewModel()
    
    init(tagViewModule: TagViewModule) {
        self.tagViewModule = tagViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tagViewModule = TagViewModule(apiService: TagAPIManger.shared)
    }
    
    var viewType: CoverViewType = .audio
    private var selectedCoverIndex: Int?
    var customCovers: [CustomCover] = []
    var selectedCustomCoverIndex: IndexPath?
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private let viewModel = EmojiViewModel()
    private var isSearchActive = false
    private var filteredEmojiCoverPages: [CoverPageData] = []
    private var currentDataSource: [CoverPageData] {
        return isSearchActive ? filteredEmojiCoverPages : viewModel.emojiCoverPages
    }
    var isLoading = true
    private let categoryId: Int = 4
    private var isLoadingMore = false
    private var selectedIndex: Int = 0
    private var nativeMediumAdUtility: NativeMediumAdUtility?
    var preloadedNativeAdView: GADNativeAdView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadSavedCovers()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        self.checkInternetAndFetchData()
        self.filteredEmojiCoverPages = viewModel.emojiCoverPages
        PremiumManager.shared.clearTemporaryUnlocks()
        
        NotificationCenter.default.addObserver( self, selector: #selector(handlePremiumContentUnlocked), name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
    }
    
    private func preloadNativeAd() {
        if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
            print("Preloading Native Ad with ID: \(nativeAdID)")
            // Create a temporary container for preloading
            let tempAdContainer = UIView(frame: .zero)
            
            nativeMediumAdUtility = NativeMediumAdUtility(
                adUnitID: nativeAdID,
                rootViewController: self,
                nativeAdPlaceholder: tempAdContainer
            ) { [weak self] success in
                if success {
                    // Store the preloaded ad view
                    if let adView = self?.nativeMediumAdUtility?.nativeAdView {
                        self?.preloadedNativeAdView = adView
                    }
                } else {
                    print("Failed to preload native ad")
                }
            }
        } else {
            print("No Native Ad ID found for preloading")
        }
    }
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            let currentIndex = self.selectedIndex
            
            self.emojiCoverAllCollectionView.reloadData()
            self.emojiCoverSlideCollectionview.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            
            self.selectedIndex = currentIndex
        }
    }
    
    func setupUI() {
        self.addcoverView.layer.cornerRadius = 10
        
        // Initial setup: Hide certain elements
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        searchMainView.isHidden = true
        searchMainViewHeightConstarints.constant = 0
        searchBarView.isHidden = true
        self.coverImageLabel.isHidden = false
        
        // Set the corner radius initially
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        
        view.bringSubviewToFront(searchMainView)
        view.bringSubviewToFront(searchBarView)
        
        // Add this to your existing setupUI method
        if let searchMainViewIndex = view.subviews.firstIndex(of: searchMainView) {
            for subview in view.subviews {
                if subview is NoDataView || subview is NoInternetView {
                    view.insertSubview(subview, at: searchMainViewIndex - 1)
                }
            }
        }
        
        // Configure the collection view layout for horizontal scrolling
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal  // Horizontal scrolling
        layout.minimumInteritemSpacing = 10  // Space between items
        layout.minimumLineSpacing = 10      // Space between rows
        
        // Add padding to the left side of the collection view
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        suggestionCollectionView.collectionViewLayout = layout
        
        suggestionCollectionView.setCollectionViewLayout(layout, animated: true)
        
        // Set CollectionView delegate and datasource
        suggestionCollectionView.delegate = self
        suggestionCollectionView.dataSource = self
        
        // Register the custom UICollectionViewCell class or Nib
        suggestionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SuggestionCell")
        
        searchBar.delegate = self
        searchBar.addTarget(self, action: #selector(searchTextFieldDidChange(_:)), for: .editingChanged)
        searchBar.returnKeyType = .search
        searchBar.placeholder = "Search cover image"
        
        if let searchBar = searchBar {
            let placeholderText = "Search cover image"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
        
        chipSelector.onSelectionChanged = { [weak self] selectedType in
            guard let self = self else { return }
            
            if selectedType == "Add cover image 📸" {
                self.addcoverView.isHidden = false
                self.noInternetView.isHidden = true
                self.noDataView.isHidden = true
                self.searchBarView.isHidden = true
                self.coverImageLabel.isHidden = false
                
                emojiCoverAllCollectionView.reloadData()
                emojiCoverSlideCollectionview.reloadData()
                
                // Add the new condition check here
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.customCovers.isEmpty && !self.shouldShowGIF {
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                        self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.selectedIndex = 0
                    }
                }
                
            } else {
                // બીજી chip select થાય ત્યારે internet check કરો
                if self.isConnectedToInternet() {
                    // Internet છે તો normal flow
                    self.addcoverView.isHidden = true
                    self.searchBarView.isHidden = false
                    self.coverImageLabel.isHidden = true
                    
                    emojiCoverAllCollectionView.reloadData()
                    emojiCoverSlideCollectionview.reloadData()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: 0, section: 0)
                            self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                            self.selectedIndex = 0
                        }
                    }
                } else {
                    // Internet નથી તો No Internet View બતાવો
                    self.addcoverView.isHidden = true
                    self.searchBarView.isHidden = false
                    self.coverImageLabel.isHidden = true
                    self.showNoInternetView()
                    
                    // Empty arrays set કરો જેથી UI crash ન થાય
                    self.viewModel.emojiCoverPages = []
                    self.filteredEmojiCoverPages = []
                    
                    emojiCoverAllCollectionView.reloadData()
                    emojiCoverSlideCollectionview.reloadData()
                }
            }
        }
        
        if isConnectedToInternet() {
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
            } else {
                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                    print("Interstitial Ad ID: \(interstitialAdID)")
                    interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
                } else {
                    print("No Interstitial Ad ID found")
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllCoverPages()
            self.fetchTagData()
            self.preloadNativeAd()
            self.noInternetView?.isHidden = true
            self.hideNoDataView()
            // Ensure search views stay on top
            self.view.bringSubviewToFront(self.searchBarView)
            self.view.bringSubviewToFront(self.searchMainView)
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
            // Ensure search views stay on top
            self.view.bringSubviewToFront(self.searchBarView)
            self.view.bringSubviewToFront(self.searchMainView)
        }
    }
    
    private func fetchTagData() {
        tagViewModule.fetchTag(id: "4") { [weak self] result in
            switch result {
            case .success(let tagResponse):
                // Use the array directly
                self?.suggestions = tagResponse.data
                self?.suggestionCollectionView.reloadData()
            case .failure(let error):
                print("Error fetching tags: \(error.localizedDescription)")
                // Handle error appropriately
                self?.searchMainViewHeightConstarints.constant = 0
                self?.searchMainView.isHidden = true
                self?.popularLabel.isHidden = true
                self?.suggestionCollectionView.isHidden = true
                self?.cancelButton.isHidden = true
                
                self?.searchMainView.layer.cornerRadius = 10
                self?.searchBarView.layer.cornerRadius = 10
                self?.searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                
                UIView.animate(withDuration: 0.3) {
                    self?.view.layoutIfNeeded()
                }
            }
        }
    }
    
    private func setupCollectionView() {
        self.emojiCoverSlideCollectionview.delegate = self
        self.emojiCoverSlideCollectionview.dataSource = self
        self.emojiCoverAllCollectionView.delegate = self
        self.emojiCoverAllCollectionView.dataSource = self
        self.emojiCoverAllCollectionView.isPagingEnabled = true
        self.emojiCoverAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.emojiCoverSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
    }
    
    func fetchAllCoverPages() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        viewModel.fetchEmojiCoverPages { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingMore = false
                if success {
                    if self.viewModel.emojiCoverPages.isEmpty {
                        self.hideSkeletonLoader()
                        self.showNoDataView()
                    } else {
                        self.hideSkeletonLoader()
                        self.hideNoDataView()
                        self.emojiCoverAllCollectionView.reloadData()
                        self.emojiCoverSlideCollectionview.reloadData()
                    }
                } else if let errorMessage = self.viewModel.errorMessage {
                    self.hideSkeletonLoader()
                    self.showNoDataView()
                    print("Error fetching all cover pages: \(errorMessage)")
                }
            }
        }
    }
    
    private func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        
        // Insert noDataView below searchMainView
        if let index = view.subviews.firstIndex(of: searchMainView) {
            self.view.insertSubview(noDataView, belowSubview: searchMainView)
        } else {
            self.view.addSubview(noDataView)
        }
        
        //        self.view.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: chipSelector.bottomAnchor),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        
        // Insert noInternetView below searchMainView
        if let index = view.subviews.firstIndex(of: searchMainView) {
            self.view.insertSubview(noInternetView, belowSubview: searchMainView)
        } else {
            self.view.addSubview(noInternetView)
        }
        
        //  self.view.addSubview(noInternetView)
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: backButton.bottomAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            hideNoDataView()
            checkInternetAndFetchData()
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
            } else {
                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                    print("Interstitial Ad ID: \(interstitialAdID)")
                    interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
                } else {
                    print("No Interstitial Ad ID found")
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    private func showNoDataView() {
        noDataView?.isHidden = false
    }
    
    private func hideNoDataView() {
        noDataView?.isHidden = true
    }
    
    func showSkeletonLoader() {
        isLoading = true
        self.emojiCoverAllCollectionView.reloadData()
        self.emojiCoverSlideCollectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        self.emojiCoverAllCollectionView.reloadData()
        self.emojiCoverSlideCollectionview.reloadData()
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    private func setupSwipeGesture() {
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.edges = .left
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    private func filterContent(with searchText: String) {
        isSearchActive = !searchText.isEmpty
        
        if searchText.isEmpty {
            filteredEmojiCoverPages = viewModel.emojiCoverPages
        } else {
            filteredEmojiCoverPages = viewModel.emojiCoverPages.filter { coverPage in
                let nameMatch = coverPage.coverName.lowercased().contains(searchText.lowercased())
                let tagMatch = coverPage.tagName.contains { tag in
                    tag.lowercased().contains(searchText.lowercased())
                }
                return nameMatch || tagMatch
            }
        }
        
        DispatchQueue.main.async {
            self.selectedIndex = 0
            
            self.emojiCoverAllCollectionView.reloadData()
            self.emojiCoverSlideCollectionview.reloadData()
            
            // Make sure searchMainView stays on top when showing no data
            if self.filteredEmojiCoverPages.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
                self.view.bringSubviewToFront(self.searchBarView)
                self.view.bringSubviewToFront(self.searchMainView)
            } else {
                self.hideNoDataView()
                
                if !self.filteredEmojiCoverPages.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    if self.emojiCoverAllCollectionView.numberOfItems(inSection: 0) > 0 {
                        self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if self.emojiCoverSlideCollectionview.numberOfItems(inSection: 0) > 0 {
                        self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }
    
    @IBAction func btnAddCoverImageTapped(_ sender: UIButton) {
        self.shouldShowGIF = false
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            self.shouldShowGIF = false
            self.addCoverClick()
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shouldShowGIF = false
                self?.addCoverClick()
            }
        }
    }
    
    private func addCoverClick() {
        let popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CoverPopupVC") as! CoverPopupVC
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        
        popupVC.cameraCallback = { [weak self] in
            self?.btnCameraTapped()
        }
        
        popupVC.downloaderCallback = { [weak self] in
            guard let self = self else { return }
            let downloaderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageDownloaderBottom") as! ImageDownloaderBottom
            downloaderVC.modalPresentationStyle = .pageSheet
            
            if let sheet = downloaderVC.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            downloaderVC.imageDownloadedCallback = { [weak self] (downloadedImage, imageUrl) in
                guard let self = self else { return }
                
                if let image = downloadedImage {
                    let customCover = CustomCover(image: image, imageUrl: imageUrl)
                    self.customCovers.insert(customCover, at: 0)
                    self.selectedCoverIndex = 0
                    self.saveCovers()
                    
                    DispatchQueue.main.async {
                        self.emojiCoverSlideCollectionview.reloadData()
                        self.emojiCoverAllCollectionView.reloadData()
                        
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.selectedCustomCoverIndex = indexPath
                        self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        self.emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
            self.present(downloaderVC, animated: true)
        }
        
        popupVC.galleryCallback = { [weak self] in
            self?.btnGalleryTapped()
        }
        self.present(popupVC, animated: true)
    }
}

@available(iOS 15.0, *)
extension CoverPrankVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCoverAllCollectionView {
            
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            if selectedChipTitle == "Add cover image 📸" {
                if shouldShowGIF {
                    return 1
                }
                return (customCovers.isEmpty ? 1 : customCovers.count)
            } else {
                
                return isLoading ? 4 : currentDataSource.count
            }
        } else if collectionView == emojiCoverSlideCollectionview {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            if selectedChipTitle == "Add cover image 📸" {
                return (customCovers.isEmpty ? 4 : customCovers.count)
            } else {
                return isLoading ? 4 : currentDataSource.count
            }
        } else {
            return suggestions.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == emojiCoverAllCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverAllCollectionViewCell", for: indexPath) as! EmojiCoverAllCollectionViewCell
                cell.imageName.text = customCovers.isEmpty ? " Tutorial " : " Custom image "
                
                if shouldShowGIF {
                    cell.imageName.text = " Tutorial "
                    cell.imageView.loadGif(name: "cover")
                    cell.imageView.contentMode = .scaleAspectFill
                    cell.applyBackgroundBlurEffect()
                    cell.DoneButton.isHidden = true
                    cell.adContainerView.isHidden = true
                    cell.premiumButton.isHidden = true
                    cell.premiumActionButton.isHidden = true
                    return cell
                }
                
                if customCovers.isEmpty {
                    cell.imageView.loadGif(name: "cover")
                    cell.imageView.contentMode = .scaleAspectFill
                    cell.applyBackgroundBlurEffect()
                    cell.DoneButton.isHidden = true
                } else {
                    let customCover = customCovers[indexPath.item]
                    cell.imageView.image = customCover.image
                    cell.originalImage = customCover.image
                    cell.imageView.contentMode = .scaleAspectFit
                    cell.applyBackgroundBlurEffect()
                    cell.DoneButton.isHidden = false
                    
                    // Configure Done button action
                    cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                    cell.DoneButton.tag = indexPath.item
                }
                cell.adContainerView.isHidden = true
                cell.premiumButton.isHidden = true
                cell.premiumActionButton.isHidden = true
                return cell
            } else {
                if isLoading {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                    cell.isUserInteractionEnabled = false
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverAllCollectionViewCell", for: indexPath) as! EmojiCoverAllCollectionViewCell
                    
                    guard indexPath.row < currentDataSource.count else {
                        return cell
                    }
                    
                    let coverPageData = currentDataSource[indexPath.row]
                    cell.configure(with: coverPageData)
                    cell.imageView.contentMode = .scaleAspectFit
                    
                    // Configure Premium button action
                    cell.premiumActionButton.tag = indexPath.row
                    cell.premiumActionButton.addTarget(self, action: #selector(handlePremiumButtonTap(_:)), for: .touchUpInside)
                    
                    // Configure Done button action
                    cell.DoneButton.tag = indexPath.row
                    cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                    
                    return cell
                }
            }
        } else if collectionView == emojiCoverSlideCollectionview {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverSliderCollectionViewCell", for: indexPath) as! EmojiCoverSliderCollectionViewCell
                cell.imageView.image = customCovers.isEmpty ? UIImage(named: "imageplacholder") : customCovers[indexPath.item].image
                cell.premiumIconImageView.isHidden = true
                
                if shouldShowGIF || customCovers.isEmpty {
                    cell.isSelected = false
                    cell.layer.borderWidth = 0
                    cell.layer.borderColor = UIColor.clear.cgColor
                }
                
                return cell
            } else {
                if isLoading {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                    cell.isUserInteractionEnabled = false
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverSliderCollectionViewCell", for: indexPath) as! EmojiCoverSliderCollectionViewCell
                    
                    guard indexPath.row < currentDataSource.count else {
                        return cell
                    }
                    let coverPageData = currentDataSource[indexPath.row]
                    cell.configure(with: coverPageData)
                    
                    return cell
                }
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath)
            
            // Remove existing subviews
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            // Create label
            let label = UILabel()
            label.text = suggestions[indexPath.row]
            label.textColor = .white
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16)
            
            // Add label to cell
            cell.contentView.addSubview(label)
            
            // Setup constraints with minimal padding
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 4),
                label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            
            // Style cell
            cell.backgroundColor = #colorLiteral(red: 0.1215686275, green: 0.1215686275, blue: 0.1215686275, alpha: 1)
            cell.layer.borderWidth = 1
            cell.layer.borderColor = #colorLiteral(red: 0.3098039216, green: 0.3176470588, blue: 0.3254901961, alpha: 1)
            cell.layer.cornerRadius = 10
            
            return cell
        }
    }
    
    @objc private func handlePremiumButtonTap(_ sender: UIButton) {
        let coverPageData = currentDataSource[sender.tag]
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumPopupVC") as! PremiumPopupVC
        premiumVC.setItemIDToUnlock(coverPageData.itemID)
        premiumVC.modalTransitionStyle = .crossDissolve
        premiumVC.modalPresentationStyle = .overCurrentContext
        present(premiumVC, animated: true, completion: nil)
    }
    
    @objc private func handleDoneButtonTap(_ sender: UIButton) {
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LanguageVC") as? LanguageVC {
                if selectedChipTitle == "Add cover image 📸" {
                    let customCover = customCovers[sender.tag]
                    vc.coverImageUrl = customCover.imageUrl
                    vc.coverimageName = "Custom Cover image"
                    vc.buttonType = buttonType
                } else {
                    let coverPageData = currentDataSource[sender.tag]
                    vc.coverImageUrl = coverPageData.coverURL
                    vc.coverimageName = coverPageData.coverName
                    vc.buttonType = buttonType
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                let selectedChipTitle = self?.chipSelector.getSelectedChipTitle()
                if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "LanguageVC") as? LanguageVC {
                    if selectedChipTitle == "Add cover image 📸" {
                        let customCover = self?.customCovers[sender.tag]
                        vc.coverImageUrl = customCover?.imageUrl
                        vc.coverimageName = "Custom Cover image"
                        vc.buttonType = self?.buttonType
                    } else {
                        let coverPageData = self?.currentDataSource[sender.tag]
                        vc.coverImageUrl = coverPageData?.coverURL
                        vc.coverimageName = coverPageData?.coverName
                        vc.buttonType = self?.buttonType
                    }
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCoverSlideCollectionview {
            
            shouldShowGIF = false
            
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                if customCovers.isEmpty {
                    return
                }
            }
            
            emojiCoverAllCollectionView.reloadData()
            
            emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        } else if collectionView == emojiCoverAllCollectionView {
            
        } else {
            let selectedSuggestion = suggestions[indexPath.row]
            searchBar.text = selectedSuggestion
            filterContent(with: selectedSuggestion)
            
            searchBar.resignFirstResponder()
            searchMainViewHeightConstarints.constant = 0
            searchMainView.isHidden = true
            popularLabel.isHidden = true
            suggestionCollectionView.isHidden = true
            cancelButton.isHidden = false
            
            // Reset corner radius when a suggestion is selected
            searchMainView.layer.cornerRadius = 10
            searchBarView.layer.cornerRadius = 10
            searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 90
        let height: CGFloat = 90
        
        if collectionView == emojiCoverAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == emojiCoverSlideCollectionview {
            return CGSize(width: width, height: height)
        } else {
            // For suggestion collection view
            let suggestion = suggestions[indexPath.row]
            
            // Create a temporary label to measure exact text size
            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16)
            label.text = suggestion
            
            // Get exact size needed for text
            let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
            
            // Add minimal padding (8 points total - 4 on each side)
            let cellWidth = labelSize.width + 20
            
            return CGSize(width: cellWidth, height: 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = viewModel.emojiCoverPages.count - 1
        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
            fetchAllCoverPages()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                for: indexPath
            ) as! LoadingFooterView
            if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.emojiCoverPages.isEmpty {
                footer.startAnimating()
            } else {
                footer.stopAnimating()
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Skip animation if scrolling from slider selection
        guard scrollView == emojiCoverAllCollectionView else { return }
        
        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
        let pageWidth = scrollView.frame.width
        
        // Apply diagonal swipe animation only for user-initiated scrolling
        for cell in emojiCoverAllCollectionView.visibleCells {
            let cellCenterX = cell.center.x
            let distanceFromCenter = centerX - cellCenterX
            
            // Calculate how far we've moved from center as a percentage
            let swipeProgress = distanceFromCenter / pageWidth
            
            // Calculate translation and rotation
            let translationX = -distanceFromCenter
            let translationY = abs(distanceFromCenter) * 0.3
            let rotation = swipeProgress * (CGFloat.pi / 8)
            
            // Combine transforms
            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: translationX, y: translationY)
            transform = transform.rotated(by: rotation)
            
            // Apply transform
            cell.transform = transform
        }
        
        // Update slider collection view position
        let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
        
        let selectedChipTitle = chipSelector.getSelectedChipTitle()
        
        if selectedChipTitle == "Add cover image 📸" {
            guard currentPage >= 0 && currentPage < customCovers.count else { return }
        } else {
            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
        }
        
        if currentPage != selectedIndex {
            selectedIndex = currentPage
            
            let indexPath = IndexPath(item: currentPage, section: 0)
            DispatchQueue.main.async {
                self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    // Reset animation when scrolling ends
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == emojiCoverAllCollectionView else { return }
        
        UIView.animate(withDuration: 0.3) {
            for cell in self.emojiCoverAllCollectionView.visibleCells {
                cell.transform = .identity
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == emojiCoverAllCollectionView else { return }
        
        if !decelerate {
            UIView.animate(withDuration: 0.3) {
                for cell in self.emojiCoverAllCollectionView.visibleCells {
                    cell.transform = .identity
                }
            }
        }
    }
    
    // For smooth page snapping
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == emojiCoverAllCollectionView else { return }
        
        let pageWidth = scrollView.frame.width
        let targetXContentOffset = targetContentOffset.pointee.x
        let newTargetOffset = round(targetXContentOffset / pageWidth) * pageWidth
        
        targetContentOffset.pointee = CGPoint(x: newTargetOffset, y: targetContentOffset.pointee.y)
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
@available(iOS 15.0, *)
extension CoverPrankVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Camera Button
    func btnCameraTapped() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showImagePicker(for: .camera)
                    } else {
                        self.showPermissionSnackbar(for: "camera")
                    }
                }
            }
        case .authorized:
            showImagePicker(for: .camera)
        case .restricted, .denied:
            showPermissionSnackbar(for: "camera")
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }
    
    // MARK: - Gallery Button
    func btnGalleryTapped() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.showImagePicker(for: .photoLibrary)
                    } else {
                        self.showPermissionSnackbar(for: "photo library")
                    }
                }
            }
        case .authorized, .limited:
            showImagePicker(for: .photoLibrary)
        case .restricted, .denied:
            showPermissionSnackbar(for: "photo library")
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }
    
    // MARK: - showImagePicker
    func showImagePicker(for sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            imagePicker.allowsEditing = true
            if sourceType == .camera {
                imagePicker.cameraDevice = .rear
            }
            DispatchQueue.main.async {
                self.present(imagePicker, animated: true, completion: nil)
            }
        } else {
            print("\(sourceType) is not available")
        }
    }
    
    // MARK: - Show permission snackbar
    func showPermissionSnackbar(for feature: String) {
        let messageKey: String
        
        switch feature {
        case "camera":
            messageKey = "We need access to your camera to set the cover image."
        case "photo library":
            messageKey = "We need access to your photo library to set the cover image."
        default:
            messageKey = "We need access to your camera to set the cover image."
        }
        
        let localizedMessage = NSLocalizedString(messageKey, comment: "")
        let settingsText = NSLocalizedString("Settings", comment: "")
        
        let snackbar = Snackbar(message: localizedMessage, backgroundColor: .snackbar)
        snackbar.setAction(title: settingsText) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        snackbar.show(in: self.view, duration: 5.0)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // First save the image to documents directory and get URL
            if let imageUrl = saveImageToDocuments(image: selectedImage) {
                ImageProcessingManager.shared.processImage(selectedImage) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let compressedImage):
                        // Create CustomCover with both compressed image and URL
                        let customCover = CustomCover(image: compressedImage, imageUrl: imageUrl)
                        self.customCovers.insert(customCover, at: 0)
                        self.selectedCoverIndex = 0
                        self.saveCovers()
                        
                        DispatchQueue.main.async {
                            self.emojiCoverSlideCollectionview.reloadData()
                            self.emojiCoverAllCollectionView.reloadData()
                            let indexPath = IndexPath(item: 0, section: 0)
                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                            self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.selectedCustomCoverIndex = indexPath
                            self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                            self.emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        }
                        
                    case .failure(let error):
                        let snackbar = Snackbar(message: error.message, backgroundColor: .snackbar)
                        snackbar.show(in: self.view, duration: 3.0)
                    }
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    // Helper function to save image and get URL
    private func saveImageToDocuments(image: UIImage) -> String? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidv4 + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        do {
            // Write the image data to the file URL
            try imageData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func saveCovers() {
        let coversData = customCovers.map { cover in
            [
                "image": cover.image,
                "url": cover.imageUrl ?? ""
            ]
        }
        
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: coversData, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: ConstantValue.is_UserCoverImages)
        }
    }
    
    func loadSavedCovers() {
        if let savedData = UserDefaults.standard.object(forKey: ConstantValue.is_UserCoverImages) as? Data {
            do {
                if let decodedData = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedData) as? [[String: Any]] {
                    customCovers = decodedData.compactMap { dict in
                        if let image = dict["image"] as? UIImage {
                            let url = dict["url"] as? String
                            return CustomCover(image: image, imageUrl: url)
                        }
                        return nil
                    }
                    emojiCoverSlideCollectionview.reloadData()
                    emojiCoverAllCollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved covers: \(error)")
            }
        }
    }
}

@available(iOS 15.0, *)
extension CoverPrankVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Show the hidden UI elements immediately when textfield is tapped
        if isConnectedToInternet() {
            searchMainView.isHidden = false
            popularLabel.isHidden = false
            suggestionCollectionView.isHidden = false
            
            searchMainViewHeightConstarints.constant = 90
            
            // Set corner radius for searchBarView (top corners)
            searchBarView.layer.cornerRadius = 10
            searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            
            // Set corner radius for searchMainView (bottom corners)
            searchMainView.layer.cornerRadius = 10
            searchMainView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            
            // Animate the changes
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @IBAction func searchTextFieldDidChange(_ sender: UITextField) {
        filterContent(with: sender.text ?? "")
        cancelButton.isHidden = false
    }
    
    @IBAction func cancelButtonTapped(_ sender: UIButton) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        filterContent(with: "")
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        
        // Restore corner radius when cancel is tapped
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        // cancelButton.isHidden = true
        
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, !text.isEmpty {
            cancelButton.isHidden = false
        } else {
            cancelButton.isHidden = true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, text.isEmpty {
            cancelButton.isHidden = true
        }
    }
}


// Extension to generate UUID string
extension UUID {
    var uuidv4: String {
        return self.uuidString.lowercased()
    }
}
