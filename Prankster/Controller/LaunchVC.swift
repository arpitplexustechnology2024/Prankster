//
//  LaunchVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import FBSDKCoreKit
import CommonCrypto
import WebKit
import FirebaseAnalytics
import GoogleMobileAds

@available(iOS 15.0, *)
class LaunchVC: UIViewController {
    
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    private var adsViewModel: AdsViewModel!
    var passedActionKey: String?
    
    init(adViewModule: AdsViewModel) {
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.trackAppInstall()
        self.loadAds()
    }
    
    private func checkNavigationFlow() {
        self.loadingActivityIndicator.stopAnimating()
        self.loadingActivityIndicator.isHidden = true
        
        if let _ = UserDefaults(suiteName: "group.com.prank.memes.fun")?.value(forKey: "incomingURL") as? String {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let viewController = storyboard.instantiateViewController(withIdentifier: "DownloaderVC") as? DownloaderVC {
                self.navigationController?.pushViewController(viewController, animated: true)
            }
        } else {
            self.loadingActivityIndicator.stopAnimating()
            self.loadingActivityIndicator.isHidden = true
            
            if let actionKey = self.passedActionKey {
                switch actionKey {
                case "AudioActionKey":
                    self.navigateToHomeVC()
                case "VideoActionKey":
                    self.navigateToHomeVC()
                case "ImageActionKey":
                    self.navigateToHomeVC()
                default:
                    self.navigateToHomeVC()
                }
            } else {
                self.navigateToHomeVC()
            }
        }
    }
    
    
    private func trackAppInstall() {
        let defaults = UserDefaults.standard
        let isFirstLaunch = !defaults.bool(forKey: "HasLaunchedBefore")
        
        if isFirstLaunch {
            Analytics.logEvent("first_Open_iOS", parameters: [
                "install_time": Date().timeIntervalSince1970,
                "ios_version": UIDevice.current.systemVersion,
                "device_model": UIDevice.current.model
            ])
            
            Analytics.setUserProperty("true", forName: "is_new_user")
            
            defaults.set(true, forKey: "HasLaunchedBefore")
            defaults.set(Date(), forKey: "InstallDate")
        }
    }
    
    func setupUI() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            launchImageView.image = UIImage(named: "LaunchBG-iPhone")
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            launchImageView.image = UIImage(named: "LaunchBG-iPad")
        }
        
        loadingActivityIndicator.style = .large
        loadingActivityIndicator.color = .black
        loadingActivityIndicator.startAnimating()
    }
    
    func navigateToHomeVC() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HomeVC") as! HomeVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func loadAds() {
        adsViewModel.fetchAds { [weak self] success in
            if !success {
                print("Ads fetch failed, using existing ads if available")
            }
            if self?.adsViewModel.shouldShowAds() == true {
                let (savedNames, savedIDs) = self?.adsViewModel.getSavedAds() ?? ([], [])
                print("Using Ads - Names: \(savedNames)")
                print("Using Ads - IDs: \(savedIDs)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.checkNavigationFlow()
                }
            } else {
                print("Ads are disabled or failed to load")
                print("Failed to load ads")
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self?.checkNavigationFlow()
                }
            }
        }
    }
}
