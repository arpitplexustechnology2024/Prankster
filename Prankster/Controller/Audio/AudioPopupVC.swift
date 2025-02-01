//
//  AudioPopupVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 30/01/25.
//


import UIKit

class AudioPopupVC: UIViewController {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var recorderButton: UIButton!
    @IBOutlet weak var mediaPlayerButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    typealias ButtonCallback = () -> Void
    var recorderCallback: ButtonCallback?
    var mediaplayerCallback: ButtonCallback?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.layer.cornerRadius = 12
        self.cancelButton.layer.borderWidth = 1
        self.cancelButton.layer.borderColor = UIColor.lightGray.cgColor
        self.bgView.layer.cornerRadius = 16
    }
    
    @IBAction func btnRecorderTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.recorderCallback?()
        }
    }
    
    @IBAction func btnmediaPlayerTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.mediaplayerCallback?()
        }
    }
    
    @IBAction func btncanceltapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
