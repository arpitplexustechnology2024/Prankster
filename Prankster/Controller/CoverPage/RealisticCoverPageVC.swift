//
//  RealisticCoverPageVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import Alamofire

class RealisticCoverPageVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var realisticCoverAllCollectionView: UICollectionView!
    @IBOutlet weak var realisticCoverSlideCollectionview: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!
    @IBOutlet weak var searchbarBlurView: UIVisualEffectView!
    
    private let viewModel = RealisticViewModel()
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private var isSearchActive = false
    private var filteredRealisticCoverPages: [CoverPageData] = []
    private var currentDataSource: [CoverPageData] {
        return isSearchActive ? filteredRealisticCoverPages : viewModel.realisticCoverPages
    }
    var isLoading = true
    private let categoryId: Int = 4
    private var isLoadingMore = false
    private var selectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.self.setupSearchBar()
        self.self.setupNoDataView()
        self.self.setupSwipeGesture()
        self.self.showSkeletonLoader()
        self.self.setupCollectionView()
        self.self.setupNoInternetView()
        self.self.hideKeyboardTappedAround()
        self.self.checkInternetAndFetchData()
        self.self.filteredRealisticCoverPages = viewModel.realisticCoverPages
        
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
                self.realisticCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.realisticCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedIndex = 0
            }
        }
    }
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            self.realisticCoverAllCollectionView.reloadData()
            self.realisticCoverSlideCollectionview.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupSearchBar() {
        searchbar.delegate = self
        searchbar.placeholder = "Search cover image"
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
            fetchAllCoverPages()
            self.noInternetView?.isHidden = true
            self.hideNoDataView()
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    private func setupCollectionView() {
        self.realisticCoverAllCollectionView.delegate = self
        self.realisticCoverAllCollectionView.dataSource = self
        self.realisticCoverAllCollectionView.isPagingEnabled = true
        self.realisticCoverSlideCollectionview.delegate = self
        self.realisticCoverSlideCollectionview.dataSource = self
        self.realisticCoverAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.realisticCoverSlideCollectionview.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
    }
    
    func fetchAllCoverPages() {
        guard !isLoadingMore else { return }
        isLoadingMore = true
        viewModel.fetchRealisticCoverPages { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async{
                self.isLoadingMore = false
                if success {
                    if self.viewModel.realisticCoverPages.isEmpty {
                        self.hideSkeletonLoader()
                        self.showNoDataView()
                    } else {
                        self.hideSkeletonLoader()
                        self.hideNoDataView()
                        self.realisticCoverAllCollectionView.reloadData()
                        self.realisticCoverSlideCollectionview.reloadData()
                        
                        if !self.currentDataSource.isEmpty {
                            let indexPath = IndexPath(item: self.selectedIndex, section: 0)
                            self.realisticCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                            self.realisticCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: .centeredHorizontally)
                        }
                    }
                } else if let errorMessage = self.viewModel.errorMessage {
                    self.hideSkeletonLoader()
                    self.noDataView.isHidden = false
                    print("Error fetching all cover pages: \(errorMessage)")
                }
            }
        }
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
            noDataView.topAnchor.constraint(equalTo: searchbar.bottomAnchor),
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
            noInternetView.topAnchor.constraint(equalTo: searchbar.bottomAnchor),
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
        self.realisticCoverAllCollectionView.reloadData()
        self.realisticCoverSlideCollectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        self.realisticCoverAllCollectionView.reloadData()
        self.realisticCoverSlideCollectionview.reloadData()
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
            filteredRealisticCoverPages = viewModel.realisticCoverPages
        } else {
            filteredRealisticCoverPages = viewModel.realisticCoverPages.filter { coverPage in
                let nameMatch = coverPage.coverName.lowercased().contains(searchText.lowercased())
                let tagMatch = coverPage.tagName.contains { tag in
                    tag.lowercased().contains(searchText.lowercased())
                }
                return nameMatch || tagMatch
            }
        }
        
        DispatchQueue.main.async {
            self.realisticCoverAllCollectionView.reloadData()
            self.realisticCoverSlideCollectionview.reloadData()
            
            if self.filteredRealisticCoverPages.isEmpty && !searchText.isEmpty {
                self.showNoDataView()
            } else {
                self.hideNoDataView()
                
                if !self.filteredRealisticCoverPages.isEmpty {
                    self.selectedIndex = 0
                    let indexPath = IndexPath(item: 0, section: 0)
                    
                    self.realisticCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                    self.realisticCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    
                    self.realisticCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.realisticCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                }
            }
        }
    }
}

extension RealisticCoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isLoading {
            return 8
        }
        return currentDataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == realisticCoverAllCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RealisticCoverAllCollectionViewCell", for: indexPath) as! RealisticCoverAllCollectionViewCell
                guard indexPath.row < currentDataSource.count else {
                    return cell
                }
                
                let coverPageData = currentDataSource[indexPath.row]
                cell.delegate = self
                cell.configure(with: coverPageData)
                
                cell.isSelected = indexPath.item == selectedIndex
                
                return cell
            }
        } else if collectionView == realisticCoverSlideCollectionview {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RealisticCoverSliderCollectionViewCell", for: indexPath) as! RealisticCoverSliderCollectionViewCell
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
        
        if collectionView == realisticCoverAllCollectionView {
            realisticCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            realisticCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else if collectionView == realisticCoverSlideCollectionview {
            realisticCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            realisticCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 80
        let height: CGFloat = 104
        
        if collectionView == realisticCoverAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == realisticCoverSlideCollectionview {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: LoadingFooterView.reuseIdentifier,
                for: indexPath
            ) as! LoadingFooterView
            
            if !isLoading && !isSearchActive && viewModel.hasMorePages && !viewModel.realisticCoverPages.isEmpty {
                footer.startAnimating()
            } else {
                footer.stopAnimating()
            }
            
            return footer
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == viewModel.realisticCoverPages.count - 1 && !viewModel.isLoading && viewModel.hasMorePages {
            fetchAllCoverPages()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == realisticCoverAllCollectionView {
            let pageWidth = scrollView.bounds.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
            
            if currentPage != selectedIndex {
                selectedIndex = currentPage
                
                let indexPath = IndexPath(item: currentPage, section: 0)
                realisticCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                realisticCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

extension RealisticCoverPageVC: RealisticCoverAllCollectionViewCellDelegate {
    func didTapDoneButton(for coverPageData: CoverPageData) {
        if coverPageData.coverPremium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
            presentPremiumViewController(for: coverPageData)
        } else {
            if let navigationController = self.navigationController {
                if let coverPageVC = navigationController.viewControllers.first(where: { $0 is CoverPageVC }) as? CoverPageVC {
                    coverPageVC.updateSelectedImage(with: coverPageData)
                    navigationController.popToViewController(coverPageVC, animated: true)
                }
            }
        }
    }
    
    private func presentPremiumViewController(for coverPageData: CoverPageData) {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumPopupVC") as! PremiumPopupVC
        premiumVC.setItemIDToUnlock(coverPageData.itemID)
        premiumVC.modalTransitionStyle = .crossDissolve
        premiumVC.modalPresentationStyle = .overCurrentContext
        present(premiumVC, animated: true, completion: nil)
    }
}

extension RealisticCoverPageVC: UISearchBarDelegate {
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
