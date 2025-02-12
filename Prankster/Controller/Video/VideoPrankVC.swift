//
//  VideoPrankVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit
import Alamofire
import AVFoundation
import SDWebImage
import GoogleMobileAds
import MobileCoreServices
import Photos

struct CustomVideos {
    let video: URL
    let videoURL: String?
    
    init(video: URL, videoURL: String? = nil) {
        self.video = video
        self.videoURL = videoURL
    }
}

@available(iOS 15.0, *)
class VideoPrankVC: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addvideoView: UIView!
    @IBOutlet weak var searchBarView: UIView!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var videoPrankLabel: UILabel!
    @IBOutlet weak var addvideoButton: UIButton!
    @IBOutlet weak var chipSelector: VideoChipSelector!
    @IBOutlet weak var videoAllCollectionView: UICollectionView!
    @IBOutlet weak var videoSlideCollectionview: UICollectionView!
    @IBOutlet weak var suggestionCollectionView: UICollectionView!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    
    var languageid: Int = 0
    var categoryId: Int = 0
    private var timer: Timer?
    private let typeId: Int = 1
    private var player: AVPlayer?
    private var isPlaying = false
    private var shouldShowGIF = true
    private var isLoadingMore = false
    var selectedCoverImageURL: String?
    var selectedCoverImageFile: Data?
    private var selectedIndex: Int = 0
    private var isSearchActive = false
    private var noDataView: NoDataView!
    var selectedCoverImageName: String?
    private var selectedAudioIndex: Int?
    private var isFirstLoad: Bool = true
    private var selectedVideoIndex: Int?
    var customVideos: [CustomVideos] = []
    private var currentCategoryId: Int = 0
    private var suggestions: [String] = []
    var selectedVideoCustomCell: IndexPath?
    private var shouldAutoPlayVideo = false
    private var playerLayer: AVPlayerLayer?
    private var audioSession: AVAudioSession?
    private var adsViewModel: AdsViewModel!
    private var tagViewModule : TagViewModule!
    var preloadedNativeAdView: GADNativeAdView?
    private var noInternetView: NoInternetView!
    private var viewModel: CategoryAllViewModel!
    private var filteredVideos: [CharacterAllData] = []
    let interstitialAdUtility = InterstitialAdUtility()
    private var nativeMediumAdUtility: NativeMediumAdUtility?
    private var skeletonLoadingView: SkeletonDataLoadingView?
    private var currentDataSource: [CharacterAllData] {
        return isSearchActive ? filteredVideos : viewModel.audioData
    }
    
    init(tagViewModule: TagViewModule, viewModule: CategoryAllViewModel, adViewModule: AdsViewModel) {
        self.tagViewModule = tagViewModule
        self.viewModel = viewModule
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tagViewModule = TagViewModule(apiService: TagAPIManger.shared)
        self.viewModel = CategoryAllViewModel(apiService: CharacterAllAPIManger.shared)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupSkeletonView()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        self.loadCustomVideoURLs()
        setupChipSelector()
        self.filteredVideos = viewModel.audioData
        PremiumManager.shared.clearTemporaryUnlocks()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePremiumContentUnlocked),
            name: NSNotification.Name("PremiumContentUnlocked"),
            object: nil
        )
    }
    
    func setupUI() {
        self.currentCategoryId = 0
        
        self.addvideoView.layer.cornerRadius = 10
        
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        searchMainView.isHidden = true
        searchMainViewHeightConstarints.constant = 0
        searchBarView.isHidden = true
        self.videoPrankLabel.isHidden = false
        
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
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        suggestionCollectionView.collectionViewLayout = layout
        
        suggestionCollectionView.setCollectionViewLayout(layout, animated: true)

        suggestionCollectionView.delegate = self
        suggestionCollectionView.dataSource = self

        suggestionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SuggestionCell")
        
        searchBar.delegate = self
        searchBar.addTarget(self, action: #selector(searchTextFieldDidChange(_:)), for: .editingChanged)
        searchBar.returnKeyType = .search
        searchBar.placeholder = "Search audio or artist name"
        
        if let searchBar = searchBar {
            let placeholderText = "Search audio or artist name"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
    }
    
    private func setupSkeletonView() {
        skeletonLoadingView = SkeletonDataLoadingView()
        skeletonLoadingView?.isHidden = true
        skeletonLoadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        if let skeletonView = skeletonLoadingView {
            view.addSubview(skeletonView)
            
            NSLayoutConstraint.activate([
                skeletonView.topAnchor.constraint(equalTo: chipSelector.bottomAnchor, constant: 3),
                skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingVideo()
    }
    
    @objc private func appDidEnterBackground() {
        if self.isViewLoaded && self.view.window != nil {
            stopPlayingVideo()
        }
    }
    
    private func stopPlayingVideo() {
        if let playingCell = VideoPlaybackManager.shared.currentlyPlayingCell,
           let playingIndexPath = VideoPlaybackManager.shared.currentlyPlayingIndexPath {
            playingCell.stopVideo()
            VideoPlaybackManager.shared.currentlyPlayingCell = nil
            VideoPlaybackManager.shared.currentlyPlayingIndexPath = nil
        }
    }
    
    private func preloadNativeAd() {
        if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
            print("Preloading Native Ad with ID: \(nativeAdID)")
            let tempAdContainer = UIView(frame: .zero)
            
            nativeMediumAdUtility = NativeMediumAdUtility(
                adUnitID: nativeAdID,
                rootViewController: self,
                nativeAdPlaceholder: tempAdContainer
            ) { [weak self] success in
                if success {
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
    
    private func playVisibleCell() {
        if currentCategoryId == 0 {
            guard !customVideos.isEmpty else { return }
            
            let visibleRect = CGRect(origin: videoAllCollectionView.contentOffset, size: videoAllCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            if let visibleIndexPath = videoAllCollectionView.indexPathForItem(at: visiblePoint),
               visibleIndexPath.item < customVideos.count {
                if let cell = videoAllCollectionView.cellForItem(at: visibleIndexPath) as? VideoAllCollectionViewCell {
                    selectedIndex = visibleIndexPath.item
                    VideoPlaybackManager.shared.stopCurrentPlayback()
                    cell.playVideo()
                    VideoPlaybackManager.shared.currentlyPlayingCell = cell
                    VideoPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
                }
                
                videoSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        } else {
            guard !currentDataSource.isEmpty else { return }
            
            let visibleRect = CGRect(origin: videoAllCollectionView.contentOffset, size: videoAllCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            if let visibleIndexPath = videoAllCollectionView.indexPathForItem(at: visiblePoint),
               visibleIndexPath.item < currentDataSource.count {
                let audioData = currentDataSource[visibleIndexPath.item]
                
                if audioData.premium && !PremiumManager.shared.isContentUnlocked(itemID: audioData.itemID) {
                    AudioPlaybackManager.shared.stopCurrentPlayback()
                    return
                }
                
                if let cell = videoAllCollectionView.cellForItem(at: visibleIndexPath) as? VideoAllCollectionViewCell {
                    selectedIndex = visibleIndexPath.item
                    VideoPlaybackManager.shared.stopCurrentPlayback()
                    cell.playVideo()
                    VideoPlaybackManager.shared.currentlyPlayingCell = cell
                    VideoPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
                }
                
                videoSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            let currentIndex = self.selectedIndex
            
            self.videoAllCollectionView.reloadData()
            self.videoSlideCollectionview.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            self.videoAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.videoSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            
            self.selectedIndex = currentIndex
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllVideos()
            self.fetchTagData()
            self.preloadNativeAd()
            self.noInternetView?.isHidden = true
            self.hideNoDataView()
            self.view.bringSubviewToFront(self.searchBarView)
            self.view.bringSubviewToFront(self.searchMainView)
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
            self.view.bringSubviewToFront(self.searchBarView)
            self.view.bringSubviewToFront(self.searchMainView)
        }
    }
    
    private func fetchTagData() {
        tagViewModule.fetchTag(id: "2") { [weak self] result in
            switch result {
            case .success(let tagResponse):
                self?.suggestions = tagResponse.data
                self?.suggestionCollectionView.reloadData()
            case .failure(let error):
                print("Error fetching tags: \(error.localizedDescription)")
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
        self.videoAllCollectionView.delegate = self
        self.videoAllCollectionView.dataSource = self
        self.videoSlideCollectionview.delegate = self
        self.videoSlideCollectionview.dataSource = self
        self.videoAllCollectionView.isPagingEnabled = true
        self.videoSlideCollectionview.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        if let layout = videoSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = CGSize(width: 50, height: videoSlideCollectionview.frame.height)
        }
    }
    
    private func setupChipSelector() {
        chipSelector.onCategorySelected = { [weak self] categoryId in
            guard let self = self else { return }
            self.currentCategoryId = categoryId

            self.selectedIndex = 0
            
            if categoryId == 0 {
                
                self.hideSkeletonLoader()
   
                self.popularLabel.isHidden = true
                self.suggestionCollectionView.isHidden = true
                self.cancelButton.isHidden = true
                self.searchMainView.isHidden = true
                self.searchMainViewHeightConstarints.constant = 0
                self.addvideoView.isHidden = false
                self.noInternetView.isHidden = true
                self.noDataView.isHidden = true
                self.searchBarView.isHidden = true
                self.videoPrankLabel.isHidden = false
                
                videoAllCollectionView.reloadData()
                videoSlideCollectionview.reloadData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    if !self.customVideos.isEmpty && !self.shouldShowGIF {
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.videoAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.selectedIndex = 0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            if let cell = self?.videoAllCollectionView.cellForItem(at: indexPath) as? VideoAllCollectionViewCell {
                                cell.playVideo()
                                VideoPlaybackManager.shared.currentlyPlayingCell = cell
                                VideoPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
                            }
                        }
                    }
                }
                
            } else {
                VideoPlaybackManager.shared.stopCurrentPlayback()
                self.isLoadingMore = false
                self.isFirstLoad = false
                self.viewModel.resetPagination()
                self.addvideoView.isHidden = true
                self.searchBarView.isHidden = false
                self.videoPrankLabel.isHidden = true
                self.viewModel.audioData.removeAll()
                self.filteredVideos.removeAll()
                self.videoAllCollectionView.reloadData()
                self.videoSlideCollectionview.reloadData()
                self.showSkeletonLoader()
                self.hideNoDataView()
                self.checkInternetAndFetchData()
            }
        }
        chipSelector.selectDefaultChip()
    }
    
    // MARK: - fetchAllAudios
    func fetchAllVideos() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        let isPremiumContent = PremiumManager.shared.isContentUnlocked(itemID: -1) ? "true" : "false"
        
        viewModel.fetchAudioData(prankid: 2, categoryId: currentCategoryId, languageid: languageid, ispremium: isPremiumContent) { [weak self] success in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoadingMore = false
                
                if success {
                    if self.viewModel.audioData.isEmpty {
                        self.hideSkeletonLoader()
                        self.showNoDataView()
                        AudioPlaybackManager.shared.stopCurrentPlayback()
                    } else {
                        self.hideSkeletonLoader()
                        self.hideNoDataView()
                        self.filteredVideos = self.viewModel.audioData
                        self.videoAllCollectionView.reloadData()
                        self.videoSlideCollectionview.reloadData()
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.videoSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                self.playVisibleCell()
                            }
                        }
                    }
                }   else if let errorMessage = self.viewModel.errorMessage {
                    self.hideSkeletonLoader()
                    self.showNoDataView()
                    AudioPlaybackManager.shared.stopCurrentPlayback()
                    print("Error fetching all cover pages: \(errorMessage)")
                }
            }
        }
    }
    
    func showSkeletonLoader() {
        skeletonLoadingView?.isHidden = false
        skeletonLoadingView?.startAnimating()
        videoAllCollectionView.reloadData()
        videoSlideCollectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        skeletonLoadingView?.isHidden = true
        skeletonLoadingView?.stopAnimating()
        videoAllCollectionView.reloadData()
        videoSlideCollectionview.reloadData()
    }
    
    private func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true

        if let index = view.subviews.firstIndex(of: searchMainView) {
            self.view.insertSubview(noDataView, belowSubview: searchMainView)
        } else {
            self.view.addSubview(noDataView)
        }

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
        
        if let index = view.subviews.firstIndex(of: searchMainView) {
            self.view.insertSubview(noInternetView, belowSubview: searchMainView)
        } else {
            self.view.addSubview(noInternetView)
        }
        
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
            self.showSkeletonLoader()
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
    
    @IBAction func btnAddVideoTapped(_ sender: UIButton) {
        self.shouldShowGIF = false
        VideoPlaybackManager.shared.stopCurrentPlayback()
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            self.shouldShowGIF = false
            self.addVideoClick()
        } else {
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    self?.shouldShowGIF = false
                    self?.addVideoClick()
                }
                interstitialAdUtility.loadAndShowAd(adUnitID: interstitialAdID, rootViewController: self)
            }
        }
    }
    
    private func addVideoClick() {
        VideoPlaybackManager.shared.stopCurrentPlayback()
        let popupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoPopupVC") as! VideoPopupVC
        popupVC.modalPresentationStyle = .overCurrentContext
        popupVC.modalTransitionStyle = .crossDissolve
        
        popupVC.cameraCallback = { [weak self] in
            self?.btnCameraTapped()
        }
        
        popupVC.downloaderCallback = { [weak self] in
            guard let self = self else { return }
            let downloaderVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VideoDownloaderBottom") as! VideoDownloaderBottom
            downloaderVC.modalPresentationStyle = .pageSheet
            
            if let sheet = downloaderVC.sheetPresentationController {
                sheet.detents = [.large()]
            }
            
            downloaderVC.videoDownloadedCallback = { [weak self] (videoURL, stringURL) in
                guard let self = self,
                      let videoURL = videoURL else { return }
                
                self.handleDownloadedVideo(url: videoURL)
            }
            self.present(downloaderVC, animated: true)
        }
        
        popupVC.galleryCallback = { [weak self] in
            self?.btnGalleryTapped()
        }
        self.present(popupVC, animated: true)
    }
    
    private func handleDownloadedVideo(url: URL) {
        VideoProcessingManager.shared.compressVideo(inputURL: url) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let compressedURL):
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "\(UUID().uuidString).mp4"
                let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                
                do {
                    try FileManager.default.copyItem(at: compressedURL, to: destinationURL)
                    
                    let customVideo = CustomVideos(video: destinationURL, videoURL: destinationURL.absoluteString)
                    customVideos.insert(customVideo, at: 0)
                    selectedVideoIndex = 0
                    saveCustomVideoURLs()
                    
                    DispatchQueue.main.async {
                        self.videoAllCollectionView.reloadData()
                        self.videoSlideCollectionview.reloadData()
                        
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.videoAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.selectedVideoCustomCell = indexPath
                        
                        self.videoAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        self.videoSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            if let cell = self.videoAllCollectionView.cellForItem(at: indexPath) as? VideoAllCollectionViewCell {
                                VideoPlaybackManager.shared.stopCurrentPlayback()
                                
                                cell.playVideo()
                                VideoPlaybackManager.shared.currentlyPlayingCell = cell
                                VideoPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
                            }
                        }
                    }
                    
                } catch {
                    print("Error handling compressed video: \(error)")
                }
                
            case .failure(let error):
                print("Video compression failed: \(error.message)")
            }
        }
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
            filteredVideos = viewModel.audioData
        } else {
            filteredVideos = viewModel.audioData.filter { coverPage in
                let nameMatch = coverPage.name.lowercased().contains(searchText.lowercased())
                let categoryMatch = coverPage.artistName.lowercased().contains(searchText.lowercased())
                return nameMatch || categoryMatch
            }
        }
        
        DispatchQueue.main.async {
            self.selectedIndex = 0
            
            self.videoAllCollectionView.reloadData()
            self.videoSlideCollectionview.reloadData()
            
            if self.filteredVideos.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
                self.view.bringSubviewToFront(self.searchBarView)
                self.view.bringSubviewToFront(self.searchMainView)
                VideoPlaybackManager.shared.stopCurrentPlayback()
            } else {
                self.hideNoDataView()
                
                
                if !self.filteredVideos.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    if self.videoAllCollectionView.numberOfItems(inSection: 0) > 0 {
                        self.videoAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.videoAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if self.videoSlideCollectionview.numberOfItems(inSection: 0) > 0 {
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if !self.filteredVideos.isEmpty {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.playVisibleCell()
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
@available(iOS 15.0, *)
extension VideoPrankVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == suggestionCollectionView {
            return suggestions.count
        } else if collectionView == videoAllCollectionView {
            if currentCategoryId == 0 {
                if shouldShowGIF {
                    return 1
                }
                return (customVideos.isEmpty ? 1 : customVideos.count)
            } else {
                return currentDataSource.count
            }
        } else {
            if currentCategoryId == 0 {
                return (customVideos.isEmpty ? 4 : customVideos.count)
            } else {
                return currentDataSource.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == videoAllCollectionView {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoAllCollectionViewCell", for: indexPath) as! VideoAllCollectionViewCell
                
                if currentCategoryId == 0 {
                    
                    if shouldShowGIF {
                        cell.imageName.text = " Tutorial "
                        cell.tutorialViewShowView.isHidden = false
                        cell.blurImageView.isHidden = true
                        cell.imageView.isHidden = true
                        cell.DoneButton.isHidden = true
                        cell.adContainerView.isHidden = true
                        cell.premiumButton.isHidden = true
                        cell.premiumActionButton.isHidden = true
                        cell.playPauseImageView.isHidden = true
                        DispatchQueue.main.async {
                            cell.setupTutorialVideo()
                        }
                        return cell
                    }
                    
                    if customVideos.isEmpty {
                        cell.tutorialViewShowView.isHidden = false
                        cell.blurImageView.isHidden = true
                        cell.imageView.isHidden = true
                        cell.DoneButton.isHidden = true
                        cell.premiumButton.isHidden = true
                        cell.premiumActionButton.isHidden = true
                        cell.playPauseImageView.isHidden = true
                        DispatchQueue.main.async {
                            cell.setupTutorialVideo()
                        }
                    } else {
                        if indexPath.row < customVideos.count {
                            let videoURL = customVideos[indexPath.row]
                            cell.imageView.isHidden = false
                            cell.blurImageView.isHidden = false
                            cell.tutorialViewShowView.isHidden = true
                            cell.premiumButton.isHidden = true
                            cell.imageView.contentMode = .scaleAspectFit
                            
                            let dummyData = CharacterAllData(file: videoURL.video.absoluteString,
                                                            name: " Custom Video ",
                                                            image: "",
                                                            premium: false,
                                                            itemID: 0, artistName: "")
                            cell.configure(with: dummyData, at: indexPath)
                            cell.configure(with: dummyData)
                            
                            cell.DoneButton.tag = indexPath.row
                            cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                        }
                    }
                } else {
                    if indexPath.row < currentDataSource.count {
                        let audioData = currentDataSource[indexPath.row]
                        
                        cell.blurImageView.isHidden = false
                        cell.tutorialViewShowView.isHidden = true
                        cell.imageView.isHidden = false
                        cell.imageView.contentMode = .scaleAspectFit
                        cell.configure(with: audioData, at: indexPath)
                        cell.configure(with: audioData)
                        
                        cell.premiumActionButton.tag = indexPath.row
                        cell.premiumActionButton.addTarget(self, action: #selector(handlePremiumButtonTap(_:)), for: .touchUpInside)
                        
                        cell.DoneButton.tag = indexPath.row
                        cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                        
                    }
                }
                cell.delegate = self
                return cell
        } else if collectionView == videoSlideCollectionview {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoSliderCollectionViewCell", for: indexPath) as! VideoSliderCollectionViewCell
                
                if currentCategoryId == 0 {
                    if customVideos.isEmpty {
                        cell.imageView.image = UIImage(named: "videoplacholder")
                        cell.premiumIconImageView.isHidden = true
                    } else {
                        cell.premiumIconImageView.isHidden = true
                        if indexPath.row < customVideos.count {
                            let videoURL = customVideos[indexPath.row]
                            cell.setThumbnail(for: videoURL.video)
                        }
                    }
                } else {
                    if indexPath.row < currentDataSource.count {
                        let coverPageData = currentDataSource[indexPath.row]
                        cell.configure(with: coverPageData)
                    }
                }
                cell.isSelected = indexPath.item == selectedIndex
                return cell
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
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    self?.doneButtonClick(sender)
                }
                interstitialAdUtility.loadAndShowAd(adUnitID: interstitialAdID, rootViewController: self)
            }
        }
    }
    
    private func doneButtonClick(_ sender: UIButton) {
        VideoPlaybackManager.shared.stopCurrentPlayback()
        if isConnectedToInternet() {
            if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ShareLinkVC") as? ShareLinkVC {
                if currentCategoryId == 0 {
                    let customImages = customVideos[sender.tag]
                    
                    if let videoURLString = customImages.videoURL,
                       let videoURL = URL(string: videoURLString),
                       videoURL.scheme?.lowercased() == "http" || videoURL.scheme?.lowercased() == "https" {
                        vc.selectedURL = videoURLString
                    } else {
                        if let fileData = try? Data(contentsOf: customImages.video) {
                            vc.selectedFile = fileData
                        }
                    }
                    vc.selectedName = selectedCoverImageName
                    vc.selectedCoverURL = selectedCoverImageURL
                    vc.selectedCoverFile = selectedCoverImageFile
                    vc.selectedPranktype = "video"
                    vc.selectedFileType = "mp4"
                    vc.sharePrank = true
                } else {
                    let categoryAllData = currentDataSource[sender.tag]
                    vc.selectedURL = categoryAllData.file
                    vc.selectedName = selectedCoverImageName
                    vc.selectedCoverURL = selectedCoverImageURL
                    vc.selectedCoverFile = selectedCoverImageFile
                    vc.selectedPranktype = "video"
                    vc.selectedFileType = "mp4"
                    vc.sharePrank = true
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }  else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == videoAllCollectionView {
            
        } else if collectionView == videoSlideCollectionview {
            
            shouldShowGIF = false
            
            if currentCategoryId == 0 {
                if customVideos.isEmpty {
                    collectionView.deselectItem(at: indexPath, animated: false)
                    return
                }
            }
            
            videoAllCollectionView.reloadData()
            
            videoAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            videoAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.playVisibleCell()
            }
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
        
        if collectionView == videoAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == videoSlideCollectionview {
            return CGSize(width: width, height: height)
        } else {
            let suggestion = suggestions[indexPath.row]

            let label = UILabel()
            label.font = UIFont.systemFont(ofSize: 16)
            label.text = suggestion

            let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: 40))
            let cellWidth = labelSize.width + 20
            
            return CGSize(width: cellWidth, height: 40)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = viewModel.audioData.count - 1
        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
            self.fetchAllVideos()
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
                if !isSearchActive && viewModel.hasMorePages && !viewModel.audioData.isEmpty {
                    footer.startAnimating()
                } else {
                    footer.stopAnimating()
                }
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == videoAllCollectionView else { return }
        
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
        
        for cell in videoAllCollectionView.visibleCells {
            let cellCenterX = cell.center.x
            let distanceFromCenter = centerX - cellCenterX
            
            let swipeProgress = distanceFromCenter / pageWidth
            
            let translationX = -distanceFromCenter
            let translationY = abs(distanceFromCenter) * 0.3
            let rotation = swipeProgress * (CGFloat.pi / 8)

            var transform = CGAffineTransform.identity
            transform = transform.translatedBy(x: translationX, y: translationY)
            transform = transform.rotated(by: rotation)
            
            cell.transform = transform
        }
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
        perform(#selector(scrollingEnded), with: nil, afterDelay: 0.1)
        
        let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
        
        if currentCategoryId == 0 {
            
            guard currentPage >= 0 && currentPage < customVideos.count else { return }
        } else {
            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
            
            let currentItem = currentDataSource[currentPage]
            if currentItem.premium && !PremiumManager.shared.isContentUnlocked(itemID: currentItem.itemID) {
                VideoPlaybackManager.shared.stopCurrentPlayback()
            }
        }
        
        if currentPage != selectedIndex {
            selectedIndex = currentPage
            
            let indexPath = IndexPath(item: currentPage, section: 0)
            DispatchQueue.main.async {
                if self.currentCategoryId == 0 {
                    if currentPage < self.customVideos.count {
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                } else {
                    if currentPage < self.currentDataSource.count {
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == videoAllCollectionView else { return }
        
        UIView.animate(withDuration: 0.3) {
            for cell in self.videoAllCollectionView.visibleCells {
                cell.transform = .identity
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == videoAllCollectionView else { return }
        
        if !decelerate {
            UIView.animate(withDuration: 0.3) {
                for cell in self.videoAllCollectionView.visibleCells {
                    cell.transform = .identity
                }
            }
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == videoAllCollectionView else { return }
        
        let pageWidth = scrollView.frame.width
        let targetXContentOffset = targetContentOffset.pointee.x
        let newTargetOffset = round(targetXContentOffset / pageWidth) * pageWidth
        
        targetContentOffset.pointee = CGPoint(x: newTargetOffset, y: targetContentOffset.pointee.y)
    }
    
    @objc private func scrollingEnded() {
        playVisibleCell()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        videoAllCollectionView.reloadData()
        
        if let playingIndexPath = VideoPlaybackManager.shared.currentlyPlayingIndexPath,
           let cell = videoAllCollectionView.cellForItem(at: playingIndexPath) as? VideoAllCollectionViewCell {
            cell.playVideo()
        }
    }
}

// MARK: - AudioAllCollectionViewCellDelegate
@available(iOS 15.0, *)
extension VideoPrankVC: VideoAllCollectionViewCellDelegate {
    func didTapVideoPlayback(at indexPath: IndexPath) {
        guard let cell = videoAllCollectionView.cellForItem(at: indexPath) as? VideoAllCollectionViewCell else {
            return
        }
        
        if VideoPlaybackManager.shared.currentlyPlayingIndexPath == indexPath {
            cell.stopVideo()
            VideoPlaybackManager.shared.currentlyPlayingCell = nil
            VideoPlaybackManager.shared.currentlyPlayingIndexPath = nil
        } else {
            cell.playVideo()
        }
    }
}

@available(iOS 15.0, *)
extension VideoPrankVC: UITextFieldDelegate {
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

@available(iOS 15.0, *)
extension VideoPrankVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func btnCameraTapped() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.showVideoPicker(for: .camera)
                    } else {
                        self?.showPermissionSnackbar(for: "camera")
                    }
                }
            }
        case .authorized:
            showVideoPicker(for: .camera)
        case .denied, .restricted:
            showPermissionSnackbar(for: "camera")
        @unknown default:
            break
        }
    }
    
    private func btnGalleryTapped() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.showVideoPicker(for: .photoLibrary)
                    } else {
                        self?.showPermissionSnackbar(for: "photo library")
                    }
                }
            }
        case .authorized, .limited:
            showVideoPicker(for: .photoLibrary)
        case .denied, .restricted:
            showPermissionSnackbar(for: "photo library")
        @unknown default:
            break
        }
    }
    
    private func showVideoPicker(for sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("Source type \(sourceType) is not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = [kUTTypeMovie as String]

        picker.videoQuality = .typeHigh

        if sourceType == .camera {
            if let cameraDevice = AVCaptureDevice.default(for: .video) {
                do {
                    try cameraDevice.lockForConfiguration()
                    if cameraDevice.isExposureModeSupported(.continuousAutoExposure) {
                        cameraDevice.exposureMode = .continuousAutoExposure
                    }
                    if cameraDevice.isFocusModeSupported(.continuousAutoFocus) {
                        cameraDevice.focusMode = .continuousAutoFocus
                    }
                    if cameraDevice.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                        cameraDevice.whiteBalanceMode = .continuousAutoWhiteBalance
                    }
                    cameraDevice.unlockForConfiguration()
                } catch {
                    print("Camera configuration error: \(error)")
                }
            }
        }
        
        picker.allowsEditing = true
        picker.videoMaximumDuration = 15.0

        if #available(iOS 14.0, *) {
            picker.videoExportPreset = AVAssetExportPresetPassthrough
        }
        
        present(picker, animated: true)
    }
    
    private func showPermissionSnackbar(for feature: String) {
        let messageKey: String
        
        switch feature {
        case "camera":
            messageKey = "We need access to your camera to record a video."
        case "photo library":
            messageKey = "We need access to your photo library to select a video."
        default:
            messageKey = "We need access to your camera to record a video."
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
        guard let videoURL = info[.mediaURL] as? URL else {
            picker.dismiss(animated: true)
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > 16.0 {
            picker.dismiss(animated: true) {
                let snackbar = CustomSnackbar(message: "Please select a max 15 seconds video file.", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
            return
        }
        
        let loadingView = UIActivityIndicatorView(style: .large)
        loadingView.center = self.view.center
        loadingView.color = .white
        self.view.addSubview(loadingView)
        loadingView.startAnimating()
        
        picker.dismiss(animated: true)
        
        VideoProcessingManager.shared.processVideo(inputURL: videoURL) { [weak self] result in
            DispatchQueue.main.async {
                loadingView.removeFromSuperview()
                
                guard let self = self else { return }
                
                switch result {
                case .success(let compressedVideoURL):
                    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileName = "\(UUID().uuidString).mp4"
                    let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                    
                    do {
                        try FileManager.default.copyItem(at: compressedVideoURL, to: destinationURL)
                        
                        let customVideo = CustomVideos(video: destinationURL, videoURL: destinationURL.absoluteString)
                        self.customVideos.insert(customVideo, at: 0)
                        self.selectedVideoIndex = 0
                        self.saveCustomVideoURLs()
                        
                        self.videoAllCollectionView.reloadData()
                        self.videoSlideCollectionview.reloadData()
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.videoAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.selectedVideoCustomCell = indexPath
                        self.videoAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        self.videoSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            if let cell = self?.videoAllCollectionView.cellForItem(at: indexPath) as? VideoAllCollectionViewCell {
                                cell.playVideo()
                            }
                        }
                        
                    } catch {
                        print("Error copying processed video: \(error)")
                        let snackbar = CustomSnackbar(message: "Failed to save video", backgroundColor: .snackbar)
                        snackbar.show(in: self.view, duration: 3.0)
                    }
                    
                case .failure(let error):
                    let snackbar = CustomSnackbar(message: error.message, backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func saveCustomVideoURLs() {
        let videoURLStrings = customVideos.map { $0.video.absoluteString }
        UserDefaults.standard.set(videoURLStrings, forKey: ConstantValue.is_UserVideos)
    }
    
    private func loadCustomVideoURLs() {
        guard let savedVideoURLStrings = UserDefaults.standard.stringArray(forKey: ConstantValue.is_UserVideos) else {
            return
        }
        
        customVideos = savedVideoURLStrings.compactMap { urlString in
            guard let url = URL(string: urlString),
                  FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return CustomVideos(video: url, videoURL: urlString)
        }
    }
}
