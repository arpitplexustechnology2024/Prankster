//
//  VideoCategoryAllVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 18/10/24.
//

import UIKit
import Alamofire

@available(iOS 15.0, *)
class VideoCategoryAllVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var videoCharacterAllCollectionView: UICollectionView!
    @IBOutlet weak var videoCharacterSliderCollectionView: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var searchbarBlurView: UIVisualEffectView!
    
    var isLoading = true
    var categoryId: Int = 0
    private let typeId: Int = 2
    private var isLoadingMore = false
    private var isSearchActive = false
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private var viewModel = CategoryAllViewModel()
    private var filteredVideos: [CategoryAllData] = []
    private var currentDataSource: [CategoryAllData] {
        return isSearchActive ? filteredVideos : viewModel.audioData
    }
    private var selectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupSearchBar()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupCollectionView()
        self.hideKeyboardTappedAround()
        self.checkInternetAndFetchData()
        self.filteredVideos = viewModel.audioData
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePremiumContentUnlocked),
            name: NSNotification.Name("PremiumContentUnlocked"),
            object: nil
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if !self.currentDataSource.isEmpty {
                let indexPath = IndexPath(item: 0, section: 0)
                self.videoCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedIndex = 0
                
                if let cell = self.videoCharacterAllCollectionView.cellForItem(at: indexPath) as? VideoCharacterAllCollectionViewCell {
                    cell.playVideo()
                    VideoPlaybackManager.shared.currentlyPlayingCell = cell
                    VideoPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
                }
            }
        }
    }
    
    private func playVisibleCell() {
        guard !currentDataSource.isEmpty else { return }
        
        let visibleRect = CGRect(origin: videoCharacterAllCollectionView.contentOffset, size: videoCharacterAllCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let visibleIndexPath = videoCharacterAllCollectionView.indexPathForItem(at: visiblePoint),
           let cell = videoCharacterAllCollectionView.cellForItem(at: visibleIndexPath) as? VideoCharacterAllCollectionViewCell {
            selectedIndex = visibleIndexPath.item
            VideoPlaybackManager.shared.stopCurrentPlayback()
            cell.playVideo()
            VideoPlaybackManager.shared.currentlyPlayingCell = cell
            VideoPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
            videoCharacterSliderCollectionView.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            let currentIndex = self.selectedIndex
            
            self.videoCharacterAllCollectionView.reloadData()
            self.videoCharacterSliderCollectionView.reloadData()
            
            let indexPath = IndexPath(item: currentIndex, section: 0)
            self.videoCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            self.videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
            
            self.selectedIndex = currentIndex
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingVideo()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVisibleCell()
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
    
    private func setupSearchBar() {
        searchbar.delegate = self
        searchbar.placeholder = "Search video or artist name"
        searchbar.backgroundImage = UIImage()
        searchbar.layer.cornerRadius = 10
        searchbar.clipsToBounds = true
        searchbarBlurView.layer.cornerRadius = 10
        searchbarBlurView.clipsToBounds = true
        searchbarBlurView.layer.masksToBounds = true
        
        if let textField = searchbar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search video or artist name",
                attributes: [.foregroundColor: UIColor.white]
            )
        }
        
        if let textField = searchbar.value(forKey: "searchField") as? UITextField,
           let leftIconView = textField.leftView as? UIImageView {
            leftIconView.tintColor = .white
            leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
        }
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllVideos()
            self.noInternetView?.isHidden = true
            self.hideNoDataView()
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    private func setupCollectionView() {
        self.videoCharacterAllCollectionView.delegate = self
        self.videoCharacterAllCollectionView.dataSource = self
        self.videoCharacterAllCollectionView.isPagingEnabled = true
        self.videoCharacterSliderCollectionView.delegate = self
        self.videoCharacterSliderCollectionView.dataSource = self
        self.videoCharacterAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.videoCharacterSliderCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.videoCharacterSliderCollectionView.register(
            LoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: LoadingFooterView.reuseIdentifier
        )
        if let layout = videoCharacterSliderCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = CGSize(width: 16, height: videoCharacterSliderCollectionView.frame.height)
        }
    }
    
    // MARK: - fetchAllVideos
    func fetchAllVideos() {
//        guard !isLoadingMore else { return }
//        isLoadingMore = true
//        viewModel.fetchAudioData(categoryId: categoryId, typeId: typeId) { [weak self] success in
//            guard let self = self else { return }
//            DispatchQueue.main.async {
//                self.isLoadingMore = false
//                if success {
//                    if self.viewModel.audioData.isEmpty {
//                        self.hideSkeletonLoader()
//                        self.showNoDataView()
//                    } else {
//                        self.hideSkeletonLoader()
//                        self.hideNoDataView()
//                        self.videoCharacterAllCollectionView.reloadData()
//                        self.videoCharacterSliderCollectionView.reloadData()
//                        
//                        if !self.currentDataSource.isEmpty {
//                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
//                            self.videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                            
//                            if !self.isLoadingMore {
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//                                    self.playVisibleCell()
//                                }
//                            }
//                        }
//                    }
//                } else if let errorMessage = self.viewModel.errorMessage {
//                    self.hideSkeletonLoader()
//                    self.showNoDataView()
//                    print("Error fetching all cover pages: \(errorMessage)")
//                }
//            }
//        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        self.view.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        self.view.addSubview(noInternetView)
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
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
        self.videoCharacterAllCollectionView.reloadData()
        self.videoCharacterSliderCollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        self.videoCharacterAllCollectionView.reloadData()
        self.videoCharacterSliderCollectionView.reloadData()
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
            
            self.videoCharacterAllCollectionView.reloadData()
            self.videoCharacterSliderCollectionView.reloadData()
            
            if self.filteredVideos.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
            } else {
                self.hideNoDataView()
                
                if !self.filteredVideos.isEmpty {
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    if self.videoCharacterAllCollectionView.numberOfItems(inSection: 0) > 0 {
                        self.videoCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                        self.videoCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                    
                    if self.videoCharacterSliderCollectionView.numberOfItems(inSection: 0) > 0 {
                        self.videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoCharacterSliderCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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
extension VideoCategoryAllVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoading {
            return 8
        }
        return currentDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == videoCharacterAllCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCharacterAllCollectionViewCell", for: indexPath) as! VideoCharacterAllCollectionViewCell
                
                guard indexPath.row < currentDataSource.count else {
                    return cell
                }
                let coverPageData = currentDataSource[indexPath.row]
                cell.delegate = self
                cell.configure(with: coverPageData, at: indexPath)
                return cell
            }
        } else if collectionView == videoCharacterSliderCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCharacterSliderCollectionViewCell", for: indexPath) as! VideoCharacterSliderCollectionViewCell
                guard indexPath.row < currentDataSource.count else {
                    return cell
                }
                
                let coverPageData = currentDataSource[indexPath.row]
                cell.configure(with: coverPageData)
                
                cell.isSelected = indexPath.item == selectedIndex
                
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < currentDataSource.count else { return }
        
        selectedIndex = indexPath.item
        
        if collectionView == videoCharacterAllCollectionView {
            videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            videoCharacterSliderCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else if collectionView == videoCharacterSliderCollectionView {
            videoCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            videoCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 90
        let height: CGFloat = 90
        
        if collectionView == videoCharacterAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == videoCharacterSliderCollectionView {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = viewModel.audioData.count - 1
        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages && isConnectedToInternet() {
            fetchAllVideos()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == videoCharacterAllCollectionView {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
            perform(#selector(scrollingEnded), with: nil, afterDelay: 0.1)
            let pageWidth = scrollView.bounds.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
            
            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
            
            if currentPage != selectedIndex {
                selectedIndex = currentPage
                
                let indexPath = IndexPath(item: currentPage, section: 0)
                DispatchQueue.main.async {
                    if currentPage < self.currentDataSource.count {
                        
                        self.videoCharacterSliderCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                        self.videoCharacterSliderCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    }
                }
            }
        }
    }
        
        @objc private func scrollingEnded() {
            playVisibleCell()
        }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            if let playingIndexPath = VideoPlaybackManager.shared.currentlyPlayingIndexPath,
               let cell = videoCharacterAllCollectionView.cellForItem(at: playingIndexPath) as? VideoCharacterAllCollectionViewCell {
                cell.playVideo()
            }
        }
    }
    
    // MARK: - VideoCharacterAllCollectionViewCellDelegate
@available(iOS 15.0, *)
extension VideoCategoryAllVC: VideoCharacterAllCollectionViewCellDelegate {
        func didTapVideoPlayback(at indexPath: IndexPath) {
            guard let cell = videoCharacterAllCollectionView.cellForItem(at: indexPath) as? VideoCharacterAllCollectionViewCell else {
                return
            }
            
            if VideoPlaybackManager.shared.currentlyPlayingIndexPath == indexPath {
                cell.stopVideo()
                VideoPlaybackManager.shared.currentlyPlayingCell = nil
                VideoPlaybackManager.shared.currentlyPlayingIndexPath = nil
            } else {
                VideoPlaybackManager.shared.stopCurrentPlayback()
                cell.playVideo()
            }
        }
        
        func didTapDoneButton(for categoryAllData: CategoryAllData) {
            VideoPlaybackManager.shared.stopCurrentPlayback()
            
            if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
                presentPremiumViewController(for: categoryAllData)
            } else {
                if isConnectedToInternet() {
                    if let navigationController = self.navigationController {
                        if let videoVC = navigationController.viewControllers.first(where: { $0 is VideoVC }) as? VideoVC {
                            videoVC.updateSelectedVideo(with: categoryAllData)
                            navigationController.popToViewController(videoVC, animated: true)
                        }
                    }
                } else {
                    let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
            }
        }
        
        private func presentPremiumViewController(for categoryAllData: CategoryAllData) {
            let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumPopupVC") as! PremiumPopupVC
            premiumVC.setItemIDToUnlock(categoryAllData.itemID)
            premiumVC.modalTransitionStyle = .crossDissolve
            premiumVC.modalPresentationStyle = .overCurrentContext
            present(premiumVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - UISearchBarDelegate
@available(iOS 15.0, *)
extension VideoCategoryAllVC: UISearchBarDelegate {
        func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
            filterContent(with: searchText)
        }
        
        func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
            searchBar.resignFirstResponder()
        }
        
        func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
            searchBar.text = ""
            searchBar.resignFirstResponder()
            filterContent(with: "")
        }
    }
