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
    @IBOutlet weak var unlockAllButton: UIButton!
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
        setupUnlockAllButton()
        self.coverImageURL.text = "Cover Image :- \(selectedCoverURL ?? "N/A")"
        self.URL.text = "URL :- \(selectedURL ?? "N/A")"
        self.name.text = "Name :- \(selectedName ?? "N/A")"
    }
    
    @IBAction func back(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setupUnlockAllButton() {
        unlockAllButton.addTarget(self, action: #selector(unlockAllButtonTapped), for: .touchUpInside)
    }
    
    @objc private func unlockAllButtonTapped() {
        PremiumManager.shared.unlockAllContent()
        
        NotificationCenter.default.post(name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
        
        let snackbar = CustomSnackbar(message: "Premium access activated!", backgroundColor: .snackbar)
        snackbar.show(in: view, duration: 2.0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dismiss(animated: true)
        }
    }
}
