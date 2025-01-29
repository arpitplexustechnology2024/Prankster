//
//  TagViewModel.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import Alamofire

// MARK: - View Module
class TagViewModule {
    private let apiService: TagAPIProtocol
    
    init(apiService: TagAPIProtocol) {
        self.apiService = apiService
    }
    
    func fetchTag(id: String, completion: @escaping (Result<TagName, Error>) -> Void) {
        apiService.fetchTag(id: id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tagResponse):
                    completion(.success(tagResponse))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
