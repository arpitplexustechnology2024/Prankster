//
//  PremiumVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

class PremiumVC: UIViewController {
    
    var selectedImageURL: String?
    var selectedImageName: String?
    
    var selectedAudioURL: String?
    var selectedAudioName: String?
    
    var selectedCoverImageURL: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let imageURL = selectedImageURL, let coverImageURL = selectedCoverImageURL, let imageName = selectedImageName {
            print("=== Received Data in Next ViewController ===")
            print("Cover Image URL: \(coverImageURL)")
            print("Image URL: \(imageURL)")
            print("Image Name: \(imageName)")
            print("=========================================")
        }
        
        if let audioFile = selectedAudioURL, let coverImageURL = selectedCoverImageURL, let imageName = selectedAudioName {
            print("=== Received Data in Next ViewController ===")
            print("Cover Image URL: \(coverImageURL)")
            print("Audio File: \(audioFile)")
            print("Audiio Name: \(imageName)")
            print("=========================================")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.revealViewController()?.gestureEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController()?.gestureEnabled = true
    }
    
}
