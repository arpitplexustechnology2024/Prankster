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

class LaunchVC: UIViewController {
    
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    //  private let adsViewModel = AdsViewModel()
    
    var passedActionKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.trackAppInstall()
        //  self.loadAds()
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
    
    //    func loadAds() {
    //        adsViewModel.fetchAds { [weak self] success in
    //            if success {
    //                print("Ads loaded successfully")
    //                let (savedNames, savedIDs) = self?.adsViewModel.getSavedAds() ?? ([], [])
    //                print("Saved Ad Names: \(savedNames)")
    //                print("Saved Ad IDs: \(savedIDs)")
    //            } else {
    //                print("Failed to load ads")
    //            }
    //        }
    //    }
}
