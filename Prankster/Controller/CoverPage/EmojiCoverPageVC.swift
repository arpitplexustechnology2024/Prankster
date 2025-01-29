//
//  EmojiCoverPageVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import Alamofire
import AVFoundation
import Photos

@available(iOS 15.0, *)
class EmojiCoverPageVC: UIViewController {
    
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
    
    private var tagViewModule : TagViewModule!
    
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
    var customCoverImages: [UIImage] = []
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadSavedImages()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        self.fetchTagData()
        self.filteredEmojiCoverPages = viewModel.emojiCoverPages
        
        NotificationCenter.default.addObserver( self, selector: #selector(handlePremiumContentUnlocked), name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if !self.customCoverImages.isEmpty {
                let indexPath = IndexPath(item: 0, section: 0)
                self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedIndex = 0
            }
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
                
                // Restore corner radius when cancel is tapped
                self?.searchMainView.layer.cornerRadius = 10
                self?.searchBarView.layer.cornerRadius = 10
                self?.searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
                
                UIView.animate(withDuration: 0.3) {
                    self?.view.layoutIfNeeded()
                }
            }
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.selectedIndex = 0
                }
                
            } else {
                self.addcoverView.isHidden = true
                
                self.searchBarView.isHidden = false
                self.coverImageLabel.isHidden = true
                
                emojiCoverAllCollectionView.reloadData()
                emojiCoverSlideCollectionview.reloadData()
                
                self.checkInternetAndFetchData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let indexPath = IndexPath(item: 0, section: 0)
                    self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                    self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.selectedIndex = 0
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
    
    private func setupCollectionView() {
        self.emojiCoverSlideCollectionview.delegate = self
        self.emojiCoverSlideCollectionview.dataSource = self
        self.emojiCoverAllCollectionView.delegate = self
        self.emojiCoverAllCollectionView.dataSource = self
        self.emojiCoverAllCollectionView.isPagingEnabled = true
        self.emojiCoverAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.emojiCoverSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.emojiCoverSlideCollectionview.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        if let layout = emojiCoverSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = CGSize(width: 16, height: emojiCoverSlideCollectionview.frame.height)
        }
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
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        }
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
            noInternetView.topAnchor.constraint(equalTo: chipSelector.bottomAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            hideNoDataView()
            checkInternetAndFetchData()
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
        let popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PopupVC") as! PopupVC
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        
        popupVC.cameraCallback = { [weak self] in
            self?.btnCameraTapped()
        }
        
        popupVC.downloaderCallback = { [weak self] in
            guard let self = self else { return }
            // Present ImageDownloaderBottom
            let downloaderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageDownloaderBottom") as! ImageDownloaderBottom
            downloaderVC.modalPresentationStyle = .pageSheet
            
            if let sheet = downloaderVC.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            downloaderVC.imageDownloadedCallback = { [weak self] (downloadedImage, imageUrl) in
                guard let self = self else { return }
                
                if let image = downloadedImage {
                    self.customCoverImages.insert(image, at: 0)
                    self.selectedCoverIndex = 0
                    self.saveImages()
                    
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
        
        present(popupVC, animated: true)
    }
}

@available(iOS 15.0, *)
extension EmojiCoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == emojiCoverAllCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            if selectedChipTitle == "Add cover image 📸" {
                return (customCoverImages.isEmpty ? 1 : customCoverImages.count)
            } else {
                
                return isLoading ? 8 : currentDataSource.count
            }
        } else if collectionView == emojiCoverSlideCollectionview {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            if selectedChipTitle == "Add cover image 📸" {
                return (customCoverImages.isEmpty ? 4 : customCoverImages.count)
            } else {
                return isLoading ? 8 : currentDataSource.count
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
                cell.imageName.text = customCoverImages.isEmpty ? "Funny name" : "Custom image \(indexPath.item + 1)"
                
                if customCoverImages.isEmpty {
                    cell.imageView.loadGif(name: "CoverGIF")
                    cell.blurImageView.loadGif(name: "CoverGIF")
                    cell.applyBackgroundBlurEffect()
                } else {
                    let image = customCoverImages[indexPath.item]
                    cell.imageView.image = image
                    cell.originalImage = image
                    cell.applyBackgroundBlurEffect()
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
                    cell.delegate = self
                    return cell
                }
            }
        } else if collectionView == emojiCoverSlideCollectionview {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverSliderCollectionViewCell", for: indexPath) as! EmojiCoverSliderCollectionViewCell
                cell.imageView.image = customCoverImages.isEmpty ? UIImage(named: "imageplacholder") : customCoverImages[indexPath.item]
                cell.premiumIconImageView.isHidden = true
                
                if customCoverImages.isEmpty {
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == emojiCoverSlideCollectionview {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                if customCoverImages.isEmpty {
                    
                    return
                }
                emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            } else {
                emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
            
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
        if scrollView == emojiCoverAllCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                let pageWidth = scrollView.bounds.width
                let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
                
                guard currentPage >= 0 && currentPage < customCoverImages.count else { return }
                
                if currentPage != selectedIndex {
                    selectedIndex = currentPage
                    
                    let indexPath = IndexPath(item: currentPage, section: 0)
                    DispatchQueue.main.async {
                        if currentPage < self.customCoverImages.count {
                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                            self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        }
                    }
                }
                
            } else {
                
                let pageWidth = scrollView.bounds.width
                let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
                
                guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
                
                if currentPage != selectedIndex {
                    selectedIndex = currentPage
                    
                    let indexPath = IndexPath(item: currentPage, section: 0)
                    DispatchQueue.main.async {
                        if currentPage < self.currentDataSource.count {
                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                            self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
@available(iOS 15.0, *)
extension EmojiCoverPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
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
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            print("Custom Cover Image URL: \(fileURL.absoluteString)")
            
            customCoverImages.insert(selectedImage, at: 0)
            selectedCoverIndex = 0
            saveImages()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
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
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadSavedImages() {
        if let savedImagesData = UserDefaults.standard.object(forKey: ConstantValue.is_UserCoverImages) as? Data {
            do {
                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [UIImage] {
                    customCoverImages = decodedImages
                    emojiCoverSlideCollectionview.reloadData()
                    emojiCoverAllCollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved images: \(error)")
            }
        }
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customCoverImages, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: ConstantValue.is_UserCoverImages)
        }
    }
}

@available(iOS 15.0, *)
extension EmojiCoverPageVC: UITextFieldDelegate {
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
        // Show the cancel button if there is text
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

@available(iOS 15.0, *)
extension EmojiCoverPageVC: emojiCoverAllCollectionViewCellDelegate {
    func didTapPremiumIcon(for coverpageData: CoverPageData) {
        presentPremiumViewController(for: coverpageData)
    }
    
    private func presentPremiumViewController(for coverPageData: CoverPageData) {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumPopupVC") as! PremiumPopupVC
        premiumVC.setItemIDToUnlock(coverPageData.itemID)
        premiumVC.modalTransitionStyle = .crossDissolve
        premiumVC.modalPresentationStyle = .overCurrentContext
        present(premiumVC, animated: true, completion: nil)
    }
    
    func didTapDoneButton(for coverPageData: CoverPageData) {
        print("Done Button Tapped")
    }
}
