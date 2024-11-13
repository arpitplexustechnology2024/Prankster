//
//  HomeVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

enum CoverViewType {
    case audio
    case video
    case image
}

class HomeVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var moreAppView: UIView!
    @IBOutlet weak var sideMenuButton: UIButton!
    @IBOutlet weak var spinerButton: UIButton!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var premiumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreAppHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.seupViewAction()
        self.navigationbarView.addBottomShadow()
    }
    
    func setupUI() {
        self.audioView.layer.cornerRadius = 15
        self.videoView.layer.cornerRadius = 15
        self.imageView.layer.cornerRadius = 15
        self.premiumView.layer.cornerRadius = 15
        self.moreAppView.layer.cornerRadius = 15
        
        if let revealVC = self.revealViewController() {
            self.sideMenuButton.addTarget(revealVC, action: #selector(revealVC.revealSideMenu), for: .touchUpInside)
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollViewHeightConstraint.constant = 810
            audioHeightConstraint.constant = 140
            videoHeightConstraint.constant = 140
            imageHeightConstraint.constant = 140
            premiumHeightConstraint.constant = 140
            moreAppHeightConstraint.constant = 140
        } else {
            scrollViewHeightConstraint.constant = 730
            audioHeightConstraint.constant = 120
            videoHeightConstraint.constant = 120
            imageHeightConstraint.constant = 120
            premiumHeightConstraint.constant = 120
            moreAppHeightConstraint.constant = 120
        }
        self.view.layoutIfNeeded()
    }
    
    func seupViewAction() {
        let tapGestureActions: [(UIView, Selector)] = [
            (audioView, #selector(btnAudioTapped)),
            (videoView, #selector(btnVideoTapped)),
            (imageView, #selector(btnImageTapped)),
            (premiumView, #selector(btnPremiumTapped)),
            (moreAppView, #selector(btnMoreAppTapped)),
        ]
        
        tapGestureActions.forEach { view, action in
            view.isUserInteractionEnabled = true
            view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        }
    }
    
    @objc func btnAudioTapped(_ sender: UITapGestureRecognizer){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
        vc.viewType = .audio
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func btnVideoTapped(_ sender: UITapGestureRecognizer){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
        vc.viewType = .video
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func btnImageTapped(_ sender: UITapGestureRecognizer){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
        vc.viewType = .image
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func btnPremiumTapped(_ sender: UITapGestureRecognizer){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PremiumVC") as! PremiumVC
        self.present(vc, animated: true)
    }
    
    @objc func btnMoreAppTapped(_ sender: UITapGestureRecognizer){
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MoreAppVC") as! MoreAppVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
