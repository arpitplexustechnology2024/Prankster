//
//  NativeTestAdUtility.swift
//  GoogleAds
//
//  Created by Arpit iOS Dev. on 17/01/25.
//

// MARK: - NativeMediumAdUtility.swift
import GoogleMobileAds
import UIKit

// MARK: - NativeMediumAdUtility.swift
class NativeMediumAdUtility: NSObject {
    private var loadingView: LoadingView?
    private var adLoader: GADAdLoader?
    private weak var rootViewController: UIViewController?
    private var nativeAdView: GADNativeAdView?
    private var nativeAd: GADNativeAd?
    
    var nativeAdPlaceholder: UIView
    var completion: ((Bool) -> Void)?
    
    init(adUnitID: String, rootViewController: UIViewController, nativeAdPlaceholder: UIView, completion: ((Bool) -> Void)? = nil) {
        self.nativeAdPlaceholder = nativeAdPlaceholder
        self.completion = completion
        self.rootViewController = rootViewController
        super.init()
        
        setupLoadingView()
        
        let multipleAdsOptions = GADMultipleAdsAdLoaderOptions()
        multipleAdsOptions.numberOfAds = 5
        
        adLoader = GADAdLoader(adUnitID: adUnitID,
                               rootViewController: rootViewController,
                               adTypes: [.native],
                               options: [multipleAdsOptions])
        adLoader?.delegate = self
        loadAd()
    }
    
    private func setupLoadingView() {
        loadingView = LoadingView(frame: .zero)
        nativeAdPlaceholder.addSubview(loadingView!)
        loadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loadingView!.centerXAnchor.constraint(equalTo: nativeAdPlaceholder.centerXAnchor),
            loadingView!.centerYAnchor.constraint(equalTo: nativeAdPlaceholder.centerYAnchor),
            loadingView!.widthAnchor.constraint(equalToConstant: 200),
            loadingView!.heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    private func setAdView(_ view: GADNativeAdView) {
        nativeAdView?.removeFromSuperview()
        nativeAdView = view
        nativeAdPlaceholder.addSubview(nativeAdView!)
        nativeAdView?.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            nativeAdView!.topAnchor.constraint(equalTo: nativeAdPlaceholder.topAnchor),
            nativeAdView!.leadingAnchor.constraint(equalTo: nativeAdPlaceholder.leadingAnchor),
            nativeAdView!.trailingAnchor.constraint(equalTo: nativeAdPlaceholder.trailingAnchor),
            nativeAdView!.bottomAnchor.constraint(equalTo: nativeAdPlaceholder.bottomAnchor)
        ])
    }
    
    func loadAd() {
        loadingView?.startLoading()
        let request = GADRequest()
        adLoader?.load(request)
    }
}

// MARK: - GADAdLoader Delegate Extensions
extension NativeMediumAdUtility: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
        print("Failed to receive ad with error: \(error.localizedDescription)")
        loadingView?.stopLoading()
        completion?(false)
    }
    
    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
        loadingView?.stopLoading()
        
        guard
            let nibObjects = Bundle.main.loadNibNamed("NativeMediumAdView", owner: nil, options: nil),
            let nativeAdView = nibObjects.first as? GADNativeAdView
        else {
            assert(false, "Could not load nib file for adView")
            return
        }
        
        setAdView(nativeAdView)
        nativeAd.delegate = self
        
        // Configure the native ad view
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
        
        if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
            let heightConstraint = NSLayoutConstraint(
                item: mediaView,
                attribute: .height,
                relatedBy: .equal,
                toItem: mediaView,
                attribute: .width,
                multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
                constant: 0)
            heightConstraint.isActive = true
        }
        
        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
        
        if let callToActionButton = nativeAdView.callToActionView as? UIButton {
            callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
            callToActionButton.layer.cornerRadius = 8
            callToActionButton.clipsToBounds = true
            callToActionButton.backgroundColor = .systemYellow
        }
        
        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
        
        nativeAdView.callToActionView?.isUserInteractionEnabled = false
        nativeAdView.nativeAd = nativeAd
        
        completion?(true)
    }
}

