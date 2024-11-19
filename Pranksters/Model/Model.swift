//
//  Model.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

// MARK: - CoverPage
struct CoverPage: Codable {
    let status: Int
    let message: String
    let data: [CoverPageData]
}
struct CoverPageData: Codable {
    let coverURL: String
    let coverPremium: Bool
    let itemID: Int
    let hide: Bool

    enum CodingKeys: String, CodingKey {
        case coverURL = "CoverURL"
        case coverPremium = "CoverPremium"
        case itemID = "ItemId"
        case hide = "Hide"
    }
}

// MARK: - CharacterAllResponse
struct CharacterAllResponse: Codable {
    let status: Int
    let message: String
    let data: [CharacterAllData]
}
struct CharacterAllData: Codable {
    let file: String?
    let name: String
    let image: String
    let premium: Bool
    let itemID: Int
    var isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case file = "File"
        case name = "Name"
        case image = "Image"
        case premium = "Premium"
        case itemID = "ItemId"
        case isFavorite
    }
}

// MARK: - MoreApp
struct MoreApp: Codable {
    let status: Int
    let message: String
    let data: [MoreData]
}
struct MoreData: Codable {
    let appName: String
    let logo: String
    let appID, packageName: String
    
    enum CodingKeys: String, CodingKey {
        case appName, logo
        case appID = "appId"
        case packageName
    }
}

