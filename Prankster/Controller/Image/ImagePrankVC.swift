//
//  ImagePrankVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 31/01/25.
//

import UIKit
import Alamofire
import AVFoundation
import Photos
import GoogleMobileAds

struct CustomImages {
    let image: UIImage
    let imageUrl: String?
    let isLocalFile: Bool
    
    init(image: UIImage, imageUrl: String?, isLocalFile: Bool = false) {
        self.image = image
        self.imageUrl = imageUrl
        self.isLocalFile = isLocalFile
    }
}

@available(iOS 15.0, *)
class ImagePrankVC: UIViewController {
    
    @IBOutlet weak var chipSelector: ImageChipSelector!
    @IBOutlet weak var imageAllCollectionview: UICollectionView!
    @IBOutlet weak var imageSlideCollectionview: UICollectionView!
    @IBOutlet weak var addimageButton: UIButton!
    @IBOutlet weak var addimageView: UIView!
    @IBOutlet weak var ImageLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var suggestionCollectionView: UICollectionView!
    
    @IBOutlet weak var searchBarView: UIView!
    
    private var shouldShowGIF = true
    
    private var currentCategoryId: Int = 0
    private var isFirstLoad: Bool = true
    
    var languageid: Int = 0
    
    private var suggestions: [String] = []
    
    var selectedCoverImageURL: String?
    var selectedCoverImageFile: Data?
    var selectedCoverImageName: String?
    
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
    private var selectedImageIndex: Int?
    var customImages: [CustomImages] = []
    var selectedCustomImageIndex: IndexPath?
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private let viewModel = CategoryAllViewModel()
    private var isSearchActive = false
    private var filteredImages: [CategoryAllData] = []
    private var currentDataSource: [CategoryAllData] {
        return isSearchActive ? filteredImages : viewModel.audioData
    }
    
    var isLoading = true
    private let categoryId: Int = 4
    private var isLoadingMore = false
    private var selectedIndex: Int = 0
    private var nativeMediumAdUtility: NativeMediumAdUtility?
    var preloadedNativeAdView: GADNativeAdView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSavedImages()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        setupChipSelector()
        self.filteredImages = viewModel.audioData
        PremiumManager.shared.clearTemporaryUnlocks()
        
        NotificationCenter.default.addObserver( self, selector: #selector(handlePremiumContentUnlocked), name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
        
        self.addimageView.layer.cornerRadius = 10
        
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        searchMainView.isHidden = true
        searchMainViewHeightConstarints.constant = 0
        searchBarView.isHidden = true
        self.ImageLabel.isHidden = false
        
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        
        view.bringSubviewToFront(searchMainView)
        view.bringSubviewToFront(searchBarView)
        
        if let searchMainViewIndex = view.subviews.firstIndex(of: searchMainView) {
            for subview in view.subviews {
                if subview is NoDataView || subview is NoInternetView {
                    view.insertSubview(subview, at: searchMainViewIndex - 1)
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
        searchBar.placeholder = "Search image or artist name"
        
        if let searchBar = searchBar {
            let placeholderText = "Search image or artist name"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
        
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
            
            self.imageAllCollectionview.reloadData()
            self.imageSlideCollectionview.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.imageSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            
            self.selectedIndex = currentIndex
        }
    }
    
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllImages()
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
        tagViewModule.fetchTag(id: "3") { [weak self] result in
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
        self.imageAllCollectionview.delegate = self
        self.imageAllCollectionview.dataSource = self
        self.imageSlideCollectionview.delegate = self
        self.imageSlideCollectionview.dataSource = self
        self.imageAllCollectionview.isPagingEnabled = true
        self.imageAllCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.imageSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.imageSlideCollectionview.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        if let layout = imageSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = CGSize(width: 50, height: imageSlideCollectionview.frame.height)
        }
    }
    
    private func setupChipSelector() {
        chipSelector.onCategorySelected = { [weak self] categoryId in
            guard let self = self else { return }
            
            // Update current category ID
            self.currentCategoryId = categoryId
            
            // Reset selected index to 0 whenever changing categories
            self.selectedIndex = 0
            
            if categoryId == 0 {
                self.hideSkeletonLoader()
                
                // Add cover image વાળી chip માટેનો existing code
                self.popularLabel.isHidden = true
                self.suggestionCollectionView.isHidden = true
                self.cancelButton.isHidden = true
                self.searchMainView.isHidden = true
                self.searchMainViewHeightConstarints.constant = 0
                self.addimageView.isHidden = false
                self.noInternetView.isHidden = true
                self.noDataView.isHidden = true
                self.searchBarView.isHidden = true
                self.ImageLabel.isHidden = false
                
                self.imageAllCollectionview.reloadData()
                self.imageSlideCollectionview.reloadData()
                
                // Select first item after reload
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    if !self.customImages.isEmpty && !self.shouldShowGIF {
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        self.imageSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                        self.imageSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                    }
                }
                
            } else {
                // Reset states for API call
                self.isLoadingMore = false
                self.isFirstLoad = false
                self.viewModel.resetPagination()
                
                self.addimageView.isHidden = true
                self.searchBarView.isHidden = false
                self.ImageLabel.isHidden = true
                
                // Clear existing data
                self.viewModel.audioData.removeAll()
                self.filteredImages.removeAll()
                
                // Reset collection views and select first item
                self.imageAllCollectionview.reloadData()
                self.imageSlideCollectionview.reloadData()
                
                // Show loader
                self.showSkeletonLoader()
                
                // Hide no data view before fetching
                self.hideNoDataView()
                
                // Fetch new data
                self.checkInternetAndFetchData()
                
                // After fetching data and reloading, select the first item
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if !self.currentDataSource.isEmpty {
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                        self.imageSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                        self.imageSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                    }
                }
            }
        }
        
        // Trigger default chip selection
        chipSelector.selectDefaultChip()
    }
    
