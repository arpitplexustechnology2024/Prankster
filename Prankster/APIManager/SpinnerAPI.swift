//
//  SpinnerAPI.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 30/11/24.
//

import Foundation
import Alamofire

enum SpinnerError: Error {
    case betterLuckNextTime
    case noDataFound
    case typeIdRequired
    case notFound
    case unknown(String)
    
    var message: String {
        switch self {
        case .betterLuckNextTime:
            return "Better Luck Next Time"
        case .noDataFound:
            return "No data found"
        case .typeIdRequired:
            return "TypeId value is required"
        case .notFound:
            return "Not Found"
        case .unknown(let message):
            return message
        }
    }
}


// MARK: - SpinService Protocol
protocol SpinnerAPIProtocol {
    func postSpin(typeId: String, completion: @escaping (Result<SpinnerResponse, SpinnerError>) -> Void)
}

// MARK: - SpinService
class SpinnerAPIManger: SpinnerAPIProtocol {
    func postSpin(typeId: String, completion: @escaping (Result<SpinnerResponse, SpinnerError>) -> Void) {
        let url = "https://pslink.world/api/spin"
        
        let parameters: [String: String] = [
            "TypeId": typeId,
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding.default)
            .responseDecodable(of: SpinnerResponse.self) { response in
                switch response.result {
                case .success(let welcome):
                    if welcome.status == 1 {
                        completion(.success(welcome))
                    } else {
                        switch welcome.message {
                        case "Better Luck Next Time":
                            completion(.failure(.betterLuckNextTime))
                        case "No data found":
                            completion(.failure(.noDataFound))
                        case "TypeId value is required":
                            completion(.failure(.typeIdRequired))
                        case "Not Found":
                            completion(.failure(.notFound))
                        default:
                            completion(.failure(.unknown(welcome.message)))
                        }
                    }
                case .failure(let error):
                    completion(.failure(.unknown(error.localizedDescription)))
                }
            }
    }
}
