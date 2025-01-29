//
//  TagAPI.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import Foundation
import Alamofire


// MARK: - SpinService Protocol
protocol TagAPIProtocol {
    func fetchTag(id: String, completion: @escaping (Result<TagName, Error>) -> Void)
}

// MARK: - Social API Manager
class TagAPIManger: TagAPIProtocol {
    static let shared = TagAPIManger()
    
    private init() {}
    
    func fetchTag(id: String, completion: @escaping (Result<TagName, Error>) -> Void) {
        let apiEndpoint = "https://pslink.world/api/cover/tagName"
        
        let parameters: [String: Any] = [
            "prankid": id
        ]
        
        AF.request(apiEndpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default)
            .responseDecodable(of: TagName.self) { response in
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
