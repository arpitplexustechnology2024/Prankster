//
//  RewardAdUtility.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 01/07/24.
//

import UIKit
import GoogleMobileAds

class RewardAdUtility: NSObject, GADFullScreenContentDelegate {
    
    private var rewardedAd: GADRewardedAd?
    private weak var rootViewController: UIViewController?
    private var adUnitID: String?
    private var loadingView: LoadingAlertView?
    
    var onRewardEarned: (() -> Void)?
    
    func loadRewardedAd(adUnitID: String, rootViewController: UIViewController) {
        self.rootViewController = rootViewController
        self.adUnitID = adUnitID
        
        loadingView = LoadingAlertView(frame: rootViewController.view.bounds)
        if let loadingView = loadingView {
            rootViewController.view.addSubview(loadingView)
            loadingView.startAnimating()
        }
        
        GADRewardedAd.load(withAdUnitID: adUnitID, request: GADRequest()) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.loadingView?.removeFromSuperview()
                self?.loadingView = nil
            }
            
            if let error = error {
                print("Rewarded ad failed to load with error: \(error.localizedDescription)")
                self?.onRewardEarned?()
                return
            }
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            print("Rewarded ad loaded.")
            
            if let rootVC = self?.rootViewController {
                self?.rewardedAd?.present(fromRootViewController: rootVC) { [weak self] in
                    print("User earned reward")
                    self?.onRewardEarned?()
                }
            }
        }
    }
    
    // MARK: - GADFullScreenContentDelegate
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Ad did fail to present full screen content: \(error.localizedDescription)")
        self.onRewardEarned?()
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("Ad did dismiss full screen content.")
        self.onRewardEarned?()
    }
}