    // MARK: - fetchAllAudios
    func fetchAllImages() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        viewModel.fetchAudioData(prankid: 3, categoryId: currentCategoryId, languageid: languageid) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                
                if success {
                    if self.viewModel.audioData.isEmpty {
                        self.hideSkeletonLoader()
                        self.showNoDataView()
                    } else {
                        self.hideSkeletonLoader()
                        self.hideNoDataView()
                        self.filteredImages = self.viewModel.audioData
                        self.imageAllCollectionview.reloadData()
                        self.imageSlideCollectionview.reloadData()
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.imageSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        }
                    }
                }   else if let errorMessage = self.viewModel.errorMessage {
                    self.hideSkeletonLoader()
                    self.showNoDataView()
                    print("Error fetching all cover pages: \(errorMessage)")
                }
            }
        }
    }
    
    func showSkeletonLoader() {
        isLoading = true
        imageAllCollectionview.reloadData()
        imageSlideCollectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        imageAllCollectionview.reloadData()
        imageSlideCollectionview.reloadData()
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
            noDataView.isHidden = true
            checkInternetAndFetchData()
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    func showNoDataView() {
        noDataView.isHidden = false
    }
    
    func hideNoDataView() {
        noDataView.isHidden = true
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    @IBAction func btnAddImageTapped(_ sender: UIButton) {
        self.shouldShowGIF = false
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            self.shouldShowGIF = false
            self.addImageClick()
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shouldShowGIF = false
                self?.addImageClick()
            }
        }
    }
    
    private func addImageClick() {
        let imagePopupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImagePopupVC") as! ImagePopupVC
        imagePopupVC.modalPresentationStyle = .overCurrentContext
        imagePopupVC.modalTransitionStyle = .crossDissolve
        
        imagePopupVC.cameraCallback = { [weak self] in
            self?.btnCameraTapped()
        }
        
        imagePopupVC.downloaderCallback = { [weak self] in
            guard let self = self else { return }
            let downloaderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageDownloaderBottom") as! ImageDownloaderBottom
            downloaderVC.modalPresentationStyle = .pageSheet
            
            if let sheet = downloaderVC.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            downloaderVC.imageDownloadedCallback = { [weak self] (downloadedImage, imageUrl) in
                guard let self = self else { return }
                
                if let image = downloadedImage {
                    let customCover = CustomImages(image: image, imageUrl: imageUrl)
                    self.customImages.insert(customCover, at: 0)
                    self.selectedImageIndex = 0
                    self.saveImages()
                    
                    DispatchQueue.main.async {
                        self.imageSlideCollectionview.reloadData()
                        self.imageAllCollectionview.reloadData()
                        
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.imageSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.selectedCustomImageIndex = indexPath
                        self.imageSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        self.imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
            self.present(downloaderVC, animated: true)
        }
        imagePopupVC.galleryCallback = { [weak self] in
            self?.btnGalleryTapped()
        }
        self.present(imagePopupVC, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
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
            filteredImages = viewModel.audioData
        } else {
            filteredImages = viewModel.audioData.filter { coverPage in
                let nameMatch = coverPage.name.lowercased().contains(searchText.lowercased())
                let tagMatch = coverPage.artistName.contains { tag in
                    tag.lowercased().contains(searchText.lowercased())
                }
                return nameMatch || tagMatch
            }
        }
        
        DispatchQueue.main.async {
            self.selectedIndex = 0
            
            self.imageAllCollectionview.reloadData()
            self.imageSlideCollectionview.reloadData()
            
            // Make sure searchMainView stays on top when showing no data
            if self.filteredImages.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
                self.view.bringSubviewToFront(self.searchBarView)
                self.view.bringSubviewToFront(self.searchMainView)
            } else {
                self.hideNoDataView()
                
                if !self.filteredImages.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    if self.imageAllCollectionview.numberOfItems(inSection: 0) > 0 {
                        self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if self.imageSlideCollectionview.numberOfItems(inSection: 0) > 0 {
                        self.imageSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.imageSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }
}


// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
@available(iOS 15.0, *)
extension ImagePrankVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == suggestionCollectionView {
            return suggestions.count
        } else if collectionView == imageAllCollectionview {
            if currentCategoryId == 0 {
                if shouldShowGIF {
                    return 1
                }
                return (customImages.isEmpty ? 1 : customImages.count)
            } else {
                if isLoading {
                    return 4
                }
                return currentDataSource.count
            }
        } else {
            if currentCategoryId == 0 {
                return (customImages.isEmpty ? 4 : customImages.count)
            } else {
                if isLoading {
                    return 4
                }
                return currentDataSource.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageAllCollectionview {
            if currentCategoryId == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterAllCollectionViewCell", for: indexPath) as! ImageCharacterAllCollectionViewCell
                cell.imageName.text = customImages.isEmpty ? " Tutorial " : " Custom image "
                
                if shouldShowGIF {
                    cell.imageName.text = " Tutorial "
                    cell.tutorialViewShowView.isHidden = false
                    cell.imageView.isHidden = true
                    cell.DoneButton.isHidden = true
                    cell.adContainerView.isHidden = true
                    cell.premiumButton.isHidden = true
                    cell.premiumActionButton.isHidden = true
                    DispatchQueue.main.async {
                        cell.setupTutorialVideo()
                    }
                    return cell
                }
                
                if customImages.isEmpty {
                    cell.tutorialViewShowView.isHidden = false
                    cell.imageView.isHidden = true
                    cell.DoneButton.isHidden = true
                    cell.premiumButton.isHidden = true
                    cell.premiumActionButton.isHidden = true
                    DispatchQueue.main.async {
                        cell.setupTutorialVideo()
                    }
                } else {
                    cell.tutorialViewShowView.isHidden = true
                    cell.imageView.isHidden = false
                    let customCover = customImages[indexPath.item]
                    cell.imageView.image = customCover.image
                    cell.originalImage = customCover.image
                    cell.imageView.contentMode = .scaleAspectFit
                    cell.applyBackgroundBlurEffect()
                    cell.DoneButton.isHidden = false
                    
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
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterAllCollectionViewCell", for: indexPath) as! ImageCharacterAllCollectionViewCell
                    
                    guard indexPath.row < currentDataSource.count else {
                        return cell
                    }
                    
                    let categoryAllData = currentDataSource[indexPath.row]
                    cell.configure(with: categoryAllData)
                    cell.imageView.contentMode = .scaleAspectFit
                    cell.tutorialViewShowView.isHidden = true
                    cell.imageView.isHidden = false
                    
                    // Configure Premium button action
                    cell.premiumActionButton.tag = indexPath.row
                    cell.premiumActionButton.addTarget(self, action: #selector(handlePremiumButtonTap(_:)), for: .touchUpInside)
                    
                    // Configure Done button action
                    cell.DoneButton.tag = indexPath.row
                    cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                    
                    return cell
                }
            }
        } else if collectionView == imageSlideCollectionview {
            
            if currentCategoryId == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterSliderCollectionViewCell", for: indexPath) as! ImageCharacterSliderCollectionViewCell
                cell.imageView.image = customImages.isEmpty ? UIImage(named: "imageplacholder") : customImages[indexPath.item].image
                cell.premiumIconImageView.isHidden = true
                if customImages.isEmpty {
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
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterSliderCollectionViewCell", for: indexPath) as! ImageCharacterSliderCollectionViewCell
                    
                    guard indexPath.row < currentDataSource.count else {
                        return cell
                    }
                    let categoryAllData = currentDataSource[indexPath.row]
                    cell.configure(with: categoryAllData)
                    
                    return cell
                }
            }
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath)
            
            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
            
            let label = UILabel()
            label.text = suggestions[indexPath.row]
            label.textColor = .white
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16)
            
            cell.contentView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 4),
                label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -4),
                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
            ])
            
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
            self.doneButtonClick(sender)
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = {
                self.doneButtonClick(sender)
            }
        }
    }
    
    private func doneButtonClick(_ sender: UIButton) {
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ShareLinkVC") as? ShareLinkVC {
            if currentCategoryId == 0 {
                let customImages = customImages[sender.tag]
                if let imageURLString = customImages.imageUrl,
                   let imageURL = URL(string: imageURLString),
                   imageURL.scheme?.lowercased() == "http" || imageURL.scheme?.lowercased() == "https" {
                    vc.selectedURL = imageURLString
                    
                } else if let localPath = customImages.imageUrl {
                    let fileURL = URL(fileURLWithPath: localPath)
                    if let fileData = try? Data(contentsOf: fileURL) {
                        vc.selectedFile = fileData
                    } else {
                        print("Error loading image data from local path")
                    }
                }
                
                vc.selectedName = selectedCoverImageName
                vc.selectedCoverURL = selectedCoverImageURL
                vc.selectedCoverFile = selectedCoverImageFile
                vc.selectedPranktype = "gallery"
                vc.selectedFileType = "jpg"
                vc.sharePrank = true
            } else {
                let categoryAllData = currentDataSource[sender.tag]
                vc.selectedURL = categoryAllData.file
                vc.selectedName = selectedCoverImageName
                vc.selectedCoverURL = selectedCoverImageURL
                vc.selectedCoverFile = selectedCoverImageFile
                vc.selectedPranktype = "gallery"
                vc.selectedFileType = "jpg"
                vc.sharePrank = true
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == imageAllCollectionview {
            
        } else if collectionView == imageSlideCollectionview {
            
            shouldShowGIF = false
            
            if currentCategoryId == 0 {
                if customImages.isEmpty {
                    collectionView.deselectItem(at: indexPath, animated: false)
                    return
                }
            }
            
            imageAllCollectionview.reloadData()
            
            imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
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
        
        if collectionView == imageAllCollectionview {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == imageSlideCollectionview {
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                for: indexPath
            ) as! LoadingFooterView
            
            if currentCategoryId == 0 {
                footer.stopAnimating()
            } else {
                // બાકીની ચિપ્સ માટે જૂની લોજિક જાળવી રાખો
                if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.audioData.isEmpty {
                    footer.startAnimating()
                } else {
                    footer.stopAnimating()
                }
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = viewModel.audioData.count - 1
        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
            //  DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
            self.fetchAllImages()
            //  }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Skip animation if scrolling from slider selection
        guard scrollView == imageAllCollectionview else { return }
        
        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
        let pageWidth = scrollView.frame.width
        
        // Apply diagonal swipe animation only for user-initiated scrolling
        for cell in imageAllCollectionview.visibleCells {
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
        
        if currentCategoryId == 0 {
            
            guard currentPage >= 0 && currentPage < customImages.count else { return }
        } else {
            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
        }
        
        if currentPage != selectedIndex {
            selectedIndex = currentPage
            
            let indexPath = IndexPath(item: currentPage, section: 0)
            DispatchQueue.main.async {
                self.imageSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    // Reset animation when scrolling ends
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == imageAllCollectionview else { return }
        
        UIView.animate(withDuration: 0.3) {
            for cell in self.imageAllCollectionview.visibleCells {
                cell.transform = .identity
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == imageAllCollectionview else { return }
        
        if !decelerate {
            UIView.animate(withDuration: 0.3) {
                for cell in self.imageAllCollectionview.visibleCells {
                    cell.transform = .identity
                }
            }
        }
    }
    
    // For smooth page snapping
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == imageAllCollectionview else { return }
        
        let pageWidth = scrollView.frame.width
        let targetXContentOffset = targetContentOffset.pointee.x
        let newTargetOffset = round(targetXContentOffset / pageWidth) * pageWidth
        
        targetContentOffset.pointee = CGPoint(x: newTargetOffset, y: targetContentOffset.pointee.y)
    }
}


// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
@available(iOS 15.0, *)
extension ImagePrankVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
            messageKey = "We need access to your camera to set the prank image."
        case "photo library":
            messageKey = "We need access to your photo library to set the prank image."
        default:
            messageKey = "We need access to your camera to set the prank image."
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
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            if let imageUrl = saveImageToDocuments(image: selectedImage) {
                ImageProcessingManager.shared.processImage(selectedImage) { [weak self] result in
                    guard let self = self else { return }
                    
                    switch result {
                    case .success(let compressedImage):
                        let customImages = CustomImages(image: compressedImage, imageUrl: imageUrl, isLocalFile: true)
                        self.customImages.insert(customImages, at: 0)
                        self.selectedImageIndex = 0
                        self.saveImages()
                        
                        DispatchQueue.main.async {
                            self.imageSlideCollectionview.reloadData()
                            self.imageAllCollectionview.reloadData()
                            let indexPath = IndexPath(item: 0, section: 0)
                            self.imageSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                            self.imageAllCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.selectedCustomImageIndex = indexPath
                            self.imageSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                            self.imageAllCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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
    
    private func saveImageToDocuments(image: UIImage) -> String? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = UUID().uuidv4 + ".jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        guard let imageData = image.jpegData(compressionQuality: 1.0) else { return nil }
        
        do {
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
    
    func saveImages() {
        let coversData: [[String: Any]] = customImages.compactMap { cover -> [String: Any]? in
            return [
                "url": cover.imageUrl ?? "",
                "isLocalFile": cover.isLocalFile
            ]
        }
        
        // JSON એન્કોડિંગનો ઉપયોગ કરો
        if let jsonData = try? JSONSerialization.data(withJSONObject: coversData) {
            UserDefaults.standard.set(jsonData, forKey: ConstantValue.is_UserImages)
        }
    }
    
    func loadSavedImages() {
        if let savedData = UserDefaults.standard.data(forKey: ConstantValue.is_UserImages) {
            do {
                if let decodedData = try JSONSerialization.jsonObject(with: savedData) as? [[String: Any]] {
                    let dispatchGroup = DispatchGroup()
                    var tempCustomCovers: [(index: Int, cover: CustomImages)] = []
                    
                    for (index, dict) in decodedData.enumerated() {
                        guard let url = dict["url"] as? String else { continue }
                        let isLocalFile = dict["isLocalFile"] as? Bool ?? false
                        
                        dispatchGroup.enter()
                        
                        if isLocalFile {
                            // Local file handling
                            let fileURL = URL(fileURLWithPath: url)
                            DispatchQueue.global(qos: .background).async {
                                if let imageData = try? Data(contentsOf: fileURL),
                                   let image = UIImage(data: imageData) {
                                    let customImage = CustomImages(image: image, imageUrl: url, isLocalFile: true)
                                    tempCustomCovers.append((index: index, cover: customImage))
                                }
                                dispatchGroup.leave()
                            }
                        } else {
                            // Remote image handling
                            if let imageURL = URL(string: url) {
                                URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
                                    if let data = data, let image = UIImage(data: data) {
                                        let customImage = CustomImages(image: image, imageUrl: url, isLocalFile: false)
                                        tempCustomCovers.append((index: index, cover: customImage))
                                    }
                                    dispatchGroup.leave()
                                }.resume()
                            } else {
                                dispatchGroup.leave()
                            }
                        }
                    }
                    
                    dispatchGroup.notify(queue: .main) { [weak self] in
                        // Sort by original index to maintain the order from UserDefaults
                        let sortedCovers = tempCustomCovers.sorted(by: { $0.index < $1.index })
                        self?.customImages = sortedCovers.map { $0.cover }
                        self?.imageAllCollectionview.reloadData()
                        self?.imageSlideCollectionview.reloadData()
                    }
                }
            } catch {
                print("Error decoding saved covers: \(error)")
            }
        }
    }
}

@available(iOS 15.0, *)
extension ImagePrankVC: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if isConnectedToInternet() {
            searchMainView.isHidden = false
            popularLabel.isHidden = false
            suggestionCollectionView.isHidden = false
            searchMainViewHeightConstarints.constant = 90
            searchBarView.layer.cornerRadius = 10
            searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
            searchMainView.layer.cornerRadius = 10
            searchMainView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
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
