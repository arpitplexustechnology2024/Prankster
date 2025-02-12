//
//  InterstitialAdUtility.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 01/07/24.
//

import GoogleMobileAds
import UIKit

// InterstitialAdUtility class માં નીચેના ફેરફારો કરો:
class InterstitialAdUtility: NSObject, GADFullScreenContentDelegate {
    private var interstitialAd: GADInterstitialAd?
    private weak var rootViewController: UIViewController?
    private var adUnitID: String?
    private var loadingView: LoadingAlertView?
    
    var onInterstitialEarned: (() -> Void)?
    
    func loadAndShowAd(adUnitID: String, rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        self.adUnitID = adUnitID
        
        // Show loading view
        loadingView = LoadingAlertView(frame: rootViewController.view.bounds)
        if let loadingView = loadingView {
            rootViewController.view.addSubview(loadingView)
            loadingView.startAnimating()
        }
        
        // Load the ad
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            // Hide loading view
            DispatchQueue.main.async {
                self?.loadingView?.removeFromSuperview()
                self?.loadingView = nil
            }
            
            if let error = error {
                print("Rewarded ad failed to load with error: \(error.localizedDescription)")
                self?.onInterstitialEarned?()
                return
            }
            
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            
            // Show the ad immediately after loading
            if let rootVC = self?.rootViewController {
                self?.interstitialAd?.present(fromRootViewController: rootVC)
            }
        }
    }
    
    // Remove the old showInterstitialAd function as we don't need it anymore
    
    // Update delegate methods
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content: \(error.localizedDescription)")
        self.onInterstitialEarned?()
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        self.onInterstitialEarned?()
    }
}
