//
//  SnapchatEventTracker.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 09/12/24.
//

import Foundation
import Alamofire
import CommonCrypto

class SnapchatAPIManager {
    static let shared = SnapchatAPIManager()
    
    private let apiURL = "https://tr.snapchat.com/v2/conversion/"
    private let appID = "6739135275"
    private let snapAppID = "ae721b65-7e0a-44a4-a03b-2e85af04f0cf"
    private let bearerToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzMzOTAwNzM2LCJzdWIiOiJjMmQyMzI5OC0wYTIzLTRmZTItOTVhZi0zZjJlMDFhMjc0MmZ-UFJPRFVDVElPTn40MWE2NjEzOS0xMmRjLTQ3ODctOGFmNC1hZWIxZDk2M2VjMWEifQ.Jk9OE8MWQBznASscGif9A-hOcoVo6bE2GEcJZaERRTo"
    
    func sendConversionEvent(clickID: String, userAgent: String, userIPAddress: String, completion: @escaping (Bool, String?) -> Void) {
        let parameters: [String: Any] = [
            "app_id": appID,
            "snap_app_id": snapAppID,
            "timestamp": Int(Date().timeIntervalSince1970),
            "event_type": "APP_INSTALL",
            "event_conversion_type": "MOBILE_APP",
            "event_tag": "offline",
            "hashed_ip_address": userIPAddress,
            "user_agent": userAgent,
            "click_id": clickID
        ]
        
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(bearerToken)",
            "Content-Type": "application/json"
        ]
        
        AF.request(apiURL, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .response { response in
                if let error = response.error {
                    completion(false, error.localizedDescription)
                } else {
                    completion(true, nil)
                }
            }
    }
}


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
