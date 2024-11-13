//
//  LaunchVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

class LaunchVC: UIViewController {
    
    @IBOutlet weak var launchImageView: UIImageView!
    @IBOutlet weak var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var refreshButton: UIButton!
    
    let viewModel = RegistrationViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.registerUserIfNeeded()
    }
    
    func registerUserIfNeeded() {
        self.refreshButton.isHidden = true
        self.loadingActivityIndicator.isHidden = false
        self.loadingActivityIndicator.startAnimating()
        
        viewModel.registerUserIfNeeded { [weak self] success in
            guard let self = self else { return }
            
            if success {
                if let response = self.viewModel.registrationResponse {
                    if response.status == 1 {
                        print("\(response.message)")
                        print("User Token :- \(response.token)")
                        
                        self.proceedToMainView()
                    } else {
                        self.handleFailure()
                    }
                }
            } else {
                if let errorMessage = self.viewModel.errorMessage {
                    print("Error: \(errorMessage)")
                    self.handleFailure()
                } else {
                    print("User is already registered, skipping API call.")
                    self.proceedToMainView()
                }
            }
        }
    }
    
    func handleFailure() {
        self.loadingActivityIndicator.stopAnimating()
        self.loadingActivityIndicator.isHidden = true
        self.refreshButton.isHidden = false
        print("API call failed or status is not 1")
    }
    
    @IBAction func refreshButtonTapped(_ sender: UIButton) {
        self.refreshButton.isHidden = true
        self.loadingActivityIndicator.isHidden = false
        self.loadingActivityIndicator.startAnimating()
        
        DispatchQueue.main.async {
            self.registerUserIfNeeded()
        }
    }
    
    func proceedToMainView() {
        Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { _ in
            self.loadingActivityIndicator.stopAnimating()
            self.loadingActivityIndicator.isHidden = true
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainVC") as! MainVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func setupUI() {
        if UIDevice.current.userInterfaceIdiom == .phone {
            launchImageView.image = UIImage(named: "LaunchBG-iPhone")
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            launchImageView.image = UIImage(named: "LaunchBG-iPad")
        }
        
        loadingActivityIndicator.style = .large
        loadingActivityIndicator.color = .black
        loadingActivityIndicator.hidesWhenStopped = true
    }
}
