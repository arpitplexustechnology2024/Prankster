//
//  PremiumVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

class PremiumVC: UIViewController {
    
    var selectedURL: String?
    var selectedName: String?
    var selectedCoverURL: String?
    
    @IBOutlet weak var coverImageURL: UILabel!
    @IBOutlet weak var URL: UILabel!
    @IBOutlet weak var name: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let imageURL = selectedURL, let coverImageURL = selectedCoverURL, let imageName = selectedName {
            print("=== Received Data in Next ViewController ===")
            print("Cover Image URL: \(coverImageURL)")
            print("Image URL: \(imageURL)")
            print("Image Name: \(imageName)")
            print("=========================================")
        }
        
        self.coverImageURL.text = "Cover Image :- \(selectedCoverURL ?? "N/A")"
        self.URL.text = "URL :- \(selectedURL ?? "N/A")"
        self.name.text = "Name :- \(selectedName ?? "N/A")"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.revealViewController()?.gestureEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController()?.gestureEnabled = true
    }
    
    
    @IBAction func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
