//
//  LaunchVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import FBSDKCoreKit
import CommonCrypto

extension String {
    func sha256() -> String {
        guard let data = self.data(using: .utf8) else { return "" }
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}


class LaunchVC: UIViewController {
    
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    
    var passedActionKey: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    func trackSnapchatInstall() {
        let clickId = SnapchatEventTracker.shared.retrieveSnapchatClickId()
        
        guard let clickId = clickId, !clickId.isEmpty else {
            print("❌ Snapchat Click ID is empty. Install event tracking aborted.")
            return
        }
        
        let hashedIpAddress = "123.456.789.012".sha256()
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        
        SnapchatEventTracker.shared.trackAppInstall(hashedIpAddress: hashedIpAddress, userAgent: userAgent) { result in
            switch result {
            case .success:
                print("✅ Snapchat install event tracked successfully")
            case .failure(let error):
                print("❌ Failed to track Snapchat install event: \(error)")
            }
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
                case "MoreActionKey":
                    self.navigateToMoreAppVC(shouldNavigateToMoreApp: true)
                case "SpinnerActionKey":
                    self.navigateToSpinnerVC(shouldNavigateToSpinner: true)
                case "PrankActionKey":
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
    
    func navigateToSpinnerVC(shouldNavigateToSpinner: Bool = false) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HomeVC") as! HomeVC
        vc.shouldNavigateToSpinner = shouldNavigateToSpinner
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func navigateToMoreAppVC(shouldNavigateToMoreApp: Bool = false) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HomeVC") as! HomeVC
        vc.shouldNavigateToMoreApp = shouldNavigateToMoreApp
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
