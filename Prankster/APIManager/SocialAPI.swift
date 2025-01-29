//
//  SocialAPI.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 27/01/25.
//

import Foundation
import Alamofire


// MARK: - SpinService Protocol
protocol SocialAPIProtocol {
    func fetchSocial(url: String, completion: @escaping (Result<Social, Error>) -> Void)
}

// MARK: - Social API Manager
class SocialAPIManger: SocialAPIProtocol {
    static let shared = SocialAPIManger()
    
    private init() {}
    
    func fetchSocial(url: String, completion: @escaping (Result<Social, Error>) -> Void) {
        let apiEndpoint = "https://pslink.world/api/social"
        
        let parameters: [String: Any] = [
            "url": url
        ]
        
        AF.request(apiEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: Social.self) { response in
                if let data = response.data, let str = String(data: data, encoding: .utf8) {
                    print("Raw response: \(str)")
                }
                
                switch response.result {
                case .success(let social):
                    completion(.success(social))
                case .failure(let error):
                    print("Error details: \(error.localizedDescription)")
                    if let data = response.data {
                        print("Response data: \(String(describing: String(data: data, encoding: .utf8)))")
                    }
                    completion(.failure(error))
                }
            }
    }
}

