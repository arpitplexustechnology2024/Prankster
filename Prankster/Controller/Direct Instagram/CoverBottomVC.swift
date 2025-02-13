//
//  CoverBottomVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 11/02/25.
//

import UIKit
import Alamofire

class CoverBottomVC: UIViewController {
    
    @IBOutlet weak var collectionview: UICollectionView!
    
    @IBOutlet weak var selectCoverLabel: UILabel!
    private var viewModel: CoverViewModel!
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private var skeletonLoadingView: SkeletonCoverLoadingView?
    let interstitialAdUtility = InterstitialAdUtility()
    private var adsViewModel: AdsViewModel!
    var DownloadURL: String?
    
    init(viewModule: CoverViewModel, adViewModule: AdsViewModel) {
        self.viewModel = viewModule
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = CoverViewModel(apiService: CoverAPIManger.shared)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionview.delegate = self
        self.collectionview.dataSource = self
        setupSkeletonView()
        showSkeletonLoader()
        checkInternetAndFetchData()
        PremiumManager.shared.clearTemporaryUnlocks()
    
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePremiumContentUnlocked),
            name: NSNotification.Name("PremiumContentUnlocked"),
            object: nil
        )
        
    }
    
    @objc private func handlePremiumContentUnlocked() {
        DispatchQueue.main.async {
            self.collectionview.reloadData()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    private func setupSkeletonView() {
        skeletonLoadingView = SkeletonCoverLoadingView()
        skeletonLoadingView?.isHidden = true
        skeletonLoadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        if let skeletonView = skeletonLoadingView {
            view.addSubview(skeletonView)
            
            NSLayoutConstraint.activate([
                skeletonView.topAnchor.constraint(equalTo: selectCoverLabel.bottomAnchor, constant: 16),
                skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    func fetchAllCoverPages() {
        viewModel.fetchEmojiCoverPages(ispremium: "true") { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    if self.viewModel.emojiCoverPages.isEmpty {
                        self.hideSkeletonLoader()
                        self.showNoDataView()
                    } else {
                        self.hideSkeletonLoader()
                        self.hideNoDataView()
                        self.collectionview.reloadData()
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
        self.view.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: view.bottomAnchor),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150)
        ])
    }
    
    // MARK: - makePrankButtonTapped
    @objc func makePrankButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - setupNoInternetView
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        self.view.addSubview(noInternetView)
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: view.bottomAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - retryButtonTapped
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            self.checkInternetAndFetchData()
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
        skeletonLoadingView?.isHidden = false
        skeletonLoadingView?.startAnimating()
        self.collectionview.reloadData()
    }
    
    func hideSkeletonLoader() {
        skeletonLoadingView?.isHidden = true
        skeletonLoadingView?.stopAnimating()
        self.collectionview.reloadData()
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
}

extension CoverBottomVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.emojiCoverPages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverBottomCell", for: indexPath) as? CoverBottomCell else {
            return UICollectionViewCell()
        }
        
        let coverPageData = viewModel.emojiCoverPages[indexPath.item]
        cell.configure(with: coverPageData)
        
        if indexPath.item == viewModel.emojiCoverPages.count - 1 {
            viewModel.fetchEmojiCoverPages(ispremium: "true") { [weak self] success in
                if success {
                    DispatchQueue.main.async {
                        self?.collectionview.reloadData()
                    }
                }
            }
        }
        
        cell.premiumActionButton.tag = indexPath.row
        cell.premiumActionButton.addTarget(self, action: #selector(handlePremiumButtonTap(_:)), for: .touchUpInside)
        
        cell.DoneButton.addTarget(self, action: #selector(handleDoneButtonTap(_:)), for: .touchUpInside)
        cell.DoneButton.tag = indexPath.item
        
        return cell
    }
    
    @objc private func handlePremiumButtonTap(_ sender: UIButton) {
        let index = sender.tag
        let coverPageData = viewModel.emojiCoverPages[index]
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
        
        let index = sender.tag
        let coverPageData = viewModel.emojiCoverPages[index]
        print("URL :- \(coverPageData.coverName)")
        
        if isConnectedToInternet() {
            if shouldOpenDirectly {
                
                self.dismiss(animated: true) { [self] in
                    if let window = UIApplication.shared.windows.first {
                        if let rootViewController = window.rootViewController as? UINavigationController {
                            let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let shareLinkVC = storyboard.instantiateViewController(withIdentifier: "ShareLinkVC") as! ShareLinkVC
                            shareLinkVC.selectedURL = self.DownloadURL
                            shareLinkVC.selectedName = coverPageData.coverName
                            shareLinkVC.selectedCoverURL = coverPageData.coverURL
                            shareLinkVC.selectedPranktype = "video"
                            shareLinkVC.selectedFileType = "mp4"
                            shareLinkVC.sharePrank = true
                            rootViewController.pushViewController(shareLinkVC, animated: true)
                        }
                    }
                }
            } else {
                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                    interstitialAdUtility.onInterstitialEarned = { [weak self] in
                        self?.dismiss(animated: true) { [self] in
                            if let window = UIApplication.shared.windows.first {
                                if let rootViewController = window.rootViewController as? UINavigationController {
                                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                    let shareLinkVC = storyboard.instantiateViewController(withIdentifier: "ShareLinkVC") as! ShareLinkVC
                                    shareLinkVC.selectedURL = self?.DownloadURL
                                    shareLinkVC.selectedName = coverPageData.coverName
                                    shareLinkVC.selectedCoverURL = coverPageData.coverURL
                                    shareLinkVC.selectedPranktype = "video"
                                    shareLinkVC.selectedFileType = "mp4"
                                    shareLinkVC.sharePrank = true
                                    rootViewController.pushViewController(shareLinkVC, animated: true)
                                }
                            }
                        }
                    }
                    interstitialAdUtility.loadAndShowAd(adUnitID: interstitialAdID, rootViewController: self)
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 32
        let spacing: CGFloat = 16
        let availableWidth = collectionView.bounds.width - padding - spacing
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let cellWidth = (availableWidth - (spacing * 3)) / 4
            return CGSize(width: cellWidth, height: 180)
        } else {
            let cellWidth = (availableWidth - spacing) / 2
            return CGSize(width: cellWidth, height: 180)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
}
