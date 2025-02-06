//
//  AudioPrankVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 17/10/24.
//
//

import UIKit
import Alamofire
import AVFoundation
import SDWebImage
import GoogleMobileAds
import MobileCoreServices

struct CustomAudio: Codable {
    let fileName: String
    let imageURL: String
    
    init(fileName: String, imageURL: String) {
        self.fileName = fileName
        self.imageURL = imageURL
    }
}

@available(iOS 15.0, *)
class AudioPrankVC: UIViewController {
    
    @IBOutlet weak var audioCharacterAllCollectionView: UICollectionView!
    @IBOutlet weak var audioCharacterSlideCollectionview: UICollectionView!
    @IBOutlet weak var chipSelector: AudioChipSelector!
    @IBOutlet weak var addcoverButton: UIButton!
    @IBOutlet weak var addcoverView: UIView!
    @IBOutlet weak var audioPrankLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var suggestionCollectionView: UICollectionView!
    @IBOutlet weak var searchBarView: UIView!
    
    // MARK: - properties
    var isLoading = true
    var languageid: Int = 0
    var categoryId: Int = 0
    private var timer: Timer?
    private let typeId: Int = 1
    private var isPlaying = false
    var selectedCoverImageFile: Data?
    private var isLoadingMore = false
    var selectedCoverImageURL: String?
    private var isSearchActive = false
    var selectedCoverImageName: String?
    private var selectedAudioIndex: Int?
    private var selectedIndex: Int = 0
    private var noDataView: NoDataView!
    private var isFirstLoad: Bool = true
    private var suggestions: [String] = []
    private var currentCategoryId: Int = 0
    private var audioPlayer: AVAudioPlayer?
    private var viewModel = CategoryAllViewModel()
    private var noInternetView: NoInternetView!
    private var filteredAudios: [CategoryAllData] = []
    private var currentDataSource: [CategoryAllData] {
        return isSearchActive ? filteredAudios : viewModel.audioData
    }
    
    private let adsViewModel = AdsViewModel()
    private var tagViewModule : TagViewModule!
    let interstitialAdUtility = InterstitialAdUtility()
    private var nativeMediumAdUtility: NativeMediumAdUtility?
    var preloadedNativeAdView: GADNativeAdView?
    
    private var shouldShowGIF = true
    
    private let defaultImageURLs = [
        "https://pslink.world/api/public/images/audio1.png",
        "https://pslink.world/api/public/images/audio2.png",
        "https://pslink.world/api/public/images/audio3.png",
        "https://pslink.world/api/public/images/audio4.png",
        "https://pslink.world/api/public/images/audio5.png"
    ]
    
    private var customAudios: [(url: URL, imageURL: String)] = [] {
        didSet {
            saveAudios()
            if currentCategoryId == 0 {
                audioCharacterAllCollectionView.reloadData()
                audioCharacterSlideCollectionview.reloadData()
            }
        }
    }
    
    init(tagViewModule: TagViewModule) {
        self.tagViewModule = tagViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.tagViewModule = TagViewModule(apiService: TagAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        self.loadSavedAudios()
        self.setupChipSelector()
        self.filteredAudios = viewModel.audioData
        PremiumManager.shared.clearTemporaryUnlocks()
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePremiumContentUnlocked),
            name: NSNotification.Name("PremiumContentUnlocked"),
            object: nil
        )
        
        self.currentCategoryId = 0
        
        self.addcoverView.layer.cornerRadius = 10
        self.popularLabel.isHidden = true
        self.suggestionCollectionView.isHidden = true
        self.cancelButton.isHidden = true
        self.searchMainView.isHidden = true
        self.searchMainViewHeightConstarints.constant = 0
        self.searchBarView.isHidden = true
        self.audioPrankLabel.isHidden = false
        
        self.searchMainView.layer.cornerRadius = 10
        self.searchBarView.layer.cornerRadius = 10
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingAudio()
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        playVisibleCell()
//    }
    
    @objc private func appDidEnterBackground() {
        if self.isViewLoaded && self.view.window != nil {
            stopPlayingAudio()
        }
    }
    
    private func stopPlayingAudio() {
        if let playingCell = AudioPlaybackManager.shared.currentlyPlayingCell,
           let playingIndexPath = AudioPlaybackManager.shared.currentlyPlayingIndexPath {
            playingCell.stopAudio()
            AudioPlaybackManager.shared.currentlyPlayingCell = nil
            AudioPlaybackManager.shared.currentlyPlayingIndexPath = nil
        }
    }
    
