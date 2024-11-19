//
//  AudioCharacterAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 17/10/24.
//

import Alamofire
import UIKit

// MARK: - API Protocols
protocol CharacterAPIServiceProtocol {
    func fetchCharacters(categoryId: Int, completion: @escaping (Result<CoverPage, Error>) -> Void)
}

// MARK: - Character API Service
class CharacterAPIService: CharacterAPIServiceProtocol {
    static let shared = CharacterAPIService()
    private init() {}
    
    func fetchCharacters(categoryId: Int, completion: @escaping (Result<CoverPage, Error>) -> Void) {
        let url = "https://pslink.world/api/character"
        
        let parameters: [String: Any] = [
            "CategoryId": categoryId
        ]
        
        AF.request(url,
                   method: .post,
                   parameters: parameters,
                   encoding: URLEncoding.default)
        .validate()
        .responseDecodable(of: CoverPage.self) { response in
            switch response.result {
            case .success(let characterResponse):
                if characterResponse.status == 1 {
                    completion(.success(characterResponse))
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
