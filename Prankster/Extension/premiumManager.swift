//
//  premiumManager.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 14/11/24.
//

import Foundation

class PremiumManager {
    static let shared = PremiumManager()
    private let defaults = UserDefaults.standard
    
    private let subscriptionActiveKey = "isSubscriptionActive"
    private let subscriptionExpirationDateKey = "subscriptionExpirationDate"
    private let subscriptionTypeKey = "subscriptionType"
    private let allUnlockedKey = "allContentUnlocked"
    
    enum SubscriptionType: String {
        case weekly = "week"
        case monthly = "month"
        case yearly = "year"
    }
    
    private var temporarilyUnlockedContent: Set<Int> = []
    
    var isSubscriptionActive: Bool {
        guard let expirationDate = defaults.object(forKey: subscriptionExpirationDateKey) as? Date else {
            return false
        }
        
        return expirationDate > Date()
    }
    
    var currentSubscriptionType: SubscriptionType? {
        guard let typeString = defaults.string(forKey: subscriptionTypeKey) else {
            return nil
        }
        return SubscriptionType(rawValue: typeString)
    }
    
    func setSubscription(expirationDate: Date, type: SubscriptionType) {
        defaults.set(true, forKey: subscriptionActiveKey)
        defaults.set(expirationDate, forKey: subscriptionExpirationDateKey)
        defaults.set(type.rawValue, forKey: subscriptionTypeKey)
    }
    
    func clearSubscription() {
        defaults.removeObject(forKey: subscriptionActiveKey)
        defaults.removeObject(forKey: subscriptionExpirationDateKey)
        defaults.removeObject(forKey: subscriptionTypeKey)
    }
    
    func isContentUnlocked(itemID: Int) -> Bool {
        if defaults.bool(forKey: allUnlockedKey) {
            return true
        }
        
        if isSubscriptionActive {
            return true
        }
        
        return temporarilyUnlockedContent.contains(itemID)
    }
    
    func temporarilyUnlockContent(itemID: Int) {
        temporarilyUnlockedContent.insert(itemID)
    }
    
    func clearTemporaryUnlocks() {
        temporarilyUnlockedContent.removeAll()
    }
    
    func checkSubscriptionStatus() {
        guard let expirationDate = defaults.object(forKey: subscriptionExpirationDateKey) as? Date else {
            return
        }
        
        if expirationDate <= Date() {
            clearSubscription()
            clearTemporaryUnlocks()
            
            NotificationCenter.default.post(name: NSNotification.Name("SubscriptionExpired"), object: nil)
        }
    }
    
    func getRemainingSubscriptionDays() -> Int? {
        guard let expirationDate = defaults.object(forKey: subscriptionExpirationDateKey) as? Date,
              let subscriptionType = currentSubscriptionType else {
            return nil
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: expirationDate)
        return components.day
    }
}
