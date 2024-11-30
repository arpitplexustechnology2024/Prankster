//
//  PrankCreateAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

import Foundation
import Alamofire

protocol PrankAPIProtocol {
    func createPrank(coverImage: Data, coverImageURL: String, type: String, name: String, file: Data, fileURL: String, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void)
}

class APIManager: PrankAPIProtocol {
    static let shared = APIManager()
    
    func createPrank(coverImage: Data, coverImageURL: String, type: String, name: String, file: Data, fileURL: String, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void) {
        let url = "https://pslink.world/api/prank/create"
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(type.data(using: .utf8)!, withName: "Type")
            
            multipartFormData.append(name.data(using: .utf8)!, withName: "Name")
            
            multipartFormData.append(coverImageURL.data(using: .utf8)!, withName: "CoverImageURL")
            
            multipartFormData.append(fileURL.data(using: .utf8)!, withName: "FileURL")
            
            multipartFormData.append(coverImage, withName: "File", fileName: "coverImage.jpg", mimeType: "image/jpeg")
            
            multipartFormData.append(file, withName: "File", fileName: "file.jpg", mimeType: "image/jpeg")
            
        }, to: url, method: .post).responseDecodable(of: PrankCreateResponse.self) { response in
            switch response.result {
            case .success(let prankResponse):
                completion(.success(prankResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
