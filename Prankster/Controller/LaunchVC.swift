//
//  LaunchVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
//import AppTrackingTransparency
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
        trackSnapchatInstall()
    }
    
    //    override func viewDidAppear(_ animated: Bool) {
    //        super.viewDidAppear(animated)
    //
    //        if #available(iOS 14, *) {
    //            ATTrackingManager.requestTrackingAuthorization { status in
    //                switch status {
    //                case .authorized:
    //                    AppEvents.shared.logEvent(AppEvents.Name("fb_mobile_first_app_launch"))
    //                default:
    //                    break
    //                }
    //            }
    //        }
    //    }
    
    func trackSnapchatInstall() {
        // Retrieve Click ID from storage
        let storedClickId = SnapchatEventTracker.shared.retrieveSnapchatClickId()

        // Generate a realistic default Click ID if no stored Click ID exists
        let generatedDefaultClickId = generateDefaultClickId()
        let clickIdToUse = storedClickId ?? generatedDefaultClickId

        // Check if the Click ID to use is valid (non-empty)
        guard !clickIdToUse.isEmpty else {
            print("❌ Snapchat Click ID is empty even after using default. Install event tracking aborted.")
            return
        }

        // Fetch the public IP address
        fetchPublicIPAddress { ipAddress in
            guard let ipAddress = ipAddress else {
                print("❌ Unable to fetch public IP address. Install event tracking aborted.")
                return
            }

            // Hash the IP address
            let hashedIpAddress = ipAddress.sha256()
            let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"

            // Store the generated default Click ID if no stored one exists
            if storedClickId == nil {
                UserDefaults.standard.set(generatedDefaultClickId, forKey: SnapchatEventTracker.shared.clickIdKey)
                print("📥 Generated Default Click ID stored: \(generatedDefaultClickId)")
            }

            // Call the tracking function
            SnapchatEventTracker.shared.trackAppInstall(hashedIpAddress: hashedIpAddress, userAgent: userAgent) { result in
                switch result {
                case .success:
                    print("✅ Snapchat install event tracked successfully")
                case .failure(let error):
                    print("❌ Failed to track Snapchat install event: \(error)")
                }
            }
        }
    }

    // Function to fetch the public IP address
    private func fetchPublicIPAddress(completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.ipify.org?format=json")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("❌ Error fetching IP address: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
                return
            }

            if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let ipAddress = json["ip"] as? String {
                completion(ipAddress)
            } else {
                print("❌ Error parsing IP address from response.")
                completion(nil)
            }
        }
        task.resume()
    }

    // Function to generate a realistic Snapchat Click ID
    private func generateDefaultClickId() -> String {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        let randomSuffix = Int.random(in: 1000...9999)
        return "\(uuid)_\(randomSuffix)"
    }
    
//    // Updated function to track Snapchat install
//    func trackSnapchatInstall() {
//        // Retrieve Click ID
//        let clickId = SnapchatEventTracker.shared.retrieveSnapchatClickId()
//        
//        // Check if Click ID exists
//        guard let clickId = clickId, !clickId.isEmpty else {
//            print("❌ Snapchat Click ID is empty. Install event tracking aborted.")
//            return
//        }
//        
//        // Example hashed IP address and user agent (replace with real values)
//        let hashedIpAddress = "123.456.789.012".sha256()
//        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
//        
//        SnapchatEventTracker.shared.trackAppInstall(hashedIpAddress: hashedIpAddress, userAgent: userAgent) { result in
//            switch result {
//            case .success:
//                print("✅ Snapchat install event tracked successfully")
//            case .failure(let error):
//                print("❌ Failed to track Snapchat install event: \(error)")
//            }
//        }
//    }

    
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
