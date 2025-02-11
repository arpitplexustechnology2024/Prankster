//
//  ViewLinkVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 01/12/24.
//

import UIKit
import Alamofire

class ViewLinkVC: UIViewController {
    
    @IBOutlet weak var nativeSmallAds: UIView!
    @IBOutlet weak var adHeightConstaints: NSLayoutConstraint!
    @IBOutlet weak var viewlinkCollectionView: UICollectionView!
    @IBOutlet weak var navigationView: UIView!
    var pranks: [PrankCreateData] = []
    private var recentPrank: RecentPrank!
    private var noInternetView: NoInternetView!
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    private let adsViewModel = AdsViewModel()
    private let rewardAdUtility = RewardAdUtility()
    private var loadingAlert: LoadingAlertView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAds()
        setupSwipeGesture()
        setupLoadingAlert()
        setupNoDataView()
        setupCollectionView()
        self.setupNoInternetView()
        self.checkInternetAndFetchData()
    }
    
    private func setupLoadingAlert() {
        loadingAlert = LoadingAlertView(frame: view.bounds)
        loadingAlert.isHidden = true
        view.addSubview(loadingAlert)
        loadingAlert.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingAlert.topAnchor.constraint(equalTo: view.topAnchor),
            loadingAlert.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingAlert.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingAlert.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - checkInternetAndFetchData
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            fetchPranksFromUserDefaults()
            self.noInternetView?.isHidden = true
        } else {
            self.noInternetView?.isHidden = false
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
                
                if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                    print("Reward Ad ID: \(rewardAdID)")
                    rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID, rootViewController: self)
                } else {
                    print("No Reward Ad ID found")
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        } else {
            nativeSmallAds.isHidden = true
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    func setupCollectionView() {
        viewlinkCollectionView.delegate = self
        viewlinkCollectionView.dataSource = self
        
        if let layout = viewlinkCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 16
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    
    private func setupNoDataView() {
        recentPrank = RecentPrank()
        recentPrank.makePrank.addTarget(self, action: #selector(makePrankButtonTapped), for: .touchUpInside)
        recentPrank.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        recentPrank.isHidden = true
        self.view.addSubview(recentPrank)
        recentPrank.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recentPrank.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            recentPrank.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            recentPrank.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            recentPrank.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150)
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
            noInternetView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - retryButtonTapped
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            self.checkInternetAndFetchData()
            if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
                print("Native Ad ID: \(nativeAdID)")
                if UIDevice.current.userInterfaceIdiom == .pad {
                    nativeSmallIpadAdUtility = NativeSmallIpadAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                } else {
                    nativeSmallIphoneAdUtility = NativeSmallIphoneAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                }
                
                if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                    print("Reward Ad ID: \(rewardAdID)")
                    rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID, rootViewController: self)
                } else {
                    print("No Reward Ad ID found")
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func fetchPranksFromUserDefaults() {
        if let savedPranksData = UserDefaults.standard.data(forKey: "SavedPranks"),
           let savedPranks = try? JSONDecoder().decode([PrankCreateData].self, from: savedPranksData) {
            self.pranks = savedPranks.sorted { $0.id > $1.id }
            recentPrank.isHidden = !pranks.isEmpty
            viewlinkCollectionView.reloadData()
        } else {
            recentPrank.isHidden = false
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchPranksFromUserDefaults()
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
}

// MARK: - Collection View Delegate and DataSource
extension ViewLinkVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return pranks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ViewLinkCollectionViewCell", for: indexPath) as! ViewLinkCollectionViewCell
        
        let prank = pranks[indexPath.item]
        cell.prankNameLabel.text = prank.name
        
        if let url = URL(string: prank.coverImage) {
            AF.request(url).response { response in
                switch response.result {
                case .success(let data):
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.imageView.image = image
                        }
                    }
                case .failure(let error):
                    print("Image load error: \(error)")
                    cell.imageView.image = UIImage(named: "imageplacholder")
                }
            }
        }
        
        cell.shareButton.tag = indexPath.item
        cell.shareButton.addTarget(self, action: #selector(shareButtonTapped(_:)), for: .touchUpInside)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 8 * 2
        let availableWidth = collectionView.frame.width - padding
        let widthPerItem = availableWidth
        let heightPerItem: CGFloat = 100
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    @objc func shareButtonTapped(_ sender: UIButton) {
        let prank = pranks[sender.tag]
        
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let hasInternet = isConnectedToInternet()
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .reward) == nil || !hasInternet)
        
        if shouldOpenDirectly {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerDataShowVC") as! SpinnerDataShowVC
            vc.coverImageURL = prank.coverImage
            vc.prankName = prank.name
            vc.prankDataURL = prank.file
            vc.prankLink = prank.link
            vc.prankShareURL = prank.shareURL
            vc.prankType = prank.type
            vc.prankImage = prank.image
            vc.sharePrank = false
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            
            self.present(vc, animated: true)
        } else {
            rewardAdUtility.showRewardedAd()
            rewardAdUtility.onRewardEarned = { [weak self] in
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerDataShowVC") as! SpinnerDataShowVC
                vc.coverImageURL = prank.coverImage
                vc.prankName = prank.name
                vc.prankDataURL = prank.file
                vc.prankLink = prank.link
                vc.prankShareURL = prank.shareURL
                vc.prankType = prank.type
                vc.prankImage = prank.image
                vc.sharePrank = false
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                
                self?.present(vc, animated: true)
            }
        }
    }
}
