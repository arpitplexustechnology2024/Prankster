//
//  AppDelegate.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/12/24.
//

import UIKit
import FirebaseCore
import FirebaseAnalytics
import Firebase
import UserNotifications
import OneSignalFramework
import FBSDKCoreKit
import AppTrackingTransparency
import AdSupport
import GoogleMobileAds
import AppsFlyerLib
import Alamofire

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    private var hasCalledInstallAPI = false
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Meta Analytics
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        Settings.shared.isAutoLogAppEventsEnabled = true
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        Settings.shared.loggingBehaviors = [LoggingBehavior.appEvents,LoggingBehavior.networkRequests]
        
        // Firebase Analytics
        FirebaseApp.configure()
        Analytics.setAnalyticsCollectionEnabled(true)
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // Onesignal
        OneSignal.Debug.setLogLevel(.LL_VERBOSE)
        OneSignal.initialize("d8e64d76-dc16-444f-af2d-1bb802f7bc44", withLaunchOptions: launchOptions)
        
        // AppsFlyer
        AppsFlyerLib.shared().appsFlyerDevKey = "YwFmSnDNyUSqZNcNUJUi4H"
        AppsFlyerLib.shared().appleAppID = "6739135275"
        AppsFlyerLib.shared().isDebug = true
        
        // Wait for ATT authorization before starting AppsFlyer
        AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
        
        NotificationCenter.default.addObserver(self, selector: NSSelectorFromString("sendLaunch"), name: UIApplication.didBecomeActiveNotification, object: nil)
        // function call
        checkNotificationAuthorization()
        
        return true
    }
    
    // Updated AppsFlyer Launch Method
    @objc func sendLaunch() {
        AppsFlyerLib.shared().start(completionHandler: { (dictionary, error) in
            if let error = error {
                print("AppsFlyer Start Error: \(error)")
            } else {
                print("AppsFlyer Start Success")
                if let dict = dictionary {
                    print("AppsFlyer Start Dictionary: \(dict)")
                }
            }
        })
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Notification Authorization
    func checkNotificationAuthorization() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                self.requestNotificationPermission()
            case .denied:
                self.requestNotificationPermission()
            case .authorized:
                print("Notifications already authorized")
                self.requestTrackingPermission()
            default:
                self.requestTrackingPermission()
            }
        }
    }
    
    func requestNotificationPermission() {
        OneSignal.Notifications.requestPermission({ accepted in
            print("User accepted notifications: \(accepted)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestTrackingPermission()
            }
        }, fallbackToSettings: true)
    }
    
    // MARK: - Tracking Permission
    private func requestTrackingPermission() {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        print("Tracking authorization granted")
                    case .denied:
                        print("Tracking authorization denied")
                    case .notDetermined:
                        print("Tracking authorization not determined")
                    case .restricted:
                        print("Tracking authorization restricted")
                    @unknown default:
                        print("Tracking authorization unknown")
                    }
                }
            }
        }
    }
    
    // MARK: - Core Functionality
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .portrait
        }
        return .all
    }
    
    // MARK: - Deep Linking Methods
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerLib.shared().handleOpen(
            url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            withAnnotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        
        if let scheme = url.scheme, scheme.caseInsensitiveCompare("ShareExtension") == .orderedSame,
           let page = url.host {
            var parameters: [String: String] = [:]
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
            
            print("redirect(to: \(page), with: \(parameters))")
            
            for parameter in parameters where parameter.key.caseInsensitiveCompare("url") == .orderedSame {
                UserDefaults.standard.set(parameter.value, forKey: "incomingURL")
            }
        }
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if let url = userActivity.webpageURL {
            print("🌍 Universal Link Opened: \(url.absoluteString)")
        }
        return true
    }
    
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    // MARK: - Update Check
    func fetchAppStoreVersion(completion: @escaping (String?) -> Void) {
        let appID = "6739135275"
        let urlString = "https://itunes.apple.com/lookup?id=\(appID)"
        
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let appStoreVersion = results.first?["version"] as? String {
                    completion(appStoreVersion)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
    
    func getCurrentAppVersion() -> String? {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return version
        }
        return nil
    }
    
    func checkForUpdate() {
        fetchAppStoreVersion { appStoreVersion in
            guard let appStoreVersion = appStoreVersion,
                  let currentVersion = self.getCurrentAppVersion() else {
                return
            }
            
            if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                DispatchQueue.main.async {
                    self.promptUserToUpdate()
                }
            }
        }
    }
    
    func promptUserToUpdate() {
        let alert = UIAlertController(
            title: "New version available",
            message: "There are new features available, please update your app",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Update", style: .default, handler: { _ in
            self.openAppStoreForUpdate()
        }))
        
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(alert, animated: true, completion: nil)
        }
    }
    
    func openAppStoreForUpdate() {
        let appID = "6739135275"
        if let url = URL(string: "https://apps.apple.com/app/id\(appID)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        checkNotificationAuthorization()
        checkForUpdate()
        AppsFlyerLib.shared().start()
        Settings.shared.isAutoLogAppEventsEnabled = true
        AppOpenAdManager.shared.showAdIfAvailable()
    }
}
