//
//  BetterLuckVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 24/12/24.
//

import UIKit

class BetterLuckVC: UIViewController {
    
    @IBOutlet weak var betterLuckImageView: UIImageView!
    @IBOutlet weak var betterLunkLabel: UILabel!
    
    private var blurEffectView: UIVisualEffectView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBlurEffect()
        self.betterLuckImageView.layer.cornerRadius = 18
    }
    
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
}
