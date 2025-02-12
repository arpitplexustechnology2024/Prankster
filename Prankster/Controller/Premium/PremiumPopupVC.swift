//
//  PremiumPopupVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 21/11/24.
//

import UIKit
import Alamofire

class PremiumPopupVC: UIViewController {
    
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var watchAdButton: UIButton!
    @IBOutlet weak var premiumViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var premiumViewWidthConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var secoundView: UIView!
    
    let interstitialAdUtility = InterstitialAdUtility()
    private var adsViewModel: AdsViewModel!
    private var itemIDToUnlock: Int?
    
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
        self.premiumView.layer.cornerRadius = 8
        self.premiumButton.layer.cornerRadius = 5
        self.watchAdButton.layer.cornerRadius = 5
        setupTapGesture()
        if isConnectedToInternet() {
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                print("Interstitial Ad ID: \(interstitialAdID)")
                self.watchAdButton.isHidden = false
                self.firstView.isHidden = false
                self.orLabel.isHidden = false
                self.secoundView.isHidden = false
                self.premiumViewHeightConstraints.constant = 365
            } else {
                print("No Interstitial Ad ID found")
                self.watchAdButton.isHidden = true
                self.firstView.isHidden = true
                self.orLabel.isHidden = true
                self.secoundView.isHidden = true
                self.premiumViewHeightConstraints.constant = 293
            }
        }
        interstitialAdUtility.onInterstitialEarned = { [weak self] in
            if let itemID = self?.itemIDToUnlock {
                PremiumManager.shared.temporarilyUnlockContent(itemID: itemID)
                self?.dismiss(animated: true) {
                    NotificationCenter.default.post(name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
                }
            }
        }
    }
    
    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleBackgroundTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !premiumView.frame.contains(location) {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func btnPremiumTapped(_ sender: UIButton) {
        self.dismiss(animated: false) {
            let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "Premium_VC") as! Premium_VC
            premiumVC.modalPresentationStyle = .fullScreen
            premiumVC.transitioningDelegate = self
            premiumVC.premiumBack = false
            if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
                topViewController.present(premiumVC, animated: true)
            }
        }
    }
    
    @IBAction func btnWatchAdTapped(_ sender: UIButton) {
        if isConnectedToInternet() {
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    if let itemID = self?.itemIDToUnlock {
                        PremiumManager.shared.temporarilyUnlockContent(itemID: itemID)
                        self?.dismiss(animated: true) {
                            NotificationCenter.default.post(name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
                        }
                    }
                }
                interstitialAdUtility.loadAndShowAd(adUnitID: interstitialAdID, rootViewController: self)
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func setItemIDToUnlock(_ itemID: Int) {
        self.itemIDToUnlock = itemID
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
}

extension PremiumPopupVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let customPresentationController = CustomePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        customPresentationController.heightPercentage = 0.8
        return customPresentationController
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? self
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? self
        }
        return self
    }
}
