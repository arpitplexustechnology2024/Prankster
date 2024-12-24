//
//  AudioCategoryAllVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 17/10/24.
//

import UIKit
import Alamofire

class AudioCategoryAllVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var audioCharacterAllCollectionView: UICollectionView!
    @IBOutlet weak var audioCharacterSlideCollectionview: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var searchbarBlurView: UIVisualEffectView!
    
    var isLoading = true
    var categoryId: Int = 0
    private let typeId: Int = 1
    private var isLoadingMore = false
    private var isSearchActive = false
    private var noDataView: NoDataView!
    private var viewModel = CategoryAllViewModel()
    private var noInternetView: NoInternetView!
    private var filteredAudios: [CategoryAllData] = []
    private var currentDataSource: [CategoryAllData] {
        return isSearchActive ? filteredAudios : viewModel.audioData
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
        self.filteredAudios = viewModel.audioData
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
                self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedIndex = 0
                
                if let cell = self.audioCharacterAllCollectionView.cellForItem(at: indexPath) as? AudioCharacterAllCollectionViewCell {
                    cell.playAudio()
                    AudioPlaybackManager.shared.currentlyPlayingCell = cell
                    AudioPlaybackManager.shared.currentlyPlayingIndexPath = indexPath
                }
            }
        }
    }
    
    private func playVisibleCell() {
        guard !currentDataSource.isEmpty else { return }
        
        let visibleRect = CGRect(origin: audioCharacterAllCollectionView.contentOffset, size: audioCharacterAllCollectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        
        if let visibleIndexPath = audioCharacterAllCollectionView.indexPathForItem(at: visiblePoint),
           let cell = audioCharacterAllCollectionView.cellForItem(at: visibleIndexPath) as? AudioCharacterAllCollectionViewCell {
            selectedIndex = visibleIndexPath.item
            AudioPlaybackManager.shared.stopCurrentPlayback()
            cell.playAudio()
            AudioPlaybackManager.shared.currentlyPlayingCell = cell
            AudioPlaybackManager.shared.currentlyPlayingIndexPath = visibleIndexPath
            audioCharacterSlideCollectionview.selectItem(at: visibleIndexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPlayingAudio()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playVisibleCell()
    }
    
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
    
    private func setupSearchBar() {
        searchbar.delegate = self
        searchbar.placeholder = "Search audio or artist name"
        searchbar.backgroundImage = UIImage()
        searchbar.layer.cornerRadius = searchbar.frame.height / 2
        searchbar.clipsToBounds = true
        searchbarBlurView.layer.cornerRadius = searchbarBlurView.frame.height / 2
        searchbarBlurView.clipsToBounds = true
        searchbarBlurView.layer.masksToBounds = true
        
        if let textField = searchbar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
        }
    }
    
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchAllAudios()
            self.noInternetView?.isHidden = true
            self.hideNoDataView()
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
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
    }
    
    // MARK: - fetchAllAudios
    func fetchAllAudios() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        viewModel.fetchAudioData(categoryId: categoryId, typeId: typeId) { [weak self] success in
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
                        self.audioCharacterAllCollectionView.reloadData()
                        self.audioCharacterSlideCollectionview.reloadData()
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                            
                            if !self.isLoadingMore {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.playVisibleCell()
                                }
                            }
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
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
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
            self.audioCharacterAllCollectionView.reloadData()
            self.audioCharacterSlideCollectionview.reloadData()
            
            if self.filteredAudios.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
            } else {
                self.hideNoDataView()
                
                if !self.filteredAudios.isEmpty {
                    self.selectedIndex = 0
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    self.audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    self.audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    
                    self.audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    
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
extension AudioCategoryAllVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoading {
            return 8
        }
        return currentDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == audioCharacterAllCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterAllCollectionViewCell", for: indexPath) as! AudioCharacterAllCollectionViewCell
                guard indexPath.row < currentDataSource.count else {
                    return cell
                }
                
                let audioData = currentDataSource[indexPath.row]
                cell.delegate = self
                cell.configure(with: audioData, at: indexPath)
                return cell
            }
        } else if collectionView == audioCharacterSlideCollectionview {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterSliderCollectionViewCell", for: indexPath) as! AudioCharacterSliderCollectionViewCell
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
        selectedIndex = indexPath.item
        
        if collectionView == audioCharacterAllCollectionView {
            audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else if collectionView == audioCharacterSlideCollectionview {
            audioCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            audioCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 80
        let height: CGFloat = 104
        
        if collectionView == audioCharacterAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == audioCharacterSlideCollectionview {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let lastItem = viewModel.audioData.count - 1
        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
            self.fetchAllAudios()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                for: indexPath
            ) as! LoadingFooterView
            if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.audioData.isEmpty {
                footer.startAnimating()
            } else {
                footer.stopAnimating()
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == audioCharacterAllCollectionView {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(scrollingEnded), object: nil)
            perform(#selector(scrollingEnded), with: nil, afterDelay: 0.1)
            let pageWidth = scrollView.bounds.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
            
            if currentPage != selectedIndex {
                selectedIndex = currentPage
                
                let indexPath = IndexPath(item: currentPage, section: 0)
                audioCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                audioCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
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
extension AudioCategoryAllVC: AudioAllCollectionViewCellDelegate {
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
    
    func didTapDoneButton(for categoryAllData: CategoryAllData) {
        AudioPlaybackManager.shared.stopCurrentPlayback()
        if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
            presentPremiumViewController(for: categoryAllData)
        } else {
            if let navigationController = self.navigationController {
                if let audioVC = navigationController.viewControllers.first(where: { $0 is AudioVC }) as? AudioVC {
                    audioVC.playSelectedAudio(categoryAllData)
                    navigationController.popToViewController(audioVC, animated: true)
                }
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
extension AudioCategoryAllVC: UISearchBarDelegate {
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