// MARK: - GADNativeAdDelegate
extension NativeMediumAdUtility: GADNativeAdDelegate {
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


//
//
//import GoogleMobileAds
//import UIKit
//
//class NativeMediumAdUtility: NSObject {
//
//    private var adLoader: GADAdLoader?
//    private weak var rootViewController: UIViewController?
//    private weak var nativeAdPlaceholder: UIView?
//    private var adUnitID: String?
//    private var nativeAdView: GADNativeAdView?
//
//    init(adUnitID: String, rootViewController: UIViewController, nativeAdPlaceholder: UIView) {
//        self.adUnitID = adUnitID
//        self.rootViewController = rootViewController
//        self.nativeAdPlaceholder = nativeAdPlaceholder
//        super.init()
//        loadAd()
//    }
//
//    func loadAd() {
//        adLoader = GADAdLoader(adUnitID: adUnitID!, rootViewController: rootViewController!,
//                               adTypes: [.native], options: nil)
//        adLoader?.delegate = self
//        adLoader?.load(GADRequest())
//    }
//
//    private func setAdView(_ view: GADNativeAdView) {
//        nativeAdView = view
//        nativeAdPlaceholder?.addSubview(nativeAdView!)
//        nativeAdView?.translatesAutoresizingMaskIntoConstraints = false
//
//        let viewDictionary = ["_nativeAdView": nativeAdView!]
//        rootViewController?.view.addConstraints(
//            NSLayoutConstraint.constraints(
//                withVisualFormat: "H:|[_nativeAdView]|",
//                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
//        )
//        rootViewController?.view.addConstraints(
//            NSLayoutConstraint.constraints(
//                withVisualFormat: "V:|[_nativeAdView]|",
//                options: NSLayoutConstraint.FormatOptions(rawValue: 0), metrics: nil, views: viewDictionary)
//        )
//    }
//}
//
//extension NativeMediumAdUtility: GADAdLoaderDelegate, GADNativeAdLoaderDelegate {
//
//    func adLoader(_ adLoader: GADAdLoader, didFailToReceiveAdWithError error: Error) {
//        print("Failed to receive ad with error: \(error.localizedDescription)")
//    }
//
//    func adLoader(_ adLoader: GADAdLoader, didReceive nativeAd: GADNativeAd) {
//        print("Received native ad: \(nativeAd)")
//
//        guard
//            let nibObjects = Bundle.main.loadNibNamed("NativeMediumAdView", owner: nil, options: nil),
//            let nativeAdView = nibObjects.first as? GADNativeAdView
//        else {
//            assert(false, "Could not load nib file for adView")
//            return
//        }
//
//        setAdView(nativeAdView)
//        nativeAd.delegate = self
//
//        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
//        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent
//
//        if let mediaView = nativeAdView.mediaView, nativeAd.mediaContent.aspectRatio > 0 {
//            let heightConstraint = NSLayoutConstraint(
//                item: mediaView,
//                attribute: .height,
//                relatedBy: .equal,
//                toItem: mediaView,
//                attribute: .width,
//                multiplier: CGFloat(1 / nativeAd.mediaContent.aspectRatio),
//                constant: 0)
//            heightConstraint.isActive = true
//        }
//
//        (nativeAdView.bodyView as? UILabel)?.text = nativeAd.body
//        nativeAdView.bodyView?.isHidden = nativeAd.body == nil
//
//        // Configure Call to Action button with corner radius
//        if let callToActionButton = nativeAdView.callToActionView as? UIButton {
//            callToActionButton.setTitle(nativeAd.callToAction, for: .normal)
//            callToActionButton.layer.cornerRadius = 8 // Set corner radius to 8 (you can adjust this value)
//            callToActionButton.clipsToBounds = true
//            // Optional: Add more button styling if needed
//            callToActionButton.backgroundColor = .systemYellow // You can customize the color
//        }
//
//        (nativeAdView.iconView as? UIImageView)?.image = nativeAd.icon?.image
//        nativeAdView.iconView?.isHidden = nativeAd.icon == nil
//
//        nativeAdView.callToActionView?.isUserInteractionEnabled = false
//        nativeAdView.nativeAd = nativeAd
//    }
//}
//
//extension NativeMediumAdUtility: GADNativeAdDelegate {
//
//    func nativeAdDidRecordClick(_ nativeAd: GADNativeAd) {
//        print("nativeAdDidRecordClick called")
//    }
//
//    func nativeAdDidRecordImpression(_ nativeAd: GADNativeAd) {
//        print("nativeAdDidRecordImpression called")
//    }
//
//    func nativeAdWillPresentScreen(_ nativeAd: GADNativeAd) {
//        print("nativeAdWillPresentScreen called")
//    }
//
//    func nativeAdWillDismissScreen(_ nativeAd: GADNativeAd) {
//        print("nativeAdWillDismissScreen called")
//    }
//
//    func nativeAdDidDismissScreen(_ nativeAd: GADNativeAd) {
//        print("nativeAdDidDismissScreen called")
//    }
//
//    func nativeAdWillLeaveApplication(_ nativeAd: GADNativeAd) {
//        print("nativeAdWillLeaveApplication called")
//    }
//}
//
//
