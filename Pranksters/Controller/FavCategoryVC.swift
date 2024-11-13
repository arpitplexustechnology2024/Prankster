//
//  FavCategoryVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 23/10/24.
//

import UIKit

class FavCategoryVC: UIViewController {
    
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var audioHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    
    var passedImage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.seupViewAction()
    }
    
    func setupUI() {
        self.audioView.layer.cornerRadius = 15
        self.videoView.layer.cornerRadius = 15
        self.imageView.layer.cornerRadius = 15
        
        print("Received Data in FavCategoryVC:")
        print("Image: \(passedImage ?? "N/A")")
        print("----------------")
    }
    
    func seupViewAction() {
        let tapGestureActions: [(UIView, Selector)] = [
            (audioView, #selector(btnAudioTapped)),
            (videoView, #selector(btnVideoTapped)),
            (imageView, #selector(btnImageTapped)),
        ]
        
        tapGestureActions.forEach { view, action in
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        }
    }
    
    @objc func btnAudioTapped(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: false) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AudioVC") as! AudioVC
                vc.selectedCoverImageURL = self.passedImage
                rootViewController.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc func btnVideoTapped(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: false) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "VideoVC") as! VideoVC
                vc.selectedCoverImageURL = self.passedImage
                rootViewController.pushViewController(vc, animated: true)
            }
        }
    }
    
    @objc func btnImageTapped(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: false) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ImageVC") as! ImageVC
                vc.selectedCoverImageURL = self.passedImage
                rootViewController.pushViewController(vc, animated: true)
            }
        }
    }
}
