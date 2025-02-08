//
//  PrankCreateAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

import Foundation
import Alamofire

protocol PrankAPIProtocol {
    func createPrank(coverImage: Data, coverImageURL: String, type: String, name: String, file: Data, fileURL: String, imageURL: String, fileType: String, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void)
    func updatePrankName(id: String, name: String, completion: @escaping (Result<PrankNameUpdate, Error>) -> Void)
}

class PrankAPIManager: PrankAPIProtocol {
    static let shared = PrankAPIManager()
    private init() {}
    
    func createPrank(coverImage: Data, coverImageURL: String, type: String, name: String, file: Data, fileURL: String, imageURL: String, fileType: String, completion: @escaping (Result<PrankCreateResponse, Error>) -> Void) {
        let url = "https://pslink.world/api/prank/create/changes"
        
        func getMimeType(for fileType: String) -> String {
            switch fileType.lowercased() {
            case "jpg", "jpeg":
                return "image/jpeg"
            case "png":
                return "image/png"
            case "mp3":
                return "audio/mpeg"
            case "mp4":
                return "video/mp4"
            default:
                return "application/octet-stream"
            }
        }
        
        func getFileName(for fileType: String) -> String {
            switch fileType.lowercased() {
            case "jpg", "jpeg":
                return "file.jpg"
            case "png":
                return "file.png"
            case "mp3":
                return "file.mp3"
            case "mp4":
                return "file.mp4"
            default:
                return "file"
            }
        }
        
        let mimeType = getMimeType(for: fileType)
        let fileName = getFileName(for: fileType)
        
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(type.data(using: .utf8)!, withName: "Type")
            multipartFormData.append(name.data(using: .utf8)!, withName: "Name")
            multipartFormData.append(coverImageURL.data(using: .utf8)!, withName: "CoverImageURL")
            multipartFormData.append(fileURL.data(using: .utf8)!, withName: "FileURL")
            multipartFormData.append(imageURL.data(using: .utf8)!, withName: "ImageURL")
            
            if coverImage.count > 0 {
                multipartFormData.append(coverImage, withName: "CoverImage", fileName: "coverImage.jpg", mimeType: "image/jpeg")
            }
            
            if file.count > 0 {
                multipartFormData.append(file, withName: "File", fileName: fileName, mimeType: mimeType)
            }
            
        }, to: url, method: .post).responseDecodable(of: PrankCreateResponse.self) { response in
            switch response.result {
            case .success(let prankResponse):
                if prankResponse.status == 1 {
                    completion(.success(prankResponse))
                } else {
                    let error = NSError(domain: "", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid status"])
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func updatePrankName(id: String, name: String, completion: @escaping (Result<PrankNameUpdate, Error>) -> Void) {
        let url = "https://pslink.world/api/prank/update/changes"
        
        let parameters: [String: String] = [
            "Id": id,
            "Name": name
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .validate()
            .responseDecodable(of: PrankNameUpdate.self) { response in
                switch response.result {
                case .success(let prankName):
                    if prankName.status == 1 {
                        completion(.success(prankName))
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
