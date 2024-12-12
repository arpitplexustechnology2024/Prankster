//
//  SnapchatEventTracker.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 09/12/24.
//

import Foundation
import Alamofire

class SnapchatEventTracker {
    // Singleton instance for easy access
    static let shared = SnapchatEventTracker()
    
    // Configuration
    private let conversionURL = "https://tr.snapchat.com/v2/conversion/validate"
    private let appId = "6739135275"
    private let snapAppId = "ae721b65-7e0a-44a4-a03b-2e85af04f0cf"
    private let bearerToken = "eyJhbGciOiJIUzI1NiIsImtpZCI6IkNhbnZhc1MyU0hNQUNQcm9kIiwidHlwIjoiSldUIn0.eyJhdWQiOiJjYW52YXMtY2FudmFzYXBpIiwiaXNzIjoiY2FudmFzLXMyc3Rva2VuIiwibmJmIjoxNzMzOTAwNzM2LCJzdWIiOiJjMmQyMzI5OC0wYTIzLTRmZTItOTVhZi0zZjJlMDFhMjc0MmZ-UFJPRFVDVElPTn40MWE2NjEzOS0xMmRjLTQ3ODctOGFmNC1hZWIxZDk2M2VjMWEifQ.Jk9OE8MWQBznASscGif9A-hOcoVo6bE2GEcJZaERRTo"
    
    // Private initializer for singleton
    private init() {}
    
    // Click ID Storage Key
    let clickIdKey = "snapchat_click_id"
    
    // Structures for API Payloads
    struct InstallEventPayload: Codable {
        let app_id: String
        let snap_app_id: String
        let timestamp: String
        let event_type: String
        let event_conversion_type: String
        let event_tag: String
        let hashed_ip_address: String
        let user_agent: String
        let click_id: String?
    }
    
    // Handle Deep Link to Extract Click ID
    func handleSnapchatDeepLink(_ url: URL) {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        // Extract Click ID from URL parameters
        if let clickId = components?.queryItems?.first(where: { $0.name == "click_id" })?.value {
            // Store Click ID in UserDefaults
            UserDefaults.standard.set(clickId, forKey: clickIdKey)
            print("✅ Snapchat Click ID Stored: \(clickId)")
        } else {
            print("❌ No Click ID found in the Snapchat deep link")
        }
    }
    
    // Retrieve Stored Snapchat Click ID
    func retrieveSnapchatClickId() -> String? {
        let clickId = UserDefaults.standard.string(forKey: clickIdKey)
        
        if let clickId = clickId {
            print("📦 Retrieved Snapchat Click ID: \(clickId)")
        } else {
            print("❗ No Stored Click ID found")
        }
        
        return clickId
    }
    
    // Track App Install with Optional Click ID
    func trackAppInstall(
        hashedIpAddress: String,
        userAgent: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // Validate hashed IP address and user agent
        guard !hashedIpAddress.isEmpty, !userAgent.isEmpty else {
            let error = NSError(domain: "SnapchatEventTracker",
                                code: 400,
                                userInfo: [NSLocalizedDescriptionKey: "Invalid hashed IP address or user agent"])
            print("❌ Hashed IP address and user agent cannot be empty")
            completion(.failure(error))
            return
        }
        
        // Retrieve Click ID if available
        let clickId = retrieveSnapchatClickId()
        
        let timestamp = ISO8601DateFormatter().string(from: Date())
        
        // Create payload with optional click ID
        let payload = InstallEventPayload(
            app_id: appId,
            snap_app_id: snapAppId,
            timestamp: timestamp,
            event_type: "APP_INSTALL",
            event_conversion_type: "MOBILE_APP",
            event_tag: "offline",
            hashed_ip_address: hashedIpAddress,
            user_agent: userAgent,
            click_id: clickId
        )
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(bearerToken)"
        ]
        
        print("🚀 Attempting to track Snapchat install event...")
        
        AF.request(conversionURL,
                   method: .post,
                   parameters: payload,
                   encoder: JSONParameterEncoder.default,
                   headers: headers)
        .validate()
        .response { response in
            switch response.result {
            case .success:
                print("✅ Snapchat install event tracked successfully")
                
                // Optionally clear the stored click ID after successful tracking
                if clickId != nil {
                    UserDefaults.standard.removeObject(forKey: self.clickIdKey)
                    print("🧹 Cleared stored Click ID")
                }
                completion(.success(()))
                
            case .failure(let error):
                print("❌ Failed to track Snapchat install event:")
                print("Error: \(error.localizedDescription)")
                
                // Log additional details if available
                if let data = response.data, let errorResponse = String(data: data, encoding: .utf8) {
                    print("Server Response: \(errorResponse)")
                }
                
                completion(.failure(error))
            }
        }
    }
}
