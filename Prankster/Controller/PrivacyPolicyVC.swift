//
//  PrivacyPolicyVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 13/12/24.
//

import UIKit
import WebKit

class PrivacyPolicyVC: UIViewController {
    
    @IBOutlet weak var privacyPolicyWebView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        if let url = URL(string: "https://pslink.world/privacy-policy") {
            let request = URLRequest(url: url)
            privacyPolicyWebView.load(request)
        }
    }
}
