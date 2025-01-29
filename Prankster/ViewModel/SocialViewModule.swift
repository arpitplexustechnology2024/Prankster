//
//  SocialViewModule.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 27/01/25.
//

import Alamofire

// MARK: - View Module
class SocialViewModule {
    private let apiService: SocialAPIProtocol
    
    init(apiService: SocialAPIProtocol) {
        self.apiService = apiService
    }
    
    func fetchSocial(url: String, completion: @escaping (Result<Social, Error>) -> Void) {
        apiService.fetchSocial(url: url) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let socialResponse):
                    completion(.success(socialResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
