//
//  SceneDelegate.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/12/24.
//

import UIKit
import FBSDKCoreKit

@available(iOS 15.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    enum ActionType: String {
        case audioAction   = "AudioAction"
        case videoAction   = "VideoAction"
        case imageAction   = "ImageAction"
    }
    
    var window: UIWindow?
    var savedShortCutItem: UIApplicationShortcutItem!
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let shortcutItem = connectionOptions.shortcutItem {
            savedShortCutItem = shortcutItem
        }
        guard let _ = (scene as? UIWindowScene) else { return }
        if let url = connectionOptions.urlContexts.first?.url {
            handleIncomingURL(url)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        print("Universal Link Opened: \(url)")
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
           let queryItems = components.queryItems {
            for item in queryItems {
                if item.name == "source" {
                    let source = item.value ?? "organic"
                    print("Source ID: \(source)")
                    
                    if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
                        appDelegate.sendInstallAPI(source: source)
                        print("APi call success")
                    }
                }
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }
        if let url = URLContexts.first?.url {
            handleIncomingURL(url)
        }
        ApplicationDelegate.shared.application(UIApplication.shared, open: url, sourceApplication: nil, annotation: [UIApplication.OpenURLOptionsKey.annotation])
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {}
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if savedShortCutItem != nil {
            _ = handleShortCutItem(shortcutItem: savedShortCutItem)
            savedShortCutItem = nil
        }
        // Call checkForUpdate when the scene becomes active
        (UIApplication.shared.delegate as? AppDelegate)?.checkForUpdate()
    }
    
    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handled = handleShortCutItem(shortcutItem: shortcutItem)
        completionHandler(handled)
    }
    
    func sceneWillResignActive(_ scene: UIScene) {}
    
    func sceneWillEnterForeground(_ scene: UIScene) {}
    
    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        if let actionTypeValue = ActionType(rawValue: shortcutItem.type) {
            switch actionTypeValue {
            case .audioAction:
                self.navigateToLaunchVC(actionKey: "AudioActionKey")
            case .videoAction:
                self.navigateToLaunchVC(actionKey: "VideoActionKey")
            case .imageAction:
                self.navigateToLaunchVC(actionKey: "ImageActionKey")
            }
        }
        return true
    }
    
    func navigateToLaunchVC(actionKey: String) {
        if let navVC = window?.rootViewController as? UINavigationController,
           let launchVC = navVC.viewControllers.first as? LaunchVC {
            launchVC.passedActionKey = actionKey
        }
    }
    
    func handleIncomingURL(_ url: URL) {
        if let scheme = url.scheme,
           scheme.caseInsensitiveCompare("ShareExtension") == .orderedSame,
           let page = url.host {
            
            var parameters: [String: String] = [:]
            URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach {
                parameters[$0.name] = $0.value
            }
            
            print("redirect(to: \(page), with: \(parameters))")
            
            for parameter in parameters where parameter.key.caseInsensitiveCompare("url") == .orderedSame {
                UserDefaults().set(parameter.value, forKey: "incomingURL")
            }
        }
    }
}
