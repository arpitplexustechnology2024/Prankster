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

class LaunchVC: UIViewController, AppOpenAdManagerDelegate {
    
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    private let adsViewModel = AdsViewModel()
    
    var passedActionKey: String?
    var secondsRemaining: Int = 5
    var countdownTimer: Timer?
    private var isMobileAdsStartCalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.trackAppInstall()
        self.loadAds()
        
        // MARK: - App Open Ads Show
        AppOpenAdManager.shared.appOpenAdManagerDelegate = self
        startGoogleMobileAdsSDK()
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0,target: self,selector: #selector(LaunchVC.decrementCounter),userInfo: nil,repeats: true)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
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
    
    func navigateToHomeVC() {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HomeVC")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - loadAds
    func loadAds() {
        adsViewModel.fetchAds { [weak self] success in
            if success {
                print("Ads loaded successfully")
                let (savedNames, savedIDs) = self?.adsViewModel.getSavedAds() ?? ([], [])
                print("Saved Ad Names: \(savedNames)")
                print("Saved Ad IDs: \(savedIDs)")
            } else {
                print("Failed to load ads")
            }
        }
    }
    
    
    // MARK: - App Open Ads code
    @objc func decrementCounter() {
        secondsRemaining -= 1
        guard secondsRemaining <= 0 else {
            return
        }
        countdownTimer?.invalidate()
        AppOpenAdManager.shared.showAdIfAvailable()
    }
    
    private func startGoogleMobileAdsSDK() {
        DispatchQueue.main.async {
            guard !self.isMobileAdsStartCalled else { return }
            self.isMobileAdsStartCalled = true
            GADMobileAds.sharedInstance().start()
            Task {
                await AppOpenAdManager.shared.loadAd()
            }
        }
    }
    
    // MARK: AppOpenAdManagerDelegate
    func appOpenAdManagerAdDidComplete(_ appOpenAdManager: AppOpenAdManager) {
        print("App open Ads Show")
    }
}
