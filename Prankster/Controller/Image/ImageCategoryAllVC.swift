//
//  ImageCategoryAllVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 18/10/24.
//
//
//import UIKit
//import Alamofire
//
//class ImageCategoryAllVC: UIViewController {
//    
//    @IBOutlet weak var navigationbarView: UIView!
//    @IBOutlet weak var imageCharacterAllCollectionView: UICollectionView!
//    @IBOutlet weak var imageCharacterSlideCollectionview: UICollectionView!
//    @IBOutlet weak var searchbar: UISearchBar!
//    @IBOutlet weak var searchbarBlurView: UIVisualEffectView!
//    
//    var isLoading = true
//    var categoryId: Int = 0
//    private let typeId: Int = 3
//    private var isLoadingMore = false
//    private var isSearchActive = false
//    private var selectedIndex: Int = 0
//    private var noDataView: NoDataView!
//    private var noInternetView: NoInternetView!
//    private var viewModel = CategoryAllViewModel()
//    private var filteredImages: [CategoryAllData] = []
//    private var currentDataSource: [CategoryAllData] {
//        return isSearchActive ? filteredImages : viewModel.audioData
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.setupSearchBar()
//        self.setupNoDataView()
//        self.setupSwipeGesture()
//        self.showSkeletonLoader()
//        self.setupNoInternetView()
//        self.setupCollectionView()
//        self.hideKeyboardTappedAround()
//        self.checkInternetAndFetchData()
//        self.filteredImages = viewModel.audioData
//        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handlePremiumContentUnlocked),
//            name: NSNotification.Name("PremiumContentUnlocked"),
//            object: nil
//        )
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
//            guard let self = self else { return }
//            if !self.currentDataSource.isEmpty {
//                let indexPath = IndexPath(item: 0, section: 0)
//                self.imageCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                self.imageCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                self.selectedIndex = 0
//            }
//        }
//    }
//    
//    @objc private func handlePremiumContentUnlocked() {
//        DispatchQueue.main.async {
//            self.imageCharacterAllCollectionView.reloadData()
//            self.imageCharacterSlideCollectionview.reloadData()
//        }
//    }
//    
//    deinit {
//        NotificationCenter.default.removeObserver(self)
//    }
//    
//    private func setupSearchBar() {
//        searchbar.delegate = self
//        searchbar.placeholder = "Search audio or artist name"
//        searchbar.backgroundImage = UIImage()
//        searchbar.layer.cornerRadius = 10
//        searchbar.clipsToBounds = true
//        searchbarBlurView.layer.cornerRadius = 10
//        searchbarBlurView.clipsToBounds = true
//        searchbarBlurView.layer.masksToBounds = true
//        
//        if let textField = searchbar.value(forKey: "searchField") as? UITextField {
//            textField.textColor = .white
//            textField.attributedPlaceholder = NSAttributedString(
//                string: "Search audio or artist name",
//                attributes: [.foregroundColor: UIColor.white]
//            )
//        }
//        
//        if let textField = searchbar.value(forKey: "searchField") as? UITextField,
//           let leftIconView = textField.leftView as? UIImageView {
//            leftIconView.tintColor = .white
//            leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
//        }
//    }
//    
//    func checkInternetAndFetchData() {
//        if isConnectedToInternet() {
//            fetchAllImages()
//            self.noInternetView?.isHidden = true
//            self.hideNoDataView()
//        } else {
//            self.showNoInternetView()
//            self.hideSkeletonLoader()
//        }
//    }
//    
//    private func setupCollectionView() {
//        self.imageCharacterAllCollectionView.delegate = self
//        self.imageCharacterAllCollectionView.dataSource = self
//        self.imageCharacterAllCollectionView.isPagingEnabled = true
//        self.imageCharacterSlideCollectionview.delegate = self
//        self.imageCharacterSlideCollectionview.dataSource = self
//        self.imageCharacterAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.imageCharacterSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
//        self.imageCharacterSlideCollectionview.register(
//            LoadingFooterView.self,
//            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
//            withReuseIdentifier: LoadingFooterView.reuseIdentifier
//        )
//        if let layout = imageCharacterSlideCollectionview.collectionViewLayout as? UICollectionViewFlowLayout {
//            layout.footerReferenceSize = CGSize(width: 16, height: imageCharacterSlideCollectionview.frame.height)
//        }
//    }
//    
//    // MARK: - fetchAllImages
//    func fetchAllImages() {
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
//                        self.imageCharacterAllCollectionView.reloadData()
//                        self.imageCharacterSlideCollectionview.reloadData()
//                        
//                        if !self.currentDataSource.isEmpty {
//                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
//                            self.imageCharacterSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
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
//    @IBAction func btnBackTapped(_ sender: UIButton) {
//        self.navigationController?.popViewController(animated: true)
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
//            noDataView.topAnchor.constraint(equalTo: searchbar.bottomAnchor),
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
//            noInternetView.topAnchor.constraint(equalTo: searchbar.bottomAnchor),
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
//        self.imageCharacterAllCollectionView.reloadData()
//    }
//    
//    func hideSkeletonLoader() {
//        isLoading = false
//        self.imageCharacterAllCollectionView.reloadData()
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
//            filteredImages = viewModel.audioData
//        } else {
//            filteredImages = viewModel.audioData.filter { coverPage in
//                let nameMatch = coverPage.name.lowercased().contains(searchText.lowercased())
//                return nameMatch
//            }
//        }
//        
//        DispatchQueue.main.async {
//            self.selectedIndex = 0
//            
//            self.imageCharacterAllCollectionView.reloadData()
//            self.imageCharacterSlideCollectionview.reloadData()
//            
//            if self.filteredImages.isEmpty && !searchText.isEmpty {
//                self.showNoDataView()
//            } else {
//                self.hideNoDataView()
//                
//                if !self.filteredImages.isEmpty {
//                    let indexPath = IndexPath(item: 0, section: 0)
//                    
//                    if self.imageCharacterAllCollectionView.numberOfItems(inSection: 0) > 0 {
//                        self.imageCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//                        self.imageCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                    
//                    if self.imageCharacterSlideCollectionview.numberOfItems(inSection: 0) > 0 {
//                        self.imageCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.imageCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
//extension ImageCategoryAllVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if isLoading {
//            return 8
//        }
//        return currentDataSource.count
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        if collectionView == imageCharacterAllCollectionView {
//            if isLoading {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                cell.isUserInteractionEnabled = false
//                return cell
//            } else {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterAllCollectionViewCell", for: indexPath) as! ImageCharacterAllCollectionViewCell
//                
//                guard indexPath.row < currentDataSource.count else {
//                    return cell
//                }
//                
//                let coverPageData = currentDataSource[indexPath.row]
//                cell.delegate = self
//                cell.configure(with: coverPageData)
//                return cell
//            }
//        } else if collectionView == imageCharacterSlideCollectionview {
//            if isLoading {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
//                cell.isUserInteractionEnabled = false
//                return cell
//            } else {
//                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterSliderCollectionViewCell", for: indexPath) as! ImageCharacterSliderCollectionViewCell
//                
//                guard indexPath.row < currentDataSource.count else {
//                    return cell
//                }
//                
//                let coverPageData = currentDataSource[indexPath.row]
//                cell.configure(with: coverPageData)
//                return cell
//            }
//        }
//        return UICollectionViewCell()
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        guard indexPath.item < currentDataSource.count else { return }
//        
//        selectedIndex = indexPath.item
//        
//        if collectionView == imageCharacterAllCollectionView {
//            imageCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//            imageCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        } else {
//            imageCharacterAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
//            imageCharacterAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width: CGFloat = 90
//        let height: CGFloat = 90
//        
//        if collectionView == imageCharacterAllCollectionView {
//            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
//        } else if collectionView == imageCharacterSlideCollectionview {
//            return CGSize(width: width, height: height)
//        }
//        return CGSize(width: width, height: height)
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
//        let lastItem = viewModel.audioData.count - 1
//        if indexPath.item == lastItem && !viewModel.isLoading && viewModel.hasMorePages {
//            fetchAllImages()
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
//            if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.audioData.isEmpty {
//                footer.startAnimating()
//            } else {
//                footer.stopAnimating()
//            }
//            return footer
//        }
//        return UICollectionReusableView()
//    }
//    
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        if scrollView == imageCharacterAllCollectionView {
//            let pageWidth = scrollView.bounds.width
//            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
//            
//            guard currentPage >= 0 && currentPage < currentDataSource.count else { return }
//            
//            if currentPage != selectedIndex {
//                selectedIndex = currentPage
//                
//                let indexPath = IndexPath(item: currentPage, section: 0)
//                DispatchQueue.main.async {
//                    if currentPage < self.currentDataSource.count {
//                        self.imageCharacterSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
//                        self.imageCharacterSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
//                    }
//                }
//            }
//        }
//    }
//}
//
//// MARK: - ImageCharacterAllCollectionViewCellDelegate
//extension ImageCategoryAllVC: ImageCharacterAllCollectionViewCellDelegate {
//    func didTapDoneButton(for categoryAllData: CategoryAllData) {
//        if categoryAllData.premium && !PremiumManager.shared.isContentUnlocked(itemID: categoryAllData.itemID) {
//            presentPremiumViewController(for: categoryAllData)
//        } else {
//            if let navigationController = self.navigationController {
//                if let coverPageVC = navigationController.viewControllers.first(where: { $0 is ImageVC }) as? ImageVC {
//                    coverPageVC.updateSelectedImage(with: categoryAllData)
//                    navigationController.popToViewController(coverPageVC, animated: true)
//                }
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
//// MARK: - UISearchBarDelegate
//extension ImageCategoryAllVC: UISearchBarDelegate {
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
