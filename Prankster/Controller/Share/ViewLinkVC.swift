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
    private var noDataView: NoDataView!
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    private let adsViewModel = AdsViewModel()
    let interstitialAdUtility = InterstitialAdUtility()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAds()
        setupSwipeGesture()
        setupNoDataView()
        setupCollectionView()
        fetchPranksFromUserDefaults()
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
            
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                print("Interstitial Ad ID: \(interstitialAdID)")
                interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
            } else {
                print("No Interstitial Ad ID found")
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
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        self.view.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: navigationView.bottomAnchor),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    func fetchPranksFromUserDefaults() {
        if let savedPranksData = UserDefaults.standard.data(forKey: "SavedPranks"),
           let savedPranks = try? JSONDecoder().decode([PrankCreateData].self, from: savedPranksData) {
            self.pranks = savedPranks.sorted { $0.id > $1.id }
            noDataView.isHidden = !pranks.isEmpty
            viewlinkCollectionView.reloadData()
        } else {
            noDataView.isHidden = false
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
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil || !hasInternet)
        
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
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
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
