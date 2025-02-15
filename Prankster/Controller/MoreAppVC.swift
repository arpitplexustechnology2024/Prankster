//
//  MoreAppVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import Alamofire

class MoreAppVC: UIViewController {
    
    @IBOutlet weak var nativeSmallAds: UIView!
    @IBOutlet weak var adHeightConstaints: NSLayoutConstraint!
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var collectionview: UICollectionView!
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private var viewModel: MoreAppViewModel!
    private var moreDataArray: [MoreData] = []
    private var skeletonLoadingView: SkeletonMoreappLoadingView?
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    private var adsViewModel: AdsViewModel!
    
    init(viewModel: MoreAppViewModel, adViewModule: AdsViewModel) {
        self.viewModel = viewModel
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = MoreAppViewModel(apiService: MoreAppAPIManger.shared)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAds()
        self.setupUI()
        self.setupSkeletonView()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.setupNoInternetView()
        self.checkInternetAndFetchData()
    }
    
    private func setupSkeletonView() {
        skeletonLoadingView = SkeletonMoreappLoadingView()
        skeletonLoadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        if let skeletonView = skeletonLoadingView {
            view.addSubview(skeletonView)
            
            NSLayoutConstraint.activate([
                skeletonView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
                skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            self.fetchMoreData()
            self.noInternetView?.isHidden = true
        } else {
            self.showNoInternetView()
        }
    }
    
    func setupUI() {
        self.collectionview.delegate = self
        self.collectionview.dataSource = self
        if let layout = collectionview.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 16
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    
    private func fetchMoreData() {
        skeletonLoadingView?.startAnimating()
        
        let packageName = "id6739135275"
        viewModel.fetchMoreData(packageName: packageName) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async { [self] in
                switch result {
                case .success(let moreDataArray):
                    self.moreDataArray = moreDataArray
                    DispatchQueue.main.async {
                        self.skeletonLoadingView?.stopAnimating()
                        self.skeletonLoadingView?.isHidden = true
                        self.noDataView.isHidden = true
                        self.collectionview.reloadData()
                    }
                case .failure(let error):
                    print("Error: \(error.localizedDescription)")
                    self.skeletonLoadingView?.stopAnimating()
                    self.noDataView.isHidden = false
                }
            }
        }
    }
    
    @objc private func appIDButtonClicked(_ sender: UIButton) {
        let index = sender.tag
        let moreData = moreDataArray[index]
        
        let appStoreURL = "https://apps.apple.com/app/id\(moreData.appID)"
        
        if let url = URL(string: appStoreURL) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
            self.setupAds()
            checkInternetAndFetchData()
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
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
    
    private func setupAds() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            adHeightConstaints.constant = 150
        } else {
            adHeightConstaints.constant = 120
        }
        
        if isConnectedToInternet(), !PremiumManager.shared.isContentUnlocked(itemID: -1) {
            if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
                print("Native Ad ID: \(nativeAdID)")
                if UIDevice.current.userInterfaceIdiom == .pad {
                    nativeSmallIpadAdUtility = NativeSmallIpadAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                } else {
                    nativeSmallIphoneAdUtility = NativeSmallIphoneAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        } else {
            nativeSmallAds.isHidden = true
        }
    }
}

extension MoreAppVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return moreDataArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MoreAppCollectionViewCell", for: indexPath) as! MoreAppCollectionViewCell
        let moreData = moreDataArray[indexPath.item]
        
        cell.configure(with: moreData)
        cell.More_App_DownloadButton.tag = indexPath.item
        cell.More_App_DownloadButton.addTarget(self, action: #selector(appIDButtonClicked(_:)), for: .touchUpInside)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8 * 2
        let availableWidth = collectionView.frame.width - padding
        let widthPerItem = availableWidth
        let heightPerItem: CGFloat = 100
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
}
