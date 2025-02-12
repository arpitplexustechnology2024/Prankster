//
//  SharePrankPopupVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 07/02/25.
//

import UIKit
import Alamofire

class SharePrankPopupVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var savePrankNamePopupView: UIView!
    @IBOutlet weak var TextFiled: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var SaveButton: UIButton!
    
    var currentPrankName: String?
    var onSave: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        
        TextFiled.text = currentPrankName
    }
    
    private func setupUI() {
        TextFiled.delegate = self
        TextFiled.returnKeyType = .done
        hideKeyboardTappedAround()
        savePrankNamePopupView.layer.cornerRadius = 25
        TextFiled.layer.cornerRadius = 5
        TextFiled.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = cancelButton.frame.height / 2
        SaveButton.layer.cornerRadius = SaveButton.frame.height / 2
        TextFiled.placeholder = "Enter prank name"
        
        if let searchBar = TextFiled {
            let placeholderText = "Enter prank name"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
    }
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        guard let newName = TextFiled.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !newName.isEmpty else {
            let snackbar = CustomSnackbar(message: "Please enter a name!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        if !isConnectedToInternet() {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        onSave?(newName)
        dismiss(animated: true)
    }
}
