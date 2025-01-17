//
//  AdsViewModel.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 17/12/24.
//

//import Foundation
//import Alamofire
//
//// MARK: - AdType Enum
//enum AdType: String {
//    case banner = "bannerAdID"
//    case interstitial = "interstitialAdID"
//    case reward = "rewardAdID"
//    case appid = "appID"
//}
//
//// MARK: - AdsViewModel
//class AdsViewModel {
//    private let apiService: AdsAPIProtocol
//    
//    init(apiService: AdsAPIProtocol = AdsAPIManger.shared) {
//        self.apiService = apiService
//    }
//    
//    // MARK: - Fetch Ads Method
//    func fetchAds(completion: @escaping (Bool) -> Void) {
//        apiService.fetchAds { [weak self] result in
//            switch result {
//            case .success(let adsResponse):
//                if adsResponse.adsStatus {
//                    let adsNames = adsResponse.data.map { $0.adsName }
//                    let adsIDs = adsResponse.data.map { $0.adsID }
//                    
//                    self?.saveAdsToUserDefaults(names: adsNames, ids: adsIDs)
//                    completion(true)
//                } else {
//                    completion(false)
//                }
//                
//            case .failure(let error):
//                print("Ads Fetch Error: \(error.localizedDescription)")
//                completion(false)
//            }
//        }
//    }
//    
//    // MARK: - UserDefaults Storage
//    private func saveAdsToUserDefaults(names: [String], ids: [String]) {
//        let defaults = UserDefaults.standard
//        
//        defaults.set(names, forKey: "savedAdsNames")
//        defaults.set(ids, forKey: "savedAdsIDs")
//        
//        for (index, name) in names.enumerated() {
//            switch name.lowercased() {
//            case "banner":
//                saveAdID(type: .banner, adID: ids[index])
//            case "intertitial":
//                saveAdID(type: .interstitial, adID: ids[index])
//            case "reward":
//                saveAdID(type: .reward, adID: ids[index])
//            case "appid":
//                saveAdID(type: .appid, adID: ids[index])
//            default:
//                break
//            }
//        }
//    }
//    
//    // MARK: - Retrieve Saved Ads
//    func getSavedAds() -> (names: [String], ids: [String]) {
//        let defaults = UserDefaults.standard
//        
//        let savedNames = defaults.stringArray(forKey: "savedAdsNames") ?? []
//        let savedIDs = defaults.stringArray(forKey: "savedAdsIDs") ?? []
//        
//        return (savedNames, savedIDs)
//    }
//    
//    // MARK: - Save Specific Ad ID for Different Ad Types
//    func saveAdID(type: AdType, adID: String) {
//        let defaults = UserDefaults.standard
//        defaults.set(adID, forKey: type.rawValue)
//    }
//    
//    // MARK: - Retrieve Specific Ad ID
//    func getAdID(type: AdType) -> String? {
//        let defaults = UserDefaults.standard
//        return defaults.string(forKey: type.rawValue)
//    }
//    
//    func removeAdsFromUserDefaults() {
//        let defaults = UserDefaults.standard
//        
//        // Remove saved names and IDs
//        defaults.removeObject(forKey: "savedAdsNames")
//        defaults.removeObject(forKey: "savedAdsIDs")
//        
//        // Remove specific ad type IDs
//        defaults.removeObject(forKey: AdType.banner.rawValue)
//        defaults.removeObject(forKey: AdType.interstitial.rawValue)
//        defaults.removeObject(forKey: AdType.reward.rawValue)
//    }
//}
