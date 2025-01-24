//
//  NativeTestAdUtility.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 17/01/25.
//

import GoogleMobileAds
import UIKit

class NativeSmallAdUtility: NSObject {
    
    private var adLoader: GADAdLoader?
    private weak var rootViewController: UIViewController?
    private weak var nativeAdPlaceholder: UIView?
    private var adUnitID: String?
    private var nativeAdView: GADNativeAdView?
    
    init(adUnitID: String, rootViewController: UIViewController, nativeAdPlaceholder: UIView) {
        self.adUnitID = adUnitID
        self.rootViewController = rootViewController
        self.nativeAdPlaceholder = nativeAdPlaceholder
        super.init()
        
        // Initially hide the ad placeholder
        nativeAdPlaceholder.isHidden = true
        
        loadAd()
    }
    
    func loadAd() {
        adLoader = GADAdLoader(adUnitID: adUnitID!, rootViewController: rootViewController!,
                               adTypes: [.native], options: nil)
        adLoader?.delegate = self
        adLoader?.load(GADRequest())
    }
    
    private func setAdView(_ view: GADNativeAdView) {
        nativeAdView = view
        nativeAdPlaceholder?.addSubview(nativeAdView!)
        nativeAdView?.translatesAutoresizingMaskIntoConstraints = false
        
        let viewDictionary = ["_nativeAdView": nativeAdView!]
        rootViewController?.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "H:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
        rootViewController?.view.addConstraints(
            NSLayoutConstraint.constraints(
                withVisualFormat: "V:|[_nativeAdView]|",
                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
        )
    }
}

extension NativeSmallAdUtility: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("Failed to receive ad with error: \(error.localizedDescription)")
        // Optionally, keep the placeholder hidden if ad loading fails
        nativeAdPlaceholder?.isHidden = true
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        print("Received native ad: \(nativeAd)")
        
        guard
            let nibObjects = Bundle.main.loadNibNamed("NativeSmallAdView", owner: nil, options: nil),
            let nativeAdView = nibObjects.first as? GADNativeAdView
        else {
            assert(false, "Could not load nib file for adView")
            return
        }
        
        setAdView(nativeAdView)
        nativeAd.delegate = self
        
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        // Configure Call to Action button with corner radius
        if let callToActionButton = nativeAdView.callToActionView as? UIButton {
            callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
            callToActionButton.layer.cornerRadius = 8
            callToActionButton.clipsToBounds = true
            callToActionButton.backgroundColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
        }
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        nativeAdView.nativeAd = nativeAd
        
        // Show the ad placeholder once the ad is loaded
        nativeAdPlaceholder?.isHidden = false
    }
}

extension NativeSmallAdUtility: GADNativeAdDelegate {
    
    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
        print("nativeAdDidRecordClick called")
    }
    
    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
        print("nativeAdDidRecordImpression called")
    }
    
    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
        print("nativeAdWillPresentScreen called")
    }
    
    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
        print("nativeAdWillDismissScreen called")
    }
    
    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
        print("nativeAdDidDismissScreen called")
    }
    
    func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
        print("nativeAdWillLeaveApplication called")
    }
}
