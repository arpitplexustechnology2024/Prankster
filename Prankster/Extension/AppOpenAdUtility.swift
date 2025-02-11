//
//  AppOpenAdUtility.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 24/01/25.
//

import UIKit
import GoogleMobileAds

//MARK: - AppOpenAdManagerDelegate
protocol AppOpenAdManagerDelegate: AnyObject {
    func appOpenAdManagerAdDidComplete(_ appOpenAdManager: AppOpenAdManager)
}

//MARK: - AppOpenAdManager
class AppOpenAdManager: NSObject {
    let timeoutInterval: TimeInterval = 4 * 3_600
    var appOpenAd: GADAppOpenAd?
    weak var appOpenAdManagerDelegate: AppOpenAdManagerDelegate?
    var isLoadingAd = false
    var isShowingAd = false
    var loadTime: Date?
    private let adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    
    static var shared = AppOpenAdManager()
    
    private func wasLoadTimeLessThanNHoursAgo(timeoutInterval: TimeInterval) -> Bool {
        if let loadTime = loadTime {
            return Date().timeIntervalSince(loadTime) < timeoutInterval
        }
        return false
    }
    
    private func isAdAvailable() -> Bool {
        return appOpenAd != nil && wasLoadTimeLessThanNHoursAgo(timeoutInterval: timeoutInterval)
    }
    
    private func appOpenAdManagerAdDidComplete() {
        
        appOpenAdManagerDelegate?.appOpenAdManagerAdDidComplete(self)
    }
    
    func loadAd() async {
        
        if isLoadingAd || isAdAvailable() {
            return
        }
        isLoadingAd = true
        
        print("Start loading app open ad.")
        
        do {
            if let appopenAdID = adsViewModel.getAdID(type: .appopen) {
                print("Appopen Ad ID: \(appopenAdID)")
                appOpenAd = try await GADAppOpenAd.load(
                    withAdUnitID: appopenAdID, request: GADRequest())
                appOpenAd?.fullScreenContentDelegate = self
                loadTime = Date()
            } else {
                print("No Appopen Ad ID found")
            }
        } catch {
            appOpenAd = nil
            loadTime = nil
            print("App open ad failed to load with error: \(error.localizedDescription)")
        }
        isLoadingAd = false
    }
    
    func showAdIfAvailable() {
        if isShowingAd {
            print("App open ad is already showing.")
            return
        }
        
        
        if !isAdAvailable() {
            print("App open ad is not ready yet.")
            appOpenAdManagerAdDidComplete()
                Task {
                    await loadAd()
                }
            return
        }
        if let ad = appOpenAd {
            print("App open ad will be displayed.")
            isShowingAd = true
            ad.present(fromRootViewController: nil)
        }
    }
}

extension AppOpenAdManager: GADFullScreenContentDelegate {
    func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        print("App open ad is will be presented.")
    }
    
    func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
        appOpenAd = nil
        isShowingAd = false
        print("App open ad was dismissed.")
        appOpenAdManagerAdDidComplete()
        Task {
            await loadAd()
        }
    }
    
    func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        appOpenAd = nil
        isShowingAd = false
        print("App open ad failed to present with error: \(error.localizedDescription)")
        appOpenAdManagerAdDidComplete()
        Task {
            await loadAd()
        }
    }
}
