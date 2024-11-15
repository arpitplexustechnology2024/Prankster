//
//  SideMenuVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

protocol SideMenuVCDelegate: AnyObject {
    func selectedMenuItem(_ index: Int)
}

class SideMenuVC: UIViewController {
    @IBOutlet weak var spinnerView: UIView!
    @IBOutlet weak var favoriteListView: UIView!
    @IBOutlet weak var viewListView: UIView!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var moreAppView: UIView!
    @IBOutlet weak var reviewView: UIView!
    @IBOutlet weak var privacyView: UIView!
    @IBOutlet weak var shareAppView: UIView!
    
    weak var delegate: SideMenuVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMenuItems()
    }
    
    private func setupMenuItems() {
        let menuItems = [spinnerView, favoriteListView, viewListView, premiumView, moreAppView, reviewView, privacyView, shareAppView]
        
        for (index, item) in menuItems.enumerated() {
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(menuItemTapped(_:)))
            item?.tag = index
            item?.addGestureRecognizer(tapGesture)
            item?.isUserInteractionEnabled = true
        }
    }
    
    @objc private func menuItemTapped(_ sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else { return }
        delegate?.selectedMenuItem(index)
    }
}
