//
//  CoverPageAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

import Alamofire

// MARK: - EmojiAPIServiceProtocol
protocol EmojiAPIServiceProtocol {
    func fetchCoverPages(page: Int, completion: @escaping (Result<CoverPage, Error>) -> Void)
}

// MARK: - EmojiAPIService
class EmojiAPIService: EmojiAPIServiceProtocol {
    
    static let shared = EmojiAPIService()
    private init() {}
    
    func fetchCoverPages(page: Int, completion: @escaping (Result<CoverPage, Error>) -> Void) {
        let url = "https://pslink.world/api/cover/changes"
        
        let parameters: [String: Any] = [
            "page": page
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

// MARK: - RealisticAPIServiceProtocol
protocol RealisticAPIServiceProtocol {
    func fetchRealisticCoverPages(page: Int, completion: @escaping (Result<CoverPage, Error>) -> Void)
}

// MARK: - EmojiAPIService
class RealisticAPIService: RealisticAPIServiceProtocol {
    
    static let shared = RealisticAPIService()
    private init() {}
    
    func fetchRealisticCoverPages(page: Int, completion: @escaping (Result<CoverPage, any Error>) -> Void) {
        let url = "https://pslink.world/api/cover/changes"
        
        let parameters: [String: Any] = [
            "page": page
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
