//
//  CoverPopupVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import UIKit

class CoverPopupVC: UIViewController {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var downloaderButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    
    typealias ButtonCallback = () -> Void
    var cameraCallback: ButtonCallback?
    var galleryCallback: ButtonCallback?
    var downloaderCallback: ButtonCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.layer.cornerRadius = 12
        self.cancelButton.layer.borderWidth = 1
        self.cancelButton.layer.borderColor = UIColor.lightGray.cgColor
        self.bgView.layer.cornerRadius = 16
    }
    
    @IBAction func btnCameraTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.cameraCallback?()
        }
    }
    
    @IBAction func btnDownaloderTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.downloaderCallback?()
        }
    }
    
    @IBAction func btnGalleryTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            self.galleryCallback?()
        }
    }
    
    @IBAction func btncanceltapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
