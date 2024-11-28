//
//  PrankCreateViewModel.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

    import Foundation
    import UIKit

    class ShareLinkViewModel {
        private let apiManager: PrankAPIProtocol
        
        init(apiManager: PrankAPIProtocol = APIManager.shared) {
            self.apiManager = apiManager
        }
        
        func createPrank(coverImage: Any, type: String, name: String, file: Any, completion: @escaping (Result<PrankCreateResponse, Error>) ->  Void) {
            apiManager.createPrank(coverImage: coverImage, type: type, name: name, file: file, completion: completion)
        }
    }
