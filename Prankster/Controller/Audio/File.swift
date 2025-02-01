//
//  File.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 31/01/25.
//

//import UIKit
//import Alamofire
//import AVFoundation
//import SDWebImage
//import GoogleMobileAds
//import MobileCoreServices
//
//struct CustomAudio: Codable {
//    let fileName: String
//    let imageURL: String
//    
//    init(fileName: String, imageURL: String) {
//        self.fileName = fileName
//        self.imageURL = imageURL
//    }
//}
//
//@available(iOS 15.0, *)
//class AudioCategoryAllVC: UIViewController {
//    
//    @IBOutlet weak var audioCharacterAllCollectionView: UICollectionView!
//    @IBOutlet weak var audioCharacterSlideCollectionview: UICollectionView!
//    
//    var isLoading = true
//    var categoryId: Int = 0
//    private let typeId: Int = 1
//    private var isLoadingMore = false
//    private var isSearchActive = false
//    private var noDataView: NoDataView!
//    private var viewModel = CategoryAllViewModel()
//    private var noInternetView: NoInternetView!
//    private var filteredAudios: [CategoryAllData] = []
//    private var currentDataSource: [CategoryAllData] {
//        return isSearchActive ? filteredAudios : viewModel.audioData
//    }
//    private var selectedIndex: Int = 0
//    
//    private var currentCategoryId: Int = 0
//    private var isFirstLoad: Bool = true
//    
//    @IBOutlet weak var chipSelector: AudioChipSelector!
//    @IBOutlet weak var addcoverButton: UIButton!
//    @IBOutlet weak var addcoverView: UIView!
//    @IBOutlet weak var audioPrankLabel: UILabel!
//    @IBOutlet weak var backButton: UIButton!
//    
//    @IBOutlet weak var searchMainView: UIView!
//    @IBOutlet weak var searchBar: UITextField!
//    @IBOutlet weak var cancelButton: UIButton!
//    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
//    @IBOutlet weak var popularLabel: UILabel!
//    @IBOutlet weak var suggestionCollectionView: UICollectionView!
//    
//    @IBOutlet weak var searchBarView: UIView!
//    
//    private var suggestions: [String] = []
//    
//    private var tagViewModule : TagViewModule!
//    let interstitialAdUtility = InterstitialAdUtility()
//    private let adsViewModel = AdsViewModel()
//    
//    // MARK: - variable
//    private var timer: Timer?
//    private var isPlaying = false
//    var selectedCoverImageURL: String?
//    var selectedCoverImageFile: Data?
//    var selectedCoverImageName: String?
//    private var selectedAudioIndex: Int?
//    private var audioPlayer: AVAudioPlayer?
//    
//    private let defaultImageURLs = [
//        "https://pslink.world/api/public/images/audio1.png",
//        "https://pslink.world/api/public/images/audio2.png",
//        "https://pslink.world/api/public/images/audio3.png",
//        "https://pslink.world/api/public/images/audio4.png",
//        "https://pslink.world/api/public/images/audio5.png"
//    ]
//    
//    private var customAudios: [(url: URL, imageURL: String)] = [] {
//        didSet {
//            saveAudios()
//        }
//    }
//    
//    private var isScrollingFromSliderSelection = false
//    private var nativeMediumAdUtility: NativeMediumAdUtility?
//    var preloadedNativeAdView: GADNativeAdView?
//    
//    init(tagViewModule: TagViewModule) {
//        self.tagViewModule = tagViewModule
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        self.tagViewModule = TagViewModule(apiService: TagAPIManger.shared)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupNoDataView()
//        self.setupSwipeGesture()
//        self.showSkeletonLoader()
//        self.setupNoInternetView()
//        self.setupCollectionView()
//        self.hideKeyboardTappedAround()
//        setupChipSelector()
//        self.loadSavedAudios()
//        self.filteredAudios = viewModel.audioData
//        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handlePremiumContentUnlocked),
//            name: NSNotification.Name("PremiumContentUnlocked"),
//            object: nil
//        )
//                
//                // Reload collection views with default data
//                self.audioCharacterAllCollectionView.reloadData()
//                self.audioCharacterSlideCollectionview.reloadData()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//            guard let self = self else { return }
//            if !self.currentDataSource.isEmpty {
//                let indexPath = IndexPath(item: 0, section: 0)
//                self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                self.selectedIndex = 0
//                
//                if let cell = self.audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell {
//                    cell.playAudio()
//                    AudioPlaybackManager.shared.currentlyPlayingCell = cell
//                    AudioPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
//                }
//            }
//        }
//        
//        self.addcoverView.layer.cornerRadius = 10
//        
//        popularLabel.isHidden = true
//        suggestionCollectionView.isHidden = true
//        cancelButton.isHidden = true
//        searchMainView.isHidden = true
//        searchMainViewHeightConstarints.constant = 0
//        searchBarView.isHidden = true
//        self.audioPrankLabel.isHidden = false
//        
//        // Set the corner radius initially
//        searchMainView.layer.cornerRadius = 10
//        searchBarView.layer.cornerRadius = 10
//        
//        view.bringSubviewToFront(searchMainView)
//        view.bringSubviewToFront(searchBarView)
//        
//        // Add this to your existing setupUI method
//        if let searchMainViewIndex = view.subviews.firstIndex(of: searchMainView) {
//            for subview in view.subviews {
//                if subview is NoDataView || subview is NoInternetView {
//                    view.insertSubview(subview, at: searchMainViewIndex - 1)
//                }
//            }
//        }
//        
//        if isConnectedToInternet() {
//            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
//            } else {
//                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
//                    print("Interstitial Ad ID: \(interstitialAdID)")
//                    interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
//                } else {
//                    print("No Interstitial Ad ID found")
//                }
//            }
//        }
//        
//        // Configure the collection view layout for horizontal scrolling
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .horizontal  // Horizontal scrolling
//        layout.minimumInteritemSpacing = 10  // Space between items
//        layout.minimumLineSpacing = 10      // Space between rows
//        
//        // Add padding to the left side of the collection view
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
//        
//        suggestionCollectionView.collectionViewLayout = layout
//        
//        suggestionCollectionView.setCollectionViewLayout(layout, animated: true)
//        
//        // Set CollectionView delegate and datasource
//        suggestionCollectionView.delegate = self
//        suggestionCollectionView.dataSource = self
//        
//        // Register the custom UICollectionViewCell class or Nib
//        suggestionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SuggestionCell")
//        
//        searchBar.delegate = self
//        searchBar.addTarget(self, action: #selector(searchTextFieldDidChange(_:)), for: .editingChanged)
//        searchBar.returnKeyType = .search
//        searchBar.placeholder = "Search cover image"
//        
//        if let searchBar = searchBar {
//            let placeholderText = "Search cover image"
//            let attributes: [NSAttributedString.Key: Any] = [
//                .foregroundColor: UIColor.lightGray
//            ]
//            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
//        }
//    }
//    
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        stopPlayingAudio()
//    }
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        playVisibleCell()
//    }
//    
//    @objc private func appDidEnterBackground() {
//        if self.isViewLoaded && self.view.window != nil {
//            stopPlayingAudio()
//        }
//    }
//    
//    private func stopPlayingAudio() {
//        if let playingCell = AudioPlaybackManager.shared.currentlyPlayingCell,
//           let playingIndexPath = AudioPlaybackManager.shared.currentlyPlayingIndexPath {
//            playingCell.stopAudio()
//            AudioPlaybackManager.shared.currentlyPlayingCell = nil
//            AudioPlaybackManager.shared.currentlyPlayingIndexPath = nil
//        }
//    }
//    
//    private func preloadNativeAd() {
//        if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
//            print("Preloading Native Ad with ID: \(nativeAdID)")
//            // Create a temporary container for preloading
//            let tempAdContainer = UIView(frame: .zero)
//            
//            nativeMediumAdUtility = NativeMediumAdUtility(
//                adUnitID: nativeAdID,
//                rootViewController: self,
//                nativeAdPlaceholder: tempAdContainer
//            ) { [weak self] success in
//                if success {
//                    // Store the preloaded ad view
//                    if let adView = self?.nativeMediumAdUtility?.nativeAdView {
//                        self?.preloadedNativeAdView = adView
//                    }
//                } else {
//                    print("Failed to preload native ad")
//                }
//            }
//        } else {
//            print("No Native Ad ID found for preloading")
//        }
//    }
//    
//    private func playVisibleCell() {
//        guard !currentDataSource.isEmpty else { return }
//        
//        let visibleRect = CGRect(origin: audioCharacterAllCollectionView.contentOffset, size: audioCharacterAllCollectionView.bounds.size)
//        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
//        
//        if let visibleIndexPath = audioCharacterAllCollectionView.indexPathForItem(at: visiblePoint) {
//            let audioData = currentDataSource[visibleIndexPath.item]
//            
//            // If visible item is premium and locked, stop any playing audio
//            if audioData.premium && !PremiumManager.shared.isContentUnlocked(itemID: audioData.itemID) {
//                AudioPlaybackManager.shared.stopCurrentPlayback()
//                return
//            }
//            
//            // Otherwise proceed with normal playback for non-premium content
//            if let cell = audioCharacterAllCollectionView.cellForItem(at: visibleIndexPath) as? AudioCharacterAllCollectionViewCell {
//                selectedIndex = visibleIndexPath.item
//                AudioPlaybackManager.shared.stopCurrentPlayback()
//                cell.playAudio()
//                AudioPlaybackManager.shared.currentlyPlayingCell = cell
//                AudioPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
//            }
//            
//            audioCharacterSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
//        }
//    }
//    
//    @objc private func handlePremiumContentUnlocked() {
//        DispatchQueue.main.async {
//            let currentIndex = self.selectedIndex
//            
//            self.audioCharacterAllCollectionView.reloadData()
//            self.audioCharacterSlideCollectionview.reloadData()
//            
//            let indexPath = IndexPath(item: currentIndex, section: 0)
//            self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
//            
//            self.selectedIndex = currentIndex
//        }
//    }
//    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    
//    func checkInternetAndFetchData() {
//        if isConnectedToInternet() {
//            fetchAllAudios()
//            self.fetchTagData()
//            self.preloadNativeAd()
//            self.noInternetView?.isHidden = true
//            self.hideNoDataView()
//            // Ensure search views stay on top
//            self.view.bringSubviewToFront(self.searchBarView)
//            self.view.bringSubviewToFront(self.searchMainView)
//        } else {
//            self.showNoInternetView()
//            self.hideSkeletonLoader()
//            
//            // Ensure search views stay on top
//            self.view.bringSubviewToFront(self.searchBarView)
//            self.view.bringSubviewToFront(self.searchMainView)
//        }
//    }
//    
//    private func fetchTagData() {
//        tagViewModule.fetchTag(id: "1") { [weak self] result in
//            switch result {
//            case .success(let tagResponse):
//                // Use the array directly
//                self?.suggestions = tagResponse.data
//                self?.suggestionCollectionView.reloadData()
//            case .failure(let error):
//                print("Error fetching tags: \(error.localizedDescription)")
//                // Handle error appropriately
//                self?.searchMainViewHeightConstarints.constant = 0
//                self?.searchMainView.isHidden = true
//                self?.popularLabel.isHidden = true
//                self?.suggestionCollectionView.isHidden = true
//                self?.cancelButton.isHidden = true
//                
//                self?.searchMainView.layer.cornerRadius = 10
//                self?.searchBarView.layer.cornerRadius = 10
//                self?.searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//                
//                UIView.animate(withDuration: 0.3) {
//                    self?.view.layoutIfNeeded()
//                }
//            }
//        }
//    }
//    
//    private func setupCollectionView() {
//        self.audioCharacterAllCollectionView.delegate = self
//        self.audioCharacterAllCollectionView.dataSource = self
//        self.audioCharacterSlideCollectionview.delegate = self
//        self.audioCharacterSlideCollectionview.dataSource = self
//        self.audioCharacterAllCollectionView.isPagingEnabled = true
//        self.audioCharacterAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.audioCharacterSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.audioCharacterSlideCollectionview.register(
//            LoadingFooterView.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
//            withReuseIdentifier: LoadingFooterView.reuseIdentifier
//        )
//        if let layout = audioCharacterSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
//            layout.footerReferenceSize = CGSize(width: 16, height: audioCharacterSlideCollectionview.frame.height)
//        }
//    }
//    
//    private func setupChipSelector() {
//            chipSelector.onCategorySelected = { [weak self] categoryId in
//                guard let self = self else { return }
//                
//                // Update current category ID
//                self.currentCategoryId = categoryId
//                
//                if categoryId == 0 {
//
//                    self.hideSkeletonLoader()
//                    
//                    // Add cover image વાળી chip માટેનો existing code
//                    self.addcoverView.isHidden = false
//                    self.noInternetView.isHidden = true
//                    self.noDataView.isHidden = true
//                    self.searchBarView.isHidden = true
//                    self.audioPrankLabel.isHidden = false
//                    
//                    audioCharacterAllCollectionView.reloadData()
//                    audioCharacterSlideCollectionview.reloadData()
//                    
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                        let indexPath = IndexPath(item: 0, section: 0)
//                        self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
//                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.selectedIndex = 0
//                    }
//                    
//                } else {
//                    // Reset states for API call
//                    self.isLoadingMore = false
//                    self.isFirstLoad = false
//                    self.viewModel.resetPagination()
//                    
//                    self.addcoverView.isHidden = true
//                    self.searchBarView.isHidden = false
//                    self.audioPrankLabel.isHidden = true
//                    
//                    // Clear existing data
//                    self.viewModel.audioData.removeAll()
//                    self.filteredAudios.removeAll()
//                    
//                    // Reset collection views
//                    self.audioCharacterAllCollectionView.reloadData()
//                    self.audioCharacterSlideCollectionview.reloadData()
//                    
//                    // Show loader
//                    self.showSkeletonLoader()
//                    
//                    // Hide no data view before fetching
//                    self.hideNoDataView()
//                    
//                    // Fetch new data
//                    self.checkInternetAndFetchData()
//                }
//            }
//            
//            // Trigger default chip selection
//            chipSelector.selectDefaultChip()
//        }
//    
//    // MARK: - fetchAllAudios
//    func fetchAllAudios() {
//        guard !isLoadingMore else { return }
//        isLoadingMore = true
//        
//        viewModel.fetchAudioData(prankid: 1, categoryId: currentCategoryId, languageid: 1) { [weak self] success in
//            guard let self = self else { return }
//            
//            DispatchQueue.main.async {
//                self.isLoadingMore = false
//                
//                if success {
//                    if self.viewModel.audioData.isEmpty {
//                        self.hideSkeletonLoader()
//                        self.showNoDataView()
//                    } else {
//                        self.hideSkeletonLoader()
//                        self.hideNoDataView()
//                        self.filteredAudios = self.viewModel.audioData
//                        self.audioCharacterAllCollectionView.reloadData()
//                        self.audioCharacterSlideCollectionview.reloadData()
//                        
//                        // Reset selection and play first audio
//                        self.selectedIndex = 0
//                        if !self.isFirstLoad {
//                            if let indexPath = IndexPath(item: 0, section: 0) as? IndexPath {
//                                self.audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
//                                self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
//                                
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                                    self.playVisibleCell()
//                                }
//                            }
//                        }
//                    }
//                } else {
//                    self.hideSkeletonLoader()
//                    if self.viewModel.audioData.isEmpty {
//                        self.showNoDataView()
//                    }
//                }
//            }
//        }
//    }
//    
//    func showSkeletonLoader() {
//        isLoading = true
//        audioCharacterAllCollectionView.reloadData()
//        audioCharacterSlideCollectionview.reloadData()
//    }
//    
//    func hideSkeletonLoader() {
//        isLoading = false
//        audioCharacterAllCollectionView.reloadData()
//        audioCharacterSlideCollectionview.reloadData()
//    }
//    
//    private func setupNoDataView() {
//        noDataView = NoDataView()
//        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        noDataView.isHidden = true
//        
//        // Insert noDataView below searchMainView
//        if let index = view.subviews.firstIndex(of: searchMainView) {
//            self.view.insertSubview(noDataView, belowSubview: searchMainView)
//        } else {
//            self.view.addSubview(noDataView)
//        }
//        
//        //        self.view.addSubview(noDataView)
//        noDataView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            noDataView.topAnchor.constraint(equalTo: chipSelector.bottomAnchor),
//            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    func setupNoInternetView() {
//        noInternetView = NoInternetView()
//        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
//        noInternetView.isHidden = true
//        
//        // Insert noInternetView below searchMainView
//        if let index = view.subviews.firstIndex(of: searchMainView) {
//            self.view.insertSubview(noInternetView, belowSubview: searchMainView)
//        } else {
//            self.view.addSubview(noInternetView)
//        }
//        
//        //  self.view.addSubview(noInternetView)
//        noInternetView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            noInternetView.topAnchor.constraint(equalTo: backButton.bottomAnchor),
//            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    @objc func retryButtonTapped() {
//        if isConnectedToInternet() {
//            noInternetView.isHidden = true
//            noDataView.isHidden = true
//            checkInternetAndFetchData()
//        } else {
//            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
//            snackbar.show(in: self.view, duration: 3.0)
//        }
//    }
//    
//    func showNoInternetView() {
//        self.noInternetView.isHidden = false
//    }
//    
//    func showNoDataView() {
//        noDataView.isHidden = false
//    }
//    
//    func hideNoDataView() {
//        noDataView.isHidden = true
//    }
//    
//    private func isConnectedToInternet() -> Bool {
//        let networkManager = NetworkReachabilityManager()
//        return networkManager?.isReachable ?? false
//    }
//    
//    @IBAction func btnAddCoverImageTapped(_ sender: UIButton) {
//        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
//        let hasInternet = isConnectedToInternet()
//        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
//        
//        if shouldOpenDirectly {
//            let popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AudioPopupVC") as! AudioPopupVC
//            popupVC.modalPresentationStyle = .overCurrentContext
//            popupVC.modalTransitionStyle = .crossDissolve
//            
//            popupVC.recorderCallback = { [weak self] in
//                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CustomRecoderVC") as! CustomRecoderVC
//                vc.delegate = self
//                if #available(iOS 15.0, *) {
//                    if let sheet = vc.sheetPresentationController {
//                        sheet.detents = [.large()]
//                        sheet.prefersGrabberVisible = true
//                    }
//                }
//                self?.present(vc, animated: true)
//            }
//            
//            popupVC.mediaplayerCallback = { [weak self] in
//                self?.openMediaPicker()
//            }
//            present(popupVC, animated: true)
//        } else {
//            interstitialAdUtility.showInterstitialAd()
//            interstitialAdUtility.onInterstitialEarned = { [weak self] in
//                let popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AudioPopupVC") as! AudioPopupVC
//                popupVC.modalPresentationStyle = .overCurrentContext
//                popupVC.modalTransitionStyle = .crossDissolve
//                
//                popupVC.recorderCallback = { [weak self] in
//                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CustomRecoderVC") as! CustomRecoderVC
//                    vc.delegate = self
//                    if #available(iOS 15.0, *) {
//                        if let sheet = vc.sheetPresentationController {
//                            sheet.detents = [.large()]
//                            sheet.prefersGrabberVisible = true
//                        }
//                    }
//                    self?.present(vc, animated: true)
//                }
//                
//                popupVC.mediaplayerCallback = { [weak self] in
//                    self?.openMediaPicker()
//                }
//                
//                self?.present(popupVC, animated: true)
//            }
//        }
//    }
//    
//    
//    @IBAction func backButtonTapped(_ sender: UIButton) {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    private func setupSwipeGesture() {
//        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
//        swipeGesture.edges = .left
//        self.view.addGestureRecognizer(swipeGesture)
//    }
//    
//    @objc private func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
//        if gesture.state == .recognized {
//            self.navigationController?.popViewController(animated: true)
//        }
//    }
//    
//    private func filterContent(with searchText: String) {
//        isSearchActive = !searchText.isEmpty
//        
//        if searchText.isEmpty {
//            filteredAudios = viewModel.audioData
//        } else {
//            filteredAudios = viewModel.audioData.filter { coverPage in
//                let nameMatch = coverPage.name.lowercased().contains(searchText.lowercased())
//                let categoryMatch = coverPage.artistName.lowercased().contains(searchText.lowercased())
//                return nameMatch || categoryMatch
//            }
//        }
//        
//        DispatchQueue.main.async {
//            self.selectedIndex = 0
//            
//            self.audioCharacterAllCollectionView.reloadData()
//            self.audioCharacterSlideCollectionview.reloadData()
//            
//            if self.filteredAudios.isEmpty && !searchText.isEmpty {
//                self.showNoDataView()
//                self.view.bringSubviewToFront(self.searchBarView)
//                self.view.bringSubviewToFront(self.searchMainView)
//                AudioPlaybackManager.shared.stopCurrentPlayback()
//            } else {
//                self.hideNoDataView()
//                
//                
//                if !self.filteredAudios.isEmpty {
//                    let indexPath = IndexPath(item: 0, section: 0)
//                    
//                    if self.audioCharacterAllCollectionView.numberOfItems(inSection: 0) > 0 {
//                        self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                        self.audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                    
//                    if self.audioCharacterSlideCollectionview.numberOfItems(inSection: 0) > 0 {
//                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                    
//                    if !self.filteredAudios.isEmpty {
//                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//                            self.playVisibleCell()
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == audioCharacterAllCollectionView {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            if selectedChipTitle == "Add Audio Prank 🎧" {
//                return (customAudios.isEmpty ? 1 : customAudios.count)
//            } else {
//                return isLoading ? 8 : currentDataSource.count
//            }
//        } else if collectionView == audioCharacterSlideCollectionview {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            if selectedChipTitle == "Add Audio Prank 🎧" {
//                return (customAudios.isEmpty ? 4 : customAudios.count)
//            } else {
//                return isLoading ? 8 : currentDataSource.count
//            }
//        } else {
//            return suggestions.count
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == audioCharacterAllCollectionView {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            
//            if selectedChipTitle == "Add cover image 📸" {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterAllCollectionViewCell", for: indexPath) as! AudioCharacterAllCollectionViewCell
//                cell.audioLabel.text = customAudios.isEmpty ? "Funny name" : "Custom audio \(indexPath.item + 1)"
//                
//                if customAudios.isEmpty {
//                    cell.imageView.loadGif(name: "CoverGIF")
//                    cell.blurImageView.loadGif(name: "CoverGIF")
//                    cell.applyBackgroundBlurEffect()
//                    cell.DoneButton.isHidden = true
//                } else {
//                    let audioData = customAudios[indexPath.item]
//                    if let url = URL(string: audioData.imageURL) {
//                        cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "audioplacholder")) { image, _, _, _ in
//                            cell.originalImage = image
//                            cell.applyBackgroundBlurEffect()
//                        }
//                        cell.DoneButton.isHidden = false
//                    }
//                }
//                cell.adContainerView.isHidden = true
//                cell.premiumButton.isHidden = true
//                cell.premiumActionButton.isHidden = true
//                return cell
//            } else {
//                if isLoading {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                    cell.isUserInteractionEnabled = false
//                    return cell
//                } else {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterAllCollectionViewCell", for: indexPath) as! AudioCharacterAllCollectionViewCell
//                    guard indexPath.row < currentDataSource.count else {
//                        return cell
//                    }
//                    
//                    let audioData = currentDataSource[indexPath.row]
//                    cell.delegate = self
//                    cell.configure(with: audioData, at: indexPath)
//                    return cell
//                }
//            }
//        } else if collectionView == audioCharacterSlideCollectionview {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            
//            if selectedChipTitle == "Add cover image 📸" {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterSliderCollectionViewCell", for: indexPath) as! AudioCharacterSliderCollectionViewCell
//                cell.premiumIconImageView.isHidden = true
//                let audioData = customAudios[indexPath.item]
//                if let url = URL(string: audioData.imageURL) {
//                    cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "audioplacholder"))
//                }
//            } else {
//                if isLoading {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                    cell.isUserInteractionEnabled = false
//                    return cell
//                } else {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterSliderCollectionViewCell", for: indexPath) as! AudioCharacterSliderCollectionViewCell
//                    guard indexPath.row < currentDataSource.count else {
//                        return cell
//                    }
//                    
//                    let coverPageData = currentDataSource[indexPath.row]
//                    cell.configure(with: coverPageData)
//                    
//                    cell.isSelected = indexPath.item == selectedIndex
//                    
//                    return cell
//                }
//            }
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath)
//            
//            // Remove existing subviews
//            cell.contentView.subviews.forEach { $0.removeFromSuperview() }
//            
//            // Create label
//            let label = UILabel()
//            label.text = suggestions[indexPath.row]
//            label.textColor = .white
//            label.textAlignment = .center
//            label.font = UIFont.systemFont(ofSize: 16)
//            
//            // Add label to cell
//            cell.contentView.addSubview(label)
//            
//            // Setup constraints with minimal padding
//            label.translatesAutoresizingMaskIntoConstraints = false
//            NSLayoutConstraint.activate([
//                label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 4),
//                label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -4),
//                label.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor)
//            ])
//            
//            // Style cell
//            cell.backgroundColor = #colorLiteral(red: 0.1215686275, green: 0.1215686275, blue: 0.1215686275, alpha: 1)
//            cell.layer.borderWidth = 1
//            cell.layer.borderColor = #colorLiteral(red: 0.3098039216, green: 0.3176470588, blue: 0.3254901961, alpha: 1)
//            cell.layer.cornerRadius = 10
//            
//            return cell
//        }
//        
//        return UICollectionViewCell()
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        
//        if collectionView == audioCharacterAllCollectionView {
//            guard indexPath.item < currentDataSource.count else { return }
//            
//            selectedIndex = indexPath.item
//            
//            audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//            audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        } else if collectionView == audioCharacterSlideCollectionview {
//            guard indexPath.item < currentDataSource.count else { return }
//            
//            selectedIndex = indexPath.item
//            
//            audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//            audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        } else {
//            let selectedSuggestion = suggestions[indexPath.row]
//            searchBar.text = selectedSuggestion
//            filterContent(with: selectedSuggestion)
//            
//            searchBar.resignFirstResponder()
//            searchMainViewHeightConstarints.constant = 0
//            searchMainView.isHidden = true
//            popularLabel.isHidden = true
//            suggestionCollectionView.isHidden = true
//            cancelButton.isHidden = false
//            
//            // Reset corner radius when a suggestion is selected
//            searchMainView.layer.cornerRadius = 10
//            searchBarView.layer.cornerRadius = 10
//            searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//            
//            UIView.animate(withDuration: 0.3) {
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width: CGFloat = 90
//        let height: CGFloat = 90
//        
//        if collectionView == audioCharacterAllCollectionView {
//            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
//        } else if collectionView == audioCharacterSlideCollectionview {
//            return CGSize(width: width, height: height)
//        } else {
//            // For suggestion collection view
//            let suggestion = suggestions[indexPath.row]
//            
//            // Create a temporary label to measure exact text size
//            let label = UILabel()
//            label.font = UIFont.systemFont(ofSize: 16)
//            label.text = suggestion
//            
//            // Get exact size needed for text
//            let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
//            
//            // Add minimal padding (8 points total - 4 on each side)
//            let cellWidth = labelSize.width + 20
//            
//            return CGSize(width: cellWidth, height: 40)
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let lastItem = viewModel.audioData.count - 1
//        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
//            self.fetchAllAudios()
//        }
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView == audioCharacterAllCollectionView {
//            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
//            perform(#selector(scrollingEnded), with: nil, afterDelay: 0.1)
//            
//            let pageWidth = scrollView.bounds.width
//            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
//            
//            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
//            
//            // Check if current visible item is premium
//            let currentItem = currentDataSource[currentPage]
//            if currentItem.premium && !PremiumManager.shared.isContentUnlocked(itemID: currentItem.itemID) {
//                AudioPlaybackManager.shared.stopCurrentPlayback()
//            }
//            
//            if currentPage != selectedIndex {
//                selectedIndex = currentPage
//                
//                let indexPath = IndexPath(item: currentPage, section: 0)
//                DispatchQueue.main.async {
//                    if currentPage < self.currentDataSource.count {
//                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                }
//            }
//        }
//    }
//    
//    @objc private func scrollingEnded() {
//        playVisibleCell()
//    }
//    
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        
//        if let playingIndexPath = AudioPlaybackManager.shared.currentlyPlayingIndexPath,
//           let cell = audioCharacterAllCollectionView.cellForItem(at: playingIndexPath) as? AudioCharacterAllCollectionViewCell {
//            cell.playAudio()
//        }
//    }
//}
//
//// MARK: - AudioAllCollectionViewCellDelegate
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: AudioAllCollectionViewCellDelegate {
//    func didTapPremiumIcon(for categoryAllData: CategoryAllData) {
//        presentPremiumViewController(for: categoryAllData)
//    }
//    
//    func didTapAudioPlayback(at indexPath: IndexPath) {
//        guard let cell = audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell else {
//            return
//        }
//        
//        if AudioPlaybackManager.shared.currentlyPlayingIndexPath == indexPath {
//            cell.stopAudio()
//            AudioPlaybackManager.shared.currentlyPlayingCell = nil
//            AudioPlaybackManager.shared.currentlyPlayingIndexPath = nil
//        } else {
//            cell.playAudio()
//        }
//    }
//    
//    func didTapDoneButton(for categoryAllData: CategoryAllData) {
//        AudioPlaybackManager.shared.stopCurrentPlayback()
//        if let navigationController = self.navigationController {
//            if let audioVC = navigationController.viewControllers.first(where: { $0 is AudioVC }) as? AudioVC {
//                audioVC.playSelectedAudio(categoryAllData)
//                navigationController.popToViewController(audioVC, animated: true)
//            }
//        }
//    }
//    
//    private func presentPremiumViewController(for categoryAllData: CategoryAllData) {
//        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumPopupVC") as! PremiumPopupVC
//        premiumVC.setItemIDToUnlock(categoryAllData.itemID)
//        premiumVC.modalTransitionStyle = .crossDissolve
//        premiumVC.modalPresentationStyle = .overCurrentContext
//        present(premiumVC, animated: true, completion: nil)
//    }
//}
//
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: UITextFieldDelegate {
//    func textFieldDidBeginEditing(_ textField: UITextField) {
//        // Show the hidden UI elements immediately when textfield is tapped
//        if isConnectedToInternet() {
//            searchMainView.isHidden = false
//            popularLabel.isHidden = false
//            suggestionCollectionView.isHidden = false
//            
//            searchMainViewHeightConstarints.constant = 90
//            
//            // Set corner radius for searchBarView (top corners)
//            searchBarView.layer.cornerRadius = 10
//            searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
//            
//            // Set corner radius for searchMainView (bottom corners)
//            searchMainView.layer.cornerRadius = 10
//            searchMainView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//            
//            // Animate the changes
//            UIView.animate(withDuration: 0.3) {
//                self.view.layoutIfNeeded()
//            }
//        }
//    }
//    
//    @IBAction func searchTextFieldDidChange(_ sender: UITextField) {
//        filterContent(with: sender.text ?? "")
//        cancelButton.isHidden = false
//    }
//    
//    @IBAction func cancelButtonTapped(_ sender: UIButton) {
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//        filterContent(with: "")
//        searchMainViewHeightConstarints.constant = 0
//        searchMainView.isHidden = true
//        popularLabel.isHidden = true
//        suggestionCollectionView.isHidden = true
//        cancelButton.isHidden = true
//        
//        // Restore corner radius when cancel is tapped
//        searchMainView.layer.cornerRadius = 10
//        searchBarView.layer.cornerRadius = 10
//        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//        
//        UIView.animate(withDuration: 0.3) {
//            self.view.layoutIfNeeded()
//        }
//    }
//    
//    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        textField.resignFirstResponder()
//        searchMainViewHeightConstarints.constant = 0
//        searchMainView.isHidden = true
//        popularLabel.isHidden = true
//        suggestionCollectionView.isHidden = true
//        // cancelButton.isHidden = true
//        
//        searchMainView.layer.cornerRadius = 10
//        searchBarView.layer.cornerRadius = 10
//        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
//        return true
//    }
//    
//    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
//        if let text = textField.text, !text.isEmpty {
//            cancelButton.isHidden = false
//        } else {
//            cancelButton.isHidden = true
//        }
//        return true
//    }
//    
//    func textFieldDidEndEditing(_ textField: UITextField) {
//        if let text = textField.text, text.isEmpty {
//            cancelButton.isHidden = true
//        }
//    }
//}
//
//
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC {
//    private func saveAudios() {
//        let audioData = customAudios.map { audio -> CustomAudio in
//            let fileName = audio.url.lastPathComponent
//            return CustomAudio(fileName: fileName, imageURL: audio.imageURL)
//        }
//        
//        if let encoded = try? JSONEncoder().encode(audioData) {
//            UserDefaults.standard.set(encoded, forKey: ConstantValue.is_UserAudios)
//        }
//    }
//    
//    private func loadSavedAudios() {
//        guard let data = UserDefaults.standard.data(forKey: ConstantValue.is_UserAudios),
//              let savedAudios = try? JSONDecoder().decode([CustomAudio].self, from: data) else {
//            return
//        }
//        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//        
//        customAudios = savedAudios.compactMap { savedAudio in
//            let audioUrl = documentsDirectory.appendingPathComponent(savedAudio.fileName)
//            if FileManager.default.fileExists(atPath: audioUrl.path) {
//                return (url: audioUrl, imageURL: savedAudio.imageURL)
//            } else {
//                print("File not found: \(audioUrl.path)")
//                return nil
//            }
//        }
//        DispatchQueue.main.async {
//            self.audioCharacterAllCollectionView.reloadData()
//            self.audioCharacterSlideCollectionview.reloadData()
//        }
//    }
//    
//    private func setupAudioSession() {
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback)
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("Failed to setup audio session: \(error)")
//        }
//    }
//    
//    private func openMediaPicker() {
//        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
//        documentPicker.delegate = self
//        documentPicker.allowsMultipleSelection = false
//        present(documentPicker, animated: true)
//    }
//    
//    private func setupAudioPlayer(with url: URL) {
//        do {
//            if let player = audioPlayer, player.isPlaying {
//                player.stop()
//            }
//            audioPlayer = try AVAudioPlayer(contentsOf: url)
//            audioPlayer?.delegate = self
//            audioPlayer?.prepareToPlay()
//            audioPlayer?.stop()
//            isPlaying = false
//        } catch {
//            print("Error setting up audio player: \(error)")
//        }
//    }
//    
//    private func timeString(from timeInterval: Int) -> String {
//        let minutes = timeInterval / 60
//        let seconds = timeInterval % 60
//        return String(format: "%02d:%02d", minutes, seconds)
//    }
//    
//    private func setupAudioPlayerFromURL(_ url: URL) {
//        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
//            guard let self = self,
//                  let audioData = data,
//                  error == nil else {
//                DispatchQueue.main.async {
//                }
//                print("Error downloading audio: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            DispatchQueue.main.async {
//                do {
//                    self.audioPlayer?.stop()
//                    self.timer?.invalidate()
//                    self.audioPlayer = try AVAudioPlayer(data: audioData)
//                    self.audioPlayer?.delegate = self
//                    self.audioPlayer?.prepareToPlay()
//                } catch {
//                    print("Error setting up audio player: \(error)")
//                }
//            }
//        }.resume()
//    }
//}
//
//// MARK: - UIDocumentPickerDelegate
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        guard let selectedURL = urls.first else { return }
//        
//        do {
//            let audioPlayer = try AVAudioPlayer(contentsOf: selectedURL)
//            let durationInSeconds = audioPlayer.duration
//            
//            if durationInSeconds > 16.0 {
//                DispatchQueue.main.async {
//                    let snackbar = CustomSnackbar(message: "please select a max 15 seconds audio file.", backgroundColor: .snackbar)
//                    snackbar.show(in: self.view, duration: 3.0)
//                }
//                return
//            }
//            
//            DispatchQueue.main.async { [weak self] in
//                guard let self = self else { return }
//                
//                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
//                let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)
//                
//                do {
//                    if FileManager.default.fileExists(atPath: destinationURL.path) {
//                        try FileManager.default.removeItem(at: destinationURL)
//                    }
//                    try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
//                    let randomImageURL = self.getRandomImageURL()
//                    
//                    self.customAudios.insert((url: destinationURL, imageURL: randomImageURL), at: 0)
//                    
//                    DispatchQueue.main.async {
//                        self.audioCharacterSlideCollectionview.reloadData()
//                        self.audioCharacterAllCollectionView.reloadData()
//                        let indexPath = IndexPath(item: 0, section: 0)
//                        self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.collectionView(self.audioCharacterAllCollectionView, didSelectItemAt: indexPath)
//                        self.collectionView(self.audioCharacterSlideCollectionview, didSelectItemAt: indexPath)
//                    }
//                } catch {
//                    print("Error copying file: \(error)")
//                }
//            }
//        } catch {
//            print("Error checking audio duration: \(error)")
//        }
//    }
//    
//    //MARK: - getRandomDefaultImage
//    private func getRandomImageURL() -> String {
//        let randomIndex = Int.random(in: 0..<defaultImageURLs.count)
//        return defaultImageURLs[randomIndex]
//    }
//}
//
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: AVAudioPlayerDelegate {
//    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.isPlaying = false
//            self.timer?.invalidate()
//        }
//    }
//}
//
//@available(iOS 15.0, *)
//extension AudioCategoryAllVC: SaveRecordingDelegate {
//    func didSaveRecording(audioURL: URL, name: String) {
//        let randomImageURL = getRandomImageURL()
//        self.customAudios.insert((url: audioURL, imageURL: randomImageURL), at: 0)
//        
//        do {
//            try AVAudioSession.sharedInstance().setCategory(.playback)
//            try AVAudioSession.sharedInstance().setActive(true)
//        } catch {
//            print("Failed to setup audio session: \(error)")
//        }
//        
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.audioCharacterAllCollectionView.reloadData()
//            self.audioCharacterSlideCollectionview.reloadData()
//            let indexPath = IndexPath(item: 0, section: 0)
//            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//            self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//            self.collectionView(self.audioCharacterSlideCollectionview, didSelectItemAt: indexPath)
//            self.collectionView(self.audioCharacterAllCollectionView, didSelectItemAt: indexPath)
//        }
//    }
//}
