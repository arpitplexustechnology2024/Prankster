//
//  CoverPageViewModel.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 10/10/24.
//

import Foundation

class EmojiViewModel {
    private let apiService: EmojiAPIServiceProtocol
    private(set) var currentPage = 1
    var isLoading = false
    var emojiCoverPages: [CoverPageData] = []
    var errorMessage: String?
    var hasMorePages = true
    
    init(apiService: EmojiAPIServiceProtocol = EmojiAPIService.shared) {
        self.apiService = apiService
    }
    
    func fetchEmojiCoverPages(ispremium: String, completion: @escaping (Bool) -> Void) {
        guard !isLoading && hasMorePages else {
            completion(false)
            return
        }
        
        isLoading = true
        
        apiService.fetchCoverPages(page: currentPage, ispremium: ispremium) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let coverPageResponse):
                if coverPageResponse.data.isEmpty {
                    self.hasMorePages = false
                } else {
                    self.currentPage += 1
                    self.emojiCoverPages.append(contentsOf: coverPageResponse.data)
                }
                completion(true)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(false)
            }
        }
    }
    
    func resetPagination() {
        currentPage = 1
        emojiCoverPages.removeAll()
        hasMorePages = true
    }
}
