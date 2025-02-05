//
//  SaveRecordingPopup.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 22/11/24.
//

import UIKit

protocol SaveRecordingDelegate: AnyObject {
    func didSaveRecording(audioURL: URL, name: String)
}

class SaveRecordingPopup: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var saveRecordingPopupView: UIView!
    @IBOutlet weak var TextFiled: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var SaveButton: UIButton!
    
    weak var delegate: SaveRecordingDelegate?
    var recordedAudioURL: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print(recordedAudioURL ?? "N/A")
    }
    
    private func setupUI() {
        TextFiled.delegate = self
        TextFiled.returnKeyType = .done
        hideKeyboardTappedAround()
        saveRecordingPopupView.layer.cornerRadius = 25
        TextFiled.layer.cornerRadius = 5
        TextFiled.layer.masksToBounds = true
        cancelButton.layer.cornerRadius = cancelButton.frame.height / 2
        SaveButton.layer.cornerRadius = SaveButton.frame.height / 2
        TextFiled.placeholder = "Enter recording name"
        
        if let searchBar = TextFiled {
            let placeholderText = "Enter recording name"
            let attributes: [NSAttributedString.Key: Any] = [
                .foregroundColor: UIColor.lightGray
            ]
            searchBar.attributedPlaceholder = NSAttributedString(string: placeholderText, attributes: attributes)
        }
    }
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func btnSaveTapped(_ sender: UIButton) {
        guard let audioURL = recordedAudioURL,
              let audioName = TextFiled.text,
              !audioName.isEmpty else {
            
            let snackbar = CustomSnackbar(message: "Please enter a name for your recording.", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let newFileName = "\(audioName)_\(Date().timeIntervalSince1970).wav"
        let destinationURL = documentsDirectory.appendingPathComponent(newFileName)
        
        do {
            try FileManager.default.copyItem(at: audioURL, to: destinationURL)
            delegate?.didSaveRecording(audioURL: destinationURL, name: audioName)
            self.dismiss(animated: true)
        } catch {
            print("Error saving audio file: \(error)")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
