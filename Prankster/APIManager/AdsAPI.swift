//
//  AdsAPI.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 17/12/24.
//

import Foundation
import Alamofire

// MARK: - SpinService Protocol
protocol AdsAPIProtocol {
    func fetchAds(completion: @escaping (Result<AdsResponse, Error>) -> Void)
}

// MARK: - AdsAPIManger
class AdsAPIManger: AdsAPIProtocol {
    static let shared = AdsAPIManger()
    private init() {}
    
    func fetchAds(completion: @escaping (Result<AdsResponse, Error>) -> Void) {
        let url = "https://pslink.world/api/ads"
        
        AF.request(url, method: .post)
            .validate()
            .responseDecodable(of: AdsResponse.self) { response in
                switch response.result {
                case .success(let adsResponse):
                    if adsResponse.status == 1 {
                        completion(.success(adsResponse))
                    } else {
                        let error = NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid status"])
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
