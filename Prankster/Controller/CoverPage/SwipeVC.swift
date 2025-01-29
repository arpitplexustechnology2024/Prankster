//
//  SwipeVC.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 20/01/25.
//

import UIKit
//
//class SwipeVC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    
//    private var collectionView1: UICollectionView!
//    private var collectionView2: UICollectionView!
//    private var selectedIndex: Int = 0
//    private var nativeAdLoaders: [Int: NativeMediumAdUtility] = [:]
//    private let adInterval = 4
//    private let regularCellCount = 50
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        setupCollectionView1()
//        setupCollectionView2()
//        // Add this new line to preload ads
//        preloadAllAds()
//        DispatchQueue.main.async {
//            self.scrollToIndex(self.selectedIndex, animated: false)
//        }
//    }
//    
//    private func setupCollectionView1() {
//        let layout1 = UICollectionViewFlowLayout()
//        layout1.scrollDirection = .horizontal
//        layout1.minimumLineSpacing = 0
//        layout1.minimumInteritemSpacing = 0
//        
//        collectionView1 = UICollectionView(frame: .zero, collectionViewLayout: layout1)
//        collectionView1.dataSource = self
//        collectionView1.delegate = self
//        collectionView1.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell1")
//        collectionView1.register(NativeAdsCell.self, forCellWithReuseIdentifier: "adCell")
//        collectionView1.backgroundColor = .white
//        collectionView1.isPagingEnabled = true
//        collectionView1.showsHorizontalScrollIndicator = false
//        
//        view.addSubview(collectionView1)
//        collectionView1.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            collectionView1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
//            collectionView1.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
//            collectionView1.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -116)
//        ])
//    }
//    
//    private func setupCollectionView2() {
//        let layout2 = UICollectionViewFlowLayout()
//        layout2.scrollDirection = .horizontal
//        layout2.minimumLineSpacing = 8
//        layout2.minimumInteritemSpacing = 8
//        
//        collectionView2 = UICollectionView(frame: .zero, collectionViewLayout: layout2)
//        collectionView2.dataSource = self
//        collectionView2.delegate = self
//        collectionView2.register(CollectionViewCell.self, forCellWithReuseIdentifier: "cell2")
//        collectionView2.backgroundColor = .white
//        collectionView2.showsHorizontalScrollIndicator = false
//        
//        view.addSubview(collectionView2)
//        collectionView2.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            collectionView2.heightAnchor.constraint(equalToConstant: 100),
//            collectionView2.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
//            collectionView2.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
//            collectionView2.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
//        ])
//    }
//    
//    // MARK: - UICollectionViewDataSource
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == collectionView1 {
//            let adCount = regularCellCount / adInterval
//            return regularCellCount + adCount
//        } else {
//            return regularCellCount
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == collectionView1 {
//            if shouldShowAdAt(index: indexPath.item) {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "adCell", for: indexPath) as! NativeAdsCell
//                if let adLoader = nativeAdLoaders[indexPath.item] {
//                    cell.configure(with: adLoader.nativeAdPlaceholder)
//                }
//                return cell
//            } else {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell1", for: indexPath) as! CollectionViewCell
//                let actualIndex = getActualIndex(for: indexPath.item)
//                cell.configureCell(index: actualIndex, isSelected: actualIndex == selectedIndex)
//                return cell
//            }
//        } else {
//            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell2", for: indexPath) as! CollectionViewCell
//            cell.configureCell(index: indexPath.item, isSelected: indexPath.item == selectedIndex)
//            return cell
//        }
//    }
//    
//    private func shouldShowAdAt(index: Int) -> Bool {
//        let adjustedIndex = index + 1
//        return adjustedIndex % (adInterval + 1) == 0
//    }
//    
//    private func getActualIndex(for visibleIndex: Int) -> Int {
//        let adCount = visibleIndex / (adInterval + 1)
//        return visibleIndex - adCount
//    }
//    
//    private func preloadAllAds() {
//        let dispatchGroup = DispatchGroup()
//        
//        let totalAds = (regularCellCount + 4) / 5
//        
//        for i in 0..<totalAds {
//            let adIndex = (i + 1) * 5 - 1
//            dispatchGroup.enter()
//            
//            let adPlaceholder = UIView()
//            adPlaceholder.backgroundColor = .lightGray
//            
//            let adLoader = NativeMediumAdUtility(adUnitID: "ca-app-pub-3940256099942544/3986624511",rootViewController: self,nativeAdPlaceholder: adPlaceholder) { [weak self] success  in
//                if success {
//                    print("Ad loaded successfully for index: \(adIndex)")
//                } else {
//                    print("Failed to load ad for index: \(adIndex)")
//                }
//                dispatchGroup.leave()
//            }
//            nativeAdLoaders[adIndex] = adLoader
//        }
//        dispatchGroup.notify(queue: .main) {
//            print("All ads have been loaded")
//            self.collectionView1.reloadData()
//            self.collectionView2.reloadData()
//        }
//    }
//    
//    // MARK: - UICollectionViewDelegate
//    // MARK: - UICollectionViewDelegate
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        guard scrollView == collectionView1 else { return }
//        let visibleRect = CGRect(origin: collectionView1.contentOffset, size: collectionView1.bounds.size)
//        guard let visibleIndexPath = collectionView1.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) else { return }
//        
//        if shouldShowAdAt(index: visibleIndexPath.item) {
//            
//        } else {
//            selectedIndex = getActualIndex(for: visibleIndexPath.item)
//        }
//        reloadAndScrollToSelectedIndex(from: collectionView1)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if collectionView == collectionView1 {
//            if shouldShowAdAt(index: indexPath.item) {
//                
//            } else {
//                selectedIndex = getActualIndex(for: indexPath.item)
//            }
//        } else if collectionView == collectionView2 {
//            selectedIndex = indexPath.item
//        }
//        reloadAndScrollToSelectedIndex(from: collectionView)
//    }
//    
//    // MARK: - Helpers
//    private func reloadAndScrollToSelectedIndex(from collectionView: UICollectionView) {
//        collectionView1.reloadData()
//        collectionView2.reloadData()
//        
//        let indexPathToScroll = IndexPath(item: selectedIndex, section: 0)
//        if collectionView == collectionView1 {
//            collectionView2.scrollToItem(at: indexPathToScroll, at: .centeredHorizontally, animated: true)
//        } else if collectionView == collectionView2 {
//            let visibleIndexPath = getVisibleIndexForActualIndex(selectedIndex)
//            collectionView1.scrollToItem(at: visibleIndexPath, at: .centeredHorizontally, animated: true)
//        }
//    }
//    
//    private func getVisibleIndexForActualIndex(_ actualIndex: Int) -> IndexPath {
//        var visibleIndex = actualIndex
//        let adCountBefore = actualIndex / adInterval
//        visibleIndex += adCountBefore
//        return IndexPath(item: visibleIndex, section: 0)
//    }
//    
//    private func scrollToIndex(_ index: Int, animated: Bool) {
//        let indexPath = IndexPath(item: index, section: 0)
//        collectionView1.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
//        collectionView2.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
//    }
//    
//    // MARK: - UICollectionViewDelegateFlowLayout
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        if collectionView == collectionView1 {
//            return collectionView.frame.size
//        } else {
//            let cellSize = collectionView.frame.height
//            return CGSize(width: cellSize, height: cellSize)
//        }
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard scrollView == collectionView1 else { return }
//        
//        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//        
//        for cell in collectionView1.visibleCells {
//            let cellCenterX = cell.center.x
//            let distance = centerX - cellCenterX
//            let maxDistance = scrollView.frame.width
//            
//            // Reduced rotation to just 8 degrees (pi/24)
//            let angle = (distance / maxDistance) * (.pi / 24)    //12
//            
//            // Simple rotation transform
//            let transform = CGAffineTransform(rotationAngle: angle)
//            
//            cell.transform = transform
//        }
//    }
//}


//func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    guard scrollView == collectionView1 else { return }
//    
//    let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//    
//    for cell in collectionView1.visibleCells {
//        let cellCenterX = cell.center.x
//        let distance = centerX - cellCenterX
//        let maxDistance = scrollView.frame.width
//        
//        let normalizedDistance = distance / maxDistance
//        
//        // Create helix spiral movement
//        let verticalOffset = sin(normalizedDistance * 2 * .pi) * 40
//        let horizontalOffset = cos(normalizedDistance * 2 * .pi) * 20
//        let rotationAngle = normalizedDistance * .pi
//        
//        let transform = CGAffineTransform(translationX: horizontalOffset, y: verticalOffset)
//            .rotated(by: rotationAngle)
//        
//        cell.transform = transform
//    }
//}




//func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    guard scrollView == collectionView1 else { return }
//    
//    let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//    
//    for cell in collectionView1.visibleCells {
//        let cellCenterX = cell.center.x
//        let distance = centerX - cellCenterX
//        let maxDistance = scrollView.frame.width
//        
//        // Calculate rotation angle (Tinder style)
//        let rotationAngle = -(distance / maxDistance) * (.pi / 8)  // Maximum 22.5 degrees rotation
//        
//        // Calculate horizontal shift
//        let horizontalShift = -(distance / maxDistance) * 20
//        
//        // Combine transforms: rotation + translation
//        let transform = CGAffineTransform(rotationAngle: rotationAngle)
//            .translatedBy(x: horizontalShift, y: 0)
//        
//        cell.transform = transform
//    }
//}


//func scrollViewDidScroll(_ scrollView: UIScrollView) {
//    guard scrollView == collectionView1 else { return }
//    
//    let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//    
//    for cell in collectionView1.visibleCells {
//        let cellCenterX = cell.center.x
//        let distance = centerX - cellCenterX
//        let maxDistance = scrollView.frame.width
//        
//        // Calculate falling domino effect
//        let normalizedDistance = distance / maxDistance
//        let rotationAngle = (normalizedDistance) * (.pi / 3)
//        
//        var transform3D = CATransform3DIdentity
//        transform3D.m34 = -1.0 / 500.0
//        
//        // Rotate around Y and X axis for domino effect
//        transform3D = CATransform3DRotate(transform3D, rotationAngle, 1, 0, 0)
//        
//        cell.layer.transform = transform3D
//    }
//}


//import UIKit
//
//// MARK: - NativeAds Cell
//class NativeAdsCell: UICollectionViewCell {
//    private var adView: UIView?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupCell()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupCell()
//    }
//    
//    private func setupCell() {
//        backgroundColor = .white
//        layer.cornerRadius = 8
//        clipsToBounds = true
//    }
//    
//    func configure(with adView: UIView?) {
//        self.adView?.removeFromSuperview()
//        
//        guard let adView = adView else { return }
//        
//        self.adView = adView
//        contentView.addSubview(adView)
//        adView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            adView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            adView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
//            adView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
//            adView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        ])
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        adView?.removeFromSuperview()
//        adView = nil
//    }
//}

// MARK: - Custom Cell
class CollectionViewCell: UICollectionViewCell {
    private let label = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .white
        layer.borderColor = UIColor.lightGray.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }
    
    func configureCell(index: Int, isSelected: Bool) {
        label.text = "Index \(index + 1)"
        layer.borderColor = isSelected ? UIColor.red.cgColor : UIColor.lightGray.cgColor
        layer.borderWidth = isSelected ? 2 : 1
    }
}


//import UIKit
//import Alamofire
//import AVFoundation
//import Photos
//
//class EmojiCoverPageVC: UIViewController {
//    
//    @IBOutlet weak var chipSelector: ChipSelectorView!
//    @IBOutlet weak var emojiCoverAllCollectionView: UICollectionView!
//    @IBOutlet weak var emojiCoverSlideCollectionview: UICollectionView!
//    @IBOutlet weak var addcoverButton: UIButton!
//    @IBOutlet weak var addcoverView: UIView!
//    
//    var searchBar: UISearchBar!
//    
//    var selectedCustomImage: UIImage?
//    var selectedCoverImageURL: String?
//    var selectedCoverImageFile: Data?
//    var selectedCoverImageName: String?
//    var viewType: CoverViewType = .audio
//    private var selectedCoverIndex: Int?
//    var customCoverImages: [UIImage] = []
//    var selectedCustomCoverIndex: IndexPath?
//    private var noDataView: NoDataView!
//    private var noInternetView: NoInternetView!
//    private let viewModel = EmojiViewModel()
//    private var isSearchActive = false
//    private var filteredEmojiCoverPages: [CoverPageData] = []
//    private var currentDataSource: [CoverPageData] {
//        return isSearchActive ? filteredEmojiCoverPages : viewModel.emojiCoverPages
//    }
//    var isLoading = true
//    private let categoryId: Int = 4
//    private var isLoadingMore = false
//    private var selectedIndex: Int = 0
//    
//    private var nativeAdLoaders: [Int: NativeMediumAdUtility] = [:]
//    private let adInterval = 4
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupUI()
//        self.preloadAllAds()
//        self.loadSavedImages()
//        self.setupNoDataView()
//        self.setupSwipeGesture()
//        self.showSkeletonLoader()
//        self.setupNoInternetView()
//        self.setupCollectionView()
//        self.hideKeyboardTappedAround()
//        self.filteredEmojiCoverPages = viewModel.emojiCoverPages
//        
//        DispatchQueue.main.async {
//            self.scrollToIndex(self.selectedIndex, animated: false)
//        }
//    }
//    
//    func setupUI() {
//        self.addcoverView.layer.cornerRadius = 10
//        
//        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
//        backButton.tintColor = .white
//        
//        let titleLabel = UILabel()
//        titleLabel.text = "Cover page"
//        titleLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
//        titleLabel.textColor = .white
//        navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: titleLabel)]
//        
//        searchBar = UISearchBar()
//        searchBar.delegate = self
//        searchBar.placeholder = "Search Album Title"
//        searchBar.barStyle = .black
//        
//        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
//            textField.textColor = .white
//            textField.attributedPlaceholder = NSAttributedString(
//                string: "Search cover image",
//                attributes: [.foregroundColor: UIColor.lightGray]
//            )
//        }
//        
//        if let textField = searchBar.value(forKey: "searchField") as? UITextField,
//           let leftIconView = textField.leftView as? UIImageView {
//            leftIconView.tintColor = .lightGray
//            leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
//        }
//        
//        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
//            textField.enablesReturnKeyAutomatically = false
//        }
//        
//        chipSelector.onSelectionChanged = { [weak self] selectedType in
//            guard let self = self else { return }
//            
//            if selectedType == "Add cover image 📸" {
//                self.addcoverView.isHidden = false
//                searchBar.resignFirstResponder()
//                searchBar.text = ""
//                navigationItem.titleView = nil
//                
//                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
//                backButton.tintColor = .white
//                
//                let titleLabel = UILabel()
//                titleLabel.text = "Cover page"
//                titleLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
//                titleLabel.textColor = .white
//                navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: titleLabel)]
//                
//                emojiCoverAllCollectionView.reloadData()
//                emojiCoverSlideCollectionview.reloadData()
//                
//            } else {
//                self.addcoverView.isHidden = true
//                
//                let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
//                backButton.tintColor = .white
//                navigationItem.leftBarButtonItems = [backButton]
//                navigationItem.titleView = searchBar
//                
//                emojiCoverAllCollectionView.reloadData()
//                emojiCoverSlideCollectionview.reloadData()
//                
//                self.checkInternetAndFetchData()
//            }
//        }
//    }
//    
//    @objc func backButtonTapped() {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    func checkInternetAndFetchData() {
//        if isConnectedToInternet() {
//            fetchAllCoverPages()
//            self.noInternetView?.isHidden = true
//            self.hideNoDataView()
//        } else {
//            self.showNoInternetView()
//            self.hideSkeletonLoader()
//        }
//    }
//    
//    private func setupCollectionView() {
//        self.emojiCoverSlideCollectionview.delegate = self
//        self.emojiCoverSlideCollectionview.dataSource = self
//        self.emojiCoverAllCollectionView.delegate = self
//        self.emojiCoverAllCollectionView.dataSource = self
//        self.emojiCoverAllCollectionView.isPagingEnabled = true
//        
//        self.emojiCoverAllCollectionView.register(NativeAdsCell.self, forCellWithReuseIdentifier: "adCell")
//        self.emojiCoverAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.emojiCoverSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.emojiCoverSlideCollectionview.register(
//            LoadingFooterView.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
//            withReuseIdentifier: LoadingFooterView.reuseIdentifier
//        )
//        if let layout = emojiCoverSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
//            layout.footerReferenceSize = CGSize(width: 16, height: emojiCoverSlideCollectionview.frame.height)
//        }
//    }
//    
//    func fetchAllCoverPages() {
//        guard !isLoadingMore else { return }
//        isLoadingMore = true
//        viewModel.fetchEmojiCoverPages { [weak self] success in
//            guard let self = self else { return }
//            DispatchQueue.main.async {
//                self.isLoadingMore = false
//                if success {
//                    if self.viewModel.emojiCoverPages.isEmpty {
//                        self.hideSkeletonLoader()
//                        self.showNoDataView()
//                    } else {
//                        self.hideSkeletonLoader()
//                        self.hideNoDataView()
//                        self.emojiCoverAllCollectionView.reloadData()
//                        self.emojiCoverSlideCollectionview.reloadData()
//                        
//                        if !self.currentDataSource.isEmpty {
//                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
//                            self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                        }
//                    }
//                } else if let errorMessage = self.viewModel.errorMessage {
//                    self.hideSkeletonLoader()
//                    self.showNoDataView()
//                    print("Error fetching all cover pages: \(errorMessage)")
//                }
//            }
//        }
//    }
//    
//    private func setupNoDataView() {
//        noDataView = NoDataView()
//        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//        noDataView.isHidden = true
//        self.view.addSubview(noDataView)
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
//        self.view.addSubview(noInternetView)
//        noInternetView.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            noInternetView.topAnchor.constraint(equalTo: chipSelector.bottomAnchor),
//            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
//        ])
//    }
//    
//    @objc func retryButtonTapped() {
//        if isConnectedToInternet() {
//            noInternetView.isHidden = true
//            hideNoDataView()
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
//    private func showNoDataView() {
//        noDataView?.isHidden = false
//    }
//    
//    private func hideNoDataView() {
//        noDataView?.isHidden = true
//    }
//    
//    func showSkeletonLoader() {
//        isLoading = true
//        self.emojiCoverAllCollectionView.reloadData()
//        self.emojiCoverSlideCollectionview.reloadData()
//    }
//    
//    func hideSkeletonLoader() {
//        isLoading = false
//        self.emojiCoverAllCollectionView.reloadData()
//        self.emojiCoverSlideCollectionview.reloadData()
//    }
//    
//    private func isConnectedToInternet() -> Bool {
//        let networkManager = NetworkReachabilityManager()
//        return networkManager?.isReachable ?? false
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
//            filteredEmojiCoverPages = viewModel.emojiCoverPages
//        } else {
//            filteredEmojiCoverPages = viewModel.emojiCoverPages.filter { coverPage in
//                let nameMatch = coverPage.coverName.lowercased().contains(searchText.lowercased())
//                let tagMatch = coverPage.tagName.contains { tag in
//                    tag.lowercased().contains(searchText.lowercased())
//                }
//                return nameMatch || tagMatch
//            }
//        }
//        
//        DispatchQueue.main.async {
//            self.selectedIndex = 0
//            
//            self.emojiCoverAllCollectionView.reloadData()
//            self.emojiCoverSlideCollectionview.reloadData()
//            
//            if self.filteredEmojiCoverPages.isEmpty && !searchText.isEmpty {
//                self.showNoDataView()
//            } else {
//                self.hideNoDataView()
//                
//                if !self.filteredEmojiCoverPages.isEmpty {
//                    let indexPath = IndexPath(item: 0, section: 0)
//                    
//                    if self.emojiCoverAllCollectionView.numberOfItems(inSection: 0) > 0 {
//                        self.emojiCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                        self.emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                    
//                    if self.emojiCoverSlideCollectionview.numberOfItems(inSection: 0) > 0 {
//                        self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                }
//            }
//        }
//    }
//    
//    @IBAction func btnAddCoverImageTapped(_ sender: UIButton) {
//        showImageOptionsActionSheet(sourceView: sender)
//    }
//}
//
//extension EmojiCoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if collectionView == emojiCoverAllCollectionView {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            if selectedChipTitle == "Add cover image 📸" {
//                let adCount = (customCoverImages.isEmpty ? 1 : customCoverImages.count) / adInterval
//                return (customCoverImages.isEmpty ? 1 : customCoverImages.count) + adCount
//               // return (customCoverImages.isEmpty ? 1 : customCoverImages.count)
//            } else {
//                let adCount = currentDataSource.count / adInterval
//                return currentDataSource.count + adCount
//               // return isLoading ? 8 : currentDataSource.count
//            }
//        } else {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            if selectedChipTitle == "Add cover image 📸" {
//                return (customCoverImages.isEmpty ? 4 : customCoverImages.count)
//            } else {
//                return isLoading ? 8 : currentDataSource.count
//            }
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == emojiCoverAllCollectionView {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            
//            if selectedChipTitle == "Add cover image 📸" {
//                if shouldShowAdAt(index: indexPath.item) {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "adCell", for: indexPath) as! NativeAdsCell
//                    if let adLoader = nativeAdLoaders[indexPath.item] {
//                        cell.configure(with: adLoader.nativeAdPlaceholder)
//                    }
//                    return cell
//                } else {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverAllCollectionViewCell", for: indexPath) as! EmojiCoverAllCollectionViewCell
//                    cell.imageName.text = customCoverImages.isEmpty ? "Funny name" : "Custom image \(indexPath.item + 1)"
//                    cell.imageView.image = customCoverImages.isEmpty ? UIImage(named: "imageplacholder") : customCoverImages[indexPath.item]
//                    cell.premiumButton.isHidden = true
//                    cell.premiumIconImageView.isHidden = true
//                    return cell
//                }
//            } else {
//                if shouldShowAdAt(index: indexPath.item) {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "adCell", for: indexPath) as! NativeAdsCell
//                    if let adLoader = nativeAdLoaders[indexPath.item] {
//                        cell.configure(with: adLoader.nativeAdPlaceholder)
//                    }
//                    return cell
//                } else {
//                    if isLoading {
//                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                        cell.isUserInteractionEnabled = false
//                        return cell
//                    } else {
//                        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverAllCollectionViewCell", for: indexPath) as! EmojiCoverAllCollectionViewCell
//                        
//                        guard indexPath.row < currentDataSource.count else {
//                            return cell
//                        }
//                        
//                        let coverPageData = currentDataSource[indexPath.row]
//                        cell.configure(with: coverPageData)
//                        
//                        return cell
//                    }
//                }
//            }
//        } else if collectionView == emojiCoverSlideCollectionview {
//            let selectedChipTitle = chipSelector.getSelectedChipTitle()
//            
//            if selectedChipTitle == "Add cover image 📸" {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverSliderCollectionViewCell", for: indexPath) as! EmojiCoverSliderCollectionViewCell
//                cell.imageView.image = customCoverImages.isEmpty ? UIImage(named: "imageplacholder") : customCoverImages[indexPath.item]
//                cell.premiumIconImageView.isHidden = true
//                return cell
//            } else {
//                if isLoading {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                    cell.isUserInteractionEnabled = false
//                    return cell
//                } else {
//                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCoverSliderCollectionViewCell", for: indexPath) as! EmojiCoverSliderCollectionViewCell
//                    
//                    guard indexPath.row < currentDataSource.count else {
//                        return cell
//                    }
//                    let coverPageData = currentDataSource[indexPath.row]
//                    cell.configure(with: coverPageData)
//                    
//                    return cell
//                }
//            }
//        }
//        return UICollectionViewCell()
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        if collectionView == emojiCoverSlideCollectionview {
//            selectedIndex = indexPath.item
//        } else {
//            if shouldShowAdAt(index: indexPath.item) {
//                
//            } else {
//                selectedIndex = getActualIndex(for: indexPath.item)
//            }
//        }
//        
//        reloadAndScrollToSelectedIndex(from: collectionView)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width: CGFloat = 90
//        let height: CGFloat = 90
//        
//        if collectionView == emojiCoverAllCollectionView {
//            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
//        } else if collectionView == emojiCoverSlideCollectionview {
//            return CGSize(width: width, height: height)
//        }
//        return CGSize(width: width, height: height)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let lastItem = viewModel.emojiCoverPages.count - 1
//        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
//            fetchAllCoverPages()
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
//        if kind == UICollectionView.elementKindSectionFooter {
//            let footer = collectionView.dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
//                for: indexPath
//            ) as! LoadingFooterView
//            if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.emojiCoverPages.isEmpty {
//                footer.startAnimating()
//            } else {
//                footer.stopAnimating()
//            }
//            
//            return footer
//        }
//        return UICollectionReusableView()
//    }
//    
//    private func shouldShowAdAt(index: Int) -> Bool {
//        let adjustedIndex = index + 1
//        return adjustedIndex % (adInterval + 1) == 0
//    }
//    
//    private func getActualIndex(for visibleIndex: Int) -> Int {
//        let adCount = visibleIndex / (adInterval + 1)
//        return visibleIndex - adCount
//    }
//    
//    private var regularCellCount: Int {
//        let selectedChipTitle = chipSelector.getSelectedChipTitle()
//        if selectedChipTitle == "Add cover image 📸" {
//            return customCoverImages.isEmpty ? 1 : customCoverImages.count
//        } else {
//            return currentDataSource.count
//        }
//    }
//
//    private func preloadAllAds() {
//        let dispatchGroup = DispatchGroup()
//        
//        let totalAds = (regularCellCount + 4) / 5
//        
//        for i in 0..<totalAds {
//            let adIndex = (i + 1) * 5 - 1
//            dispatchGroup.enter()
//            
//            let adPlaceholder = UIView()
//            adPlaceholder.backgroundColor = .lightGray
//            
//            let adLoader = NativeMediumAdUtility(adUnitID: "ca-app-pub-3940256099942544/3986624511",rootViewController: self,nativeAdPlaceholder: adPlaceholder) { [weak self] success in
//                if success {
//                    print("Ad loaded successfully for index: \(adIndex)")
//                } else {
//                    print("Failed to load ad for index: \(adIndex)")
//                }
//                dispatchGroup.leave()
//            }
//            nativeAdLoaders[adIndex] = adLoader
//        }
//        dispatchGroup.notify(queue: .main) {
//            print("All ads have been loaded")
//            self.emojiCoverAllCollectionView.reloadData()
//            self.emojiCoverSlideCollectionview.reloadData()
//        }
//    }
//    
//    // MARK: - UICollectionViewDelegate
//    // MARK: - UICollectionViewDelegate
//    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
//        guard scrollView == emojiCoverAllCollectionView else { return }
//        let visibleRect = CGRect(origin: emojiCoverAllCollectionView.contentOffset, size: emojiCoverAllCollectionView.bounds.size)
//        guard let visibleIndexPath = emojiCoverAllCollectionView.indexPathForItem(at: CGPoint(x: visibleRect.midX, y: visibleRect.midY)) else { return }
//        
//        if shouldShowAdAt(index: visibleIndexPath.item) {
//            
//        } else {
//            selectedIndex = getActualIndex(for: visibleIndexPath.item)
//        }
//        reloadAndScrollToSelectedIndex(from: emojiCoverAllCollectionView)
//    }
//    
//    // MARK: - Helpers
//    private func reloadAndScrollToSelectedIndex(from collectionView: UICollectionView) {
//        emojiCoverAllCollectionView.reloadData()
//        emojiCoverSlideCollectionview.reloadData()
//        
//        let indexPathToScroll = IndexPath(item: selectedIndex, section: 0)
//        if collectionView == emojiCoverAllCollectionView {
//            emojiCoverSlideCollectionview.scrollToItem(at: indexPathToScroll, at: .centeredHorizontally, animated: true)
//        } else if collectionView == emojiCoverSlideCollectionview {
//            let visibleIndexPath = getVisibleIndexForActualIndex(selectedIndex)
//            emojiCoverAllCollectionView.scrollToItem(at: visibleIndexPath, at: .centeredHorizontally, animated: true)
//        }
//    }
//    
//    private func getVisibleIndexForActualIndex(_ actualIndex: Int) -> IndexPath {
//        var visibleIndex = actualIndex
//        let adCountBefore = actualIndex / adInterval
//        visibleIndex += adCountBefore
//        return IndexPath(item: visibleIndex, section: 0)
//    }
//    
//    private func scrollToIndex(_ index: Int, animated: Bool) {
//        let indexPath = IndexPath(item: index, section: 0)
//        emojiCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
//        emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard scrollView == emojiCoverAllCollectionView else { return }
//        
//        let centerX = scrollView.contentOffset.x + (scrollView.frame.width / 2)
//        
//        for cell in emojiCoverAllCollectionView.visibleCells {
//            let cellCenterX = cell.center.x
//            let distance = centerX - cellCenterX
//            let maxDistance = scrollView.frame.width
//            
//            let angle = (distance / maxDistance) * (.pi / 24)
//            
//            let transform = CGAffineTransform(rotationAngle: angle)
//            
//            cell.transform = transform
//        }
//    }
//}
//
//// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
//extension EmojiCoverPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    
//    // MARK: - Show ImageOptions ActionSheet
//    private func showImageOptionsActionSheet(sourceView: UIButton) {
//        let titleString = NSAttributedString(string: "Select cover image", attributes: [
//            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
//        ])
//        
//        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
//        alertController.setValue(titleString, forKey: "attributedTitle")
//        
//        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
//            self?.btnCameraTapped()
//        }
//        
//        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
//            self?.btnGalleryTapped()
//        }
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
//        
//        alertController.addAction(cameraAction)
//        alertController.addAction(galleryAction)
//        alertController.addAction(cancelAction)
//        
//        if let popoverController = alertController.popoverPresentationController {
//            popoverController.sourceView = sourceView
//            popoverController.sourceRect = sourceView.bounds
//        }
//        
//        present(alertController, animated: true)
//    }
//    
//    // MARK: - Camera Button
//    func btnCameraTapped() {
//        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
//        switch cameraAuthorizationStatus {
//        case .notDetermined:
//            AVCaptureDevice.requestAccess(for: .video) { granted in
//                DispatchQueue.main.async {
//                    if granted {
//                        self.showImagePicker(for: .camera)
//                    } else {
//                        self.showPermissionSnackbar(for: "camera")
//                    }
//                }
//            }
//        case .authorized:
//            showImagePicker(for: .camera)
//        case .restricted, .denied:
//            showPermissionSnackbar(for: "camera")
//        @unknown default:
//            fatalError("Unknown authorization status")
//        }
//    }
//    
//    // MARK: - Gallery Button
//    func btnGalleryTapped() {
//        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
//        switch photoAuthorizationStatus {
//        case .notDetermined:
//            PHPhotoLibrary.requestAuthorization { status in
//                DispatchQueue.main.async {
//                    if status == .authorized {
//                        self.showImagePicker(for: .photoLibrary)
//                    } else {
//                        self.showPermissionSnackbar(for: "photo library")
//                    }
//                }
//            }
//        case .authorized, .limited:
//            showImagePicker(for: .photoLibrary)
//        case .restricted, .denied:
//            showPermissionSnackbar(for: "photo library")
//        @unknown default:
//            fatalError("Unknown authorization status")
//        }
//    }
//    
//    // MARK: - showImagePicker
//    func showImagePicker(for sourceType: UIImagePickerController.SourceType) {
//        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
//            let imagePicker = UIImagePickerController()
//            imagePicker.delegate = self
//            imagePicker.sourceType = sourceType
//            imagePicker.allowsEditing = true
//            if sourceType == .camera {
//                imagePicker.cameraDevice = .rear
//            }
//            DispatchQueue.main.async {
//                self.present(imagePicker, animated: true, completion: nil)
//            }
//        } else {
//            print("\(sourceType) is not available")
//        }
//    }
//    
//    // MARK: - Show permission snackbar
//    func showPermissionSnackbar(for feature: String) {
//        let messageKey: String
//        
//        switch feature {
//        case "camera":
//            messageKey = "We need access to your camera to set the cover image."
//        case "photo library":
//            messageKey = "We need access to your photo library to set the cover image."
//        default:
//            messageKey = "We need access to your camera to set the cover image."
//        }
//        
//        let localizedMessage = NSLocalizedString(messageKey, comment: "")
//        let settingsText = NSLocalizedString("Settings", comment: "")
//        
//        let snackbar = Snackbar(message: localizedMessage, backgroundColor: .snackbar)
//        snackbar.setAction(title: settingsText) {
//            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
//                return
//            }
//            
//            if UIApplication.shared.canOpenURL(settingsUrl) {
//                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
//                    print("Settings opened: \(success)")
//                })
//            }
//        }
//        snackbar.show(in: self.view, duration: 5.0)
//    }
//    
//    // MARK: - UIImagePickerControllerDelegate
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
//            let temporaryDirectory = NSTemporaryDirectory()
//            let fileName = "\(UUID().uuidString).jpg"
//            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
//            
//            if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
//                try? imageData.write(to: fileURL)
//                if let fileData = try? Data(contentsOf: fileURL) {
//                    self.selectedCoverImageFile = fileData
//                    self.selectedCoverImageURL = nil
//                    self.selectedCoverImageName = "Custom Cover Image"
//                }
//                print("Custom Cover Image URL: \(fileURL.absoluteString)")
//                
//                customCoverImages.insert(selectedImage, at: 0)
//                selectedCoverIndex = 0
//                saveImages()
//                
//                DispatchQueue.main.async { [weak self] in
//                    guard let self = self else { return }
//                    
//                    self.emojiCoverSlideCollectionview.reloadData()
//                    self.emojiCoverAllCollectionView.reloadData()
//                    let indexPath = IndexPath(item: 0, section: 0)
//                    let indexPath1 = IndexPath(item: 0, section: 0)
//                    self.emojiCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                    self.emojiCoverAllCollectionView.selectItem(at: indexPath1, animated: false, scrollPosition: [])
//                    self.selectedCustomCoverIndex = indexPath
//                    self.emojiCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    self.emojiCoverAllCollectionView.scrollToItem(at: indexPath1, at: .centeredHorizontally, animated: true)
//                }
//            }
//        }
//        dismiss(animated: true, completion: nil)
//    }
//    
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true, completion: nil)
//    }
//    
//    func loadSavedImages() {
//        if let savedImagesData = UserDefaults.standard.object(forKey: ConstantValue.is_UserCoverImages) as? Data {
//            do {
//                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [UIImage] {
//                    customCoverImages = decodedImages
//                    emojiCoverSlideCollectionview.reloadData()
//                    emojiCoverAllCollectionView.reloadData()
//                }
//            } catch {
//                print("Error decoding saved images: \(error)")
//            }
//        }
//    }
//    
//    func saveImages() {
//        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customCoverImages, requiringSecureCoding: false) {
//            UserDefaults.standard.set(encodedData, forKey: ConstantValue.is_UserCoverImages)
//        }
//    }
//}
//
//extension EmojiCoverPageVC: UISearchBarDelegate {
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
//        filterContent(with: searchText)
//    }
//    
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.resignFirstResponder()
//    }
//    
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//        searchBar.resignFirstResponder()
//        filterContent(with: "")
//    }
//}





//
//import UIKit
//
//// MARK: - NativeAds Cell
//class NativeAdsCell: UICollectionViewCell {
//    private var adView: UIView?
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupCell()
//    }
//    
//    required init?(coder: NSCoder) {
//        super.init(coder: coder)
//        setupCell()
//    }
//    
//    private func setupCell() {
//        layer.cornerRadius = 20
//        clipsToBounds = true
//    }
//    
//    func configure(with adView: UIView?) {
//        self.adView?.removeFromSuperview()
//        
//        guard let adView = adView else { return }
//        
//        self.adView = adView
//        adView.layer.cornerRadius = 20
//        adView.layer.backgroundColor = UIColor.background.cgColor
//        adView.clipsToBounds = true
//        contentView.addSubview(adView)
//        adView.translatesAutoresizingMaskIntoConstraints = false
//        
//        NSLayoutConstraint.activate([
//            adView.topAnchor.constraint(equalTo: contentView.topAnchor),
//            adView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
//            adView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
//            adView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
//        ])
//    }
//    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        adView?.removeFromSuperview()
//        adView = nil
//    }
//}
