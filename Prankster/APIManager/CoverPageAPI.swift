//
//  CoverPageAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

import Alamofire

// MARK: - EmojiAPIServiceProtocol
protocol EmojiAPIServiceProtocol {
    func fetchCoverPages(page: Int, ispremium: String, completion: @escaping (Result<CoverPage, Error>) -> Void)
}

// MARK: - EmojiAPIService
class CoverAPIManger: EmojiAPIServiceProtocol {
    
    static let shared = CoverAPIManger()
    private init() {}
    
    func fetchCoverPages(page: Int,  ispremium: String, completion: @escaping (Result<CoverPage, Error>) -> Void) {
        let url = "https://pslink.world/api/cover/changes"
        
        let parameters: [String: Any] = [
            "page": page,
            "ispremium": ispremium
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .responseDecodable(of: CoverPage.self) { response in
                switch response.result {
                case .success(let coverPageResponse):
                    completion(.success(coverPageResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
    }
}
