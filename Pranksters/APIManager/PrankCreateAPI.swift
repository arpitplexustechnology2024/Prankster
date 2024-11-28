//
//  PrankCreateAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

import Foundation
import Alamofire

protocol PrankAPIProtocol {
    func createPrank(coverImage: Any, type: String, name: String, file: Any, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void )
}

class APIManager: PrankAPIProtocol {
    static let shared = APIManager()
    
    func createPrank(coverImage: Any, type: String, name: String, file: Any, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void) {
        let url = "https://pslink.world/api/prank/create"
        
        var coverImageData: Data?
        var coverImageUrlString: String?
        
        if let fileURL = coverImage as? URL, fileURL.isFileURL {
            do {
                coverImageData = try Data(contentsOf: fileURL)
            } catch {
                completion(.failure(error))
                return
            }
        } else if let urlString = coverImage as? String {
            coverImageUrlString = urlString
        }
        
        var fileData: Data?
        var fileUrlString: String?
        
        if let fileURL = file as? URL, fileURL.isFileURL {
            do {
                fileData = try Data(contentsOf: fileURL)
            } catch {
                completion(.failure(error))
                return
            }
        } else if let urlString = file as? String {
            fileUrlString = urlString
        }
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(type.data(using: .utf8)!, withName: "Type")
            
            multipartFormData.append(name.data(using: .utf8)!, withName: "Name")
            
            if let imageData = coverImageData {
                multipartFormData.append(imageData, withName: "CoverImage", fileName: "coverImage.jpg", mimeType: "image/jpeg")
            } else if let urlString = coverImageUrlString {
                multipartFormData.append(urlString.data(using: .utf8)!, withName: "CoverImage")
            }

            if let fileDataToUpload = fileData {
                multipartFormData.append(fileDataToUpload, withName: "File", fileName: "file.jpg", mimeType: "image/jpeg")
            } else if let urlString = fileUrlString {
                multipartFormData.append(urlString.data(using: .utf8)!, withName: "File")
            }
            
        }, to: url).responseDecodable(of: PrankCreateResponse.self) { response in
            switch response.result {
            case .success(let prankResponse):
                completion(.success(prankResponse))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
