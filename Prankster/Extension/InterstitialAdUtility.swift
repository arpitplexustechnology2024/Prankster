//
//  InterstitialAdUtility.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 01/07/24.
//

import GoogleMobileAds
import UIKit

class InterstitialAdUtility: NSObject, GADFullScreenContentDelegate {
    
    private var interstitialAd: GADInterstitialAd?
    private weak var rootViewController: UIViewController?
    private var adUnitID: String?
    
    var onInterstitialEarned: (() -> Void)?
    
    func loadInterstitialAd(adUnitID: String, rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        self.adUnitID = adUnitID
        GADInterstitialAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            if let error = error {
                print("Rewarded ad failed to load with error: \(error.localizedDescription)")
                self?.onInterstitialEarned?()
                return
            }
            self?.interstitialAd = ad
            self?.interstitialAd?.fullScreenContentDelegate = self
            print("Interstitial ad loaded.")
        }
    }
    
    func showInterstitialAd() {
        guard let interstitialAd = interstitialAd, let rootViewController = rootViewController else {
            print("Ad wasn't ready.")
            self.onInterstitialEarned?()
            return
        }
        interstitialAd.present(fromRootViewController: rootViewController)
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content: \(error.localizedDescription)")
        if let adUnitID = adUnitID {
            loadInterstitialAd(adUnitID: adUnitID, rootViewController: rootViewController!)
            self.onInterstitialEarned?()
        }
    }
    
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad will present full screen content.")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        if let adUnitID = adUnitID {
            loadInterstitialAd(adUnitID: adUnitID, rootViewController: rootViewController!)
            self.onInterstitialEarned?()
        }
    }
}