    private func preloadNativeAd() {
        if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
            print("Preloading Native Ad with ID: \(nativeAdID)")
            let tempAdContainer = UIView(frame: .zero)
            nativeMediumAdUtility = NativeMediumAdUtility(adUnitID: nativeAdID,rootViewController: self,nativeAdPlaceholder: tempAdContainer) { [weak self] success in
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
            guard !customAudios.isEmpty else { return }
            
            let visibleRect = CGRect(origin: audioCharacterAllCollectionView.contentOffset, size: audioCharacterAllCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            if let visibleIndexPath = audioCharacterAllCollectionView.indexPathForItem(at: visiblePoint),
               visibleIndexPath.item < customAudios.count {
                if let cell = audioCharacterAllCollectionView.cellForItem(at: visibleIndexPath) as? AudioCharacterAllCollectionViewCell {
                    selectedIndex = visibleIndexPath.item
                    AudioPlaybackManager.shared.stopCurrentPlayback()
                    cell.playAudio()
                    AudioPlaybackManager.shared.currentlyPlayingCell = cell
                    AudioPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
                }
                audioCharacterSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        } else {
            guard !currentDataSource.isEmpty else { return }
            
            let visibleRect = CGRect(origin: audioCharacterAllCollectionView.contentOffset, size: audioCharacterAllCollectionView.bounds.size)
            let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
            
            if let visibleIndexPath = audioCharacterAllCollectionView.indexPathForItem(at: visiblePoint),
               visibleIndexPath.item < currentDataSource.count {
                let audioData = currentDataSource[visibleIndexPath.item]
                
                if audioData.premium && !PremiumManager.shared.isContentUnlocked(itemID: audioData.itemID) {
                    AudioPlaybackManager.shared.stopCurrentPlayback()
                    return
                }
                
                if let cell = audioCharacterAllCollectionView.cellForItem(at: visibleIndexPath) as? AudioCharacterAllCollectionViewCell {
                    selectedIndex = visibleIndexPath.item
                    AudioPlaybackManager.shared.stopCurrentPlayback()
                    cell.playAudio()
                    AudioPlaybackManager.shared.currentlyPlayingCell = cell
                    AudioPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
                }
                audioCharacterSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
            }
        }
    }
    
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            let currentIndex = self.selectedIndex
            
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            
            self.selectedIndex = currentIndex
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllAudios()
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
        tagViewModule.fetchTag(id: "1") { [weak self] result in
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
        self.audioCharacterAllCollectionView.delegate = self
        self.audioCharacterAllCollectionView.dataSource = self
        self.audioCharacterSlideCollectionview.delegate = self
        self.audioCharacterSlideCollectionview.dataSource = self
        self.audioCharacterAllCollectionView.isPagingEnabled = true
        self.audioCharacterAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.audioCharacterSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.audioCharacterSlideCollectionview.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        if let layout = audioCharacterSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = CGSize(width: 50, height: audioCharacterSlideCollectionview.frame.height)
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
                self.addcoverView.isHidden = false
                self.noInternetView.isHidden = true
                self.noDataView.isHidden = true
                self.searchBarView.isHidden = true
                self.audioPrankLabel.isHidden = false
                
                audioCharacterAllCollectionView.reloadData()
                audioCharacterSlideCollectionview.reloadData()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self else { return }
                    if !self.customAudios.isEmpty && !self.shouldShowGIF {
                        let indexPath = IndexPath(item: 0, section: 0)
                        self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.selectedIndex = 0
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                            if let cell = self?.audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell {
                                cell.playAudio()
                                AudioPlaybackManager.shared.currentlyPlayingCell = cell
                                AudioPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
                            }
                        }
                    }
                }
            } else {
                AudioPlaybackManager.shared.stopCurrentPlayback()
                self.isLoadingMore = false
                self.isFirstLoad = false
                self.viewModel.resetPagination()
                self.addcoverView.isHidden = true
                self.searchBarView.isHidden = false
                self.audioPrankLabel.isHidden = true
                self.viewModel.audioData.removeAll()
                self.filteredAudios.removeAll()
                self.audioCharacterAllCollectionView.reloadData()
                self.audioCharacterSlideCollectionview.reloadData()
                self.showSkeletonLoader()
                self.hideNoDataView()
                self.checkInternetAndFetchData()
            }
        }
        chipSelector.selectDefaultChip()
    }
    
    // MARK: - fetchAllAudios
    func fetchAllAudios() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        
        viewModel.fetchAudioData(prankid: 1, categoryId: currentCategoryId, languageid: languageid) { [weak self] success in
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
                        self.filteredAudios = self.viewModel.audioData
                        self.audioCharacterAllCollectionView.reloadData()
                        self.audioCharacterSlideCollectionview.reloadData()
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            
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
        isLoading = true
        audioCharacterAllCollectionView.reloadData()
        audioCharacterSlideCollectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        audioCharacterAllCollectionView.reloadData()
        audioCharacterSlideCollectionview.reloadData()
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
    
    @IBAction func btnAddAudioTapped(_ sender: UIButton) {
        self.shouldShowGIF = false
        AudioPlaybackManager.shared.stopCurrentPlayback()
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            self.shouldShowGIF = false
            self.addAudioClick()
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shouldShowGIF = false
                self?.addAudioClick()
            }
        }
    }
    
    private func addAudioClick() {
        AudioPlaybackManager.shared.stopCurrentPlayback()
        let audioPopupVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AudioPopupVC") as! AudioPopupVC
        audioPopupVC.modalPresentationStyle = .overCurrentContext
        audioPopupVC.modalTransitionStyle = .crossDissolve
        
        audioPopupVC.recorderCallback = { [weak self] in
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CustomRecoderVC") as! CustomRecoderVC
            vc.delegate = self
            if #available(iOS 15.0, *) {
                if let sheet = vc.sheetPresentationController {
                    sheet.detents = [.large()]
                    sheet.prefersGrabberVisible = true
                }
            }
            self?.present(vc, animated: true)
        }
        audioPopupVC.mediaplayerCallback = { [weak self] in
            self?.openMediaPicker()
        }
        self.present(audioPopupVC, animated: true)
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
            filteredAudios = viewModel.audioData
        } else {
            filteredAudios = viewModel.audioData.filter { coverPage in
                let nameMatch = coverPage.name.lowercased().contains(searchText.lowercased())
                let categoryMatch = coverPage.artistName.lowercased().contains(searchText.lowercased())
                return nameMatch || categoryMatch
            }
        }
        
        DispatchQueue.main.async {
            self.selectedIndex = 0
            
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
            
            if self.filteredAudios.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
                self.view.bringSubviewToFront(self.searchBarView)
                self.view.bringSubviewToFront(self.searchMainView)
                AudioPlaybackManager.shared.stopCurrentPlayback()
            } else {
                self.hideNoDataView()
                
                
                if !self.filteredAudios.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    if self.audioCharacterAllCollectionView.numberOfItems(inSection: 0) > 0 {
                        self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if self.audioCharacterSlideCollectionview.numberOfItems(inSection: 0) > 0 {
                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if !self.filteredAudios.isEmpty {
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
extension AudioPrankVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == suggestionCollectionView {
            return suggestions.count
        } else if collectionView == audioCharacterAllCollectionView {
            
            if currentCategoryId == 0 {
                if shouldShowGIF {
                    return 1
                }
                return (customAudios.isEmpty ? 1 : customAudios.count)
            } else {
                if isLoading {
                    return 4
                }
                return currentDataSource.count
            }
        } else {
            if currentCategoryId == 0 {
                return (customAudios.isEmpty ? 4 : customAudios.count)
            } else {
                if isLoading {
                    return 4
                }
                return currentDataSource.count
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == audioCharacterAllCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterAllCollectionViewCell", for: indexPath) as! AudioCharacterAllCollectionViewCell
                
                if currentCategoryId == 0 {
                    
                    if shouldShowGIF {
                        cell.audioLabel.text = " Tutorial "
                        cell.imageView.loadGif(name: "audio")
                        cell.imageView.contentMode = .scaleAspectFill
                        cell.applyBackgroundBlurEffect()
                        cell.DoneButton.isHidden = true
                        cell.adContainerView.isHidden = true
                        cell.premiumButton.isHidden = true
                        cell.premiumActionButton.isHidden = true
                        cell.playPauseImageView.isHidden = true
                        return cell
                    }
                    
                    if customAudios.isEmpty {
                        cell.imageView.loadGif(name: "audio")
                        cell.audioLabel.text = " Tutorial "
                        cell.imageView.contentMode = .scaleAspectFill
                        cell.applyBackgroundBlurEffect()
                        cell.playPauseImageView.isHidden = true
                        cell.DoneButton.isHidden = true
                        cell.premiumButton.isHidden = true
                        cell.premiumActionButton.isHidden = true
                    } else {
                        let customAudio = customAudios[indexPath.row]
                        cell.imageView.contentMode = .scaleAspectFit
                        cell.configure(with: nil, customAudio: customAudio, at: indexPath)
                        
                        cell.DoneButton.tag = indexPath.row
                        cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                    }
                } else {
                    if indexPath.row < currentDataSource.count {
                        let audioData = currentDataSource[indexPath.row]
                        cell.imageView.contentMode = .scaleAspectFit
                        cell.configure(with: audioData, customAudio: nil, at: indexPath)
                        
                        cell.premiumActionButton.tag = indexPath.row
                        cell.premiumActionButton.addTarget(self, action: #selector(handlePremiumButtonTap(_:)), for: .touchUpInside)
                        
                        cell.DoneButton.tag = indexPath.row
                        cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
                    }
                }
                cell.delegate = self
                return cell
            }
        } else if collectionView == audioCharacterSlideCollectionview {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterSliderCollectionViewCell", for: indexPath) as! AudioCharacterSliderCollectionViewCell
                
                if currentCategoryId == 0 {
                    if customAudios.isEmpty {
                        cell.imageView.image = UIImage(named: "audioplacholder")
                        cell.premiumIconImageView.isHidden = true
                    } else {
                        cell.premiumIconImageView.isHidden = true
                        if indexPath.row < customAudios.count {
                            let customAudio = customAudios[indexPath.row]
                            if let url = URL(string: customAudio.imageURL) {
                                cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "audioplacholder"))
                            }
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
        AudioPlaybackManager.shared.stopCurrentPlayback()
        if let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ShareLinkVC") as? ShareLinkVC {
            if self.currentCategoryId == 0 {
                
                let customImages = self.customAudios[sender.tag]
                if let fileData = try? Data(contentsOf: customImages.url) {
                    vc.selectedFile = fileData
                    vc.selectedImage = customImages.imageURL
                    vc.selectedName = self.selectedCoverImageName
                    vc.selectedCoverURL = self.selectedCoverImageURL
                    vc.selectedCoverFile = self.selectedCoverImageFile
                    vc.selectedPranktype = "audio"
                    vc.selectedFileType = "mp3"
                    vc.sharePrank = true
                }
            } else {
                let categoryAllData = self.currentDataSource[sender.tag]
                vc.selectedURL = categoryAllData.file
                vc.selectedImage = categoryAllData.image
                vc.selectedName = self.selectedCoverImageName
                vc.selectedCoverURL = self.selectedCoverImageURL
                vc.selectedCoverFile = self.selectedCoverImageFile
                vc.selectedPranktype = "audio"
                vc.selectedFileType = "mp3"
                vc.sharePrank = true
            }
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == audioCharacterAllCollectionView {
            
        } else if collectionView == audioCharacterSlideCollectionview {
            
            shouldShowGIF = false
            
            if currentCategoryId == 0 {
                if customAudios.isEmpty {
                    collectionView.deselectItem(at: indexPath, animated: false)
                    return
                }
            }
            
            audioCharacterAllCollectionView.reloadData()
            
            audioCharacterAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)

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
        
        if collectionView == audioCharacterAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == audioCharacterSlideCollectionview {
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
           // DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [self] in
                self.fetchAllAudios()
          //  }
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
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == audioCharacterAllCollectionView else { return }
        
        let pageWidth = scrollView.bounds.width
        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
        
        for cell in audioCharacterAllCollectionView.visibleCells {
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
            
            guard currentPage >= 0 && currentPage < customAudios.count else { return }
        } else {
            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
            
            let currentItem = currentDataSource[currentPage]
            if currentItem.premium && !PremiumManager.shared.isContentUnlocked(itemID: currentItem.itemID) {
                AudioPlaybackManager.shared.stopCurrentPlayback()
            }
        }
        
        if currentPage != selectedIndex {
            selectedIndex = currentPage
            
            let indexPath = IndexPath(item: currentPage, section: 0)
            DispatchQueue.main.async {
                if self.currentCategoryId == 0 {
                    if currentPage < self.customAudios.count {
                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                } else {
                    if currentPage < self.currentDataSource.count {
                        self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard scrollView == audioCharacterAllCollectionView else { return }
        
        UIView.animate(withDuration: 0.3) {
            for cell in self.audioCharacterAllCollectionView.visibleCells {
                cell.transform = .identity
            }
        }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard scrollView == audioCharacterAllCollectionView else { return }
        
        if !decelerate {
            UIView.animate(withDuration: 0.3) {
                for cell in self.audioCharacterAllCollectionView.visibleCells {
                    cell.transform = .identity
                }
            }
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == audioCharacterAllCollectionView else { return }
        
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
        if let playingIndexPath = AudioPlaybackManager.shared.currentlyPlayingIndexPath,
           let cell = audioCharacterAllCollectionView.cellForItem(at: playingIndexPath) as? AudioCharacterAllCollectionViewCell {
            cell.playAudio()
        }
    }
}

// MARK: - AudioAllCollectionViewCellDelegate
@available(iOS 15.0, *)
extension AudioPrankVC: AudioAllCollectionViewCellDelegate {
    
    func didTapAudioPlayback(at indexPath: IndexPath) {
        guard let cell = audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell else {
            return
        }
        
        if AudioPlaybackManager.shared.currentlyPlayingIndexPath == indexPath {
            cell.stopAudio()
            AudioPlaybackManager.shared.currentlyPlayingCell = nil
            AudioPlaybackManager.shared.currentlyPlayingIndexPath = nil
        } else {
            cell.playAudio()
        }
    }
}

@available(iOS 15.0, *)
extension AudioPrankVC: UITextFieldDelegate {
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
extension AudioPrankVC {
    private func saveAudios() {
        let audioData = customAudios.map { audio -> CustomAudio in
            let fileName = audio.url.lastPathComponent
            return CustomAudio(fileName: fileName, imageURL: audio.imageURL)
        }
        
        if let encoded = try? JSONEncoder().encode(audioData) {
            UserDefaults.standard.set(encoded, forKey: ConstantValue.is_UserAudios)
        }
    }
    
    private func loadSavedAudios() {
        guard let data = UserDefaults.standard.data(forKey: ConstantValue.is_UserAudios),
              let savedAudios = try? JSONDecoder().decode([CustomAudio].self, from: data) else {
            return
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        customAudios = savedAudios.compactMap { savedAudio in
            let audioUrl = documentsDirectory.appendingPathComponent(savedAudio.fileName)
            if FileManager.default.fileExists(atPath: audioUrl.path) {
                return (url: audioUrl, imageURL: savedAudio.imageURL)
            } else {
                print("File not found: \(audioUrl.path)")
                return nil
            }
        }
        DispatchQueue.main.async {
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func openMediaPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    private func setupAudioPlayer(with url: URL) {
        do {
            if let player = audioPlayer, player.isPlaying {
                player.stop()
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.stop()
            isPlaying = false
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func timeString(from timeInterval: Int) -> String {
        let minutes = timeInterval / 60
        let seconds = timeInterval % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - UIDocumentPickerDelegate
@available(iOS 15.0, *)
extension AudioPrankVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        let asset = AVAsset(url: selectedURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration <= 16.0 {
            didSaveRecording(audioURL: selectedURL, name: selectedURL.lastPathComponent)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let trimmingVC = storyboard.instantiateViewController(withIdentifier: "TrimmingVC") as? TrimmingVC {
                trimmingVC.audioURL = selectedURL
                trimmingVC.delegate = self
                trimmingVC.modalPresentationStyle = .fullScreen
                present(trimmingVC, animated: true)
            }
        }
    }
    
    private func getRandomImageURL() -> String {
        let randomIndex = Int.random(in: 0..<defaultImageURLs.count)
        return defaultImageURLs[randomIndex]
    }
}

@available(iOS 15.0, *)
extension AudioPrankVC: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
            self.timer?.invalidate()
        }
    }
}

@available(iOS 15.0, *)
extension AudioPrankVC: SaveRecordingDelegate {
    func didSaveRecording(audioURL: URL, name: String) {
        let randomImageURL = getRandomImageURL()
        self.customAudios.insert((url: audioURL, imageURL: randomImageURL), at: 0)
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
            
            let indexPath = IndexPath(item: 0, section: 0)
            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                if let cell = self?.audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell {
                    cell.playAudio()
                }
            }
        }
    }
}
