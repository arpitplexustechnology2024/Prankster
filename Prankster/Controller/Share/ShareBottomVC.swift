//
//  ShareBottomVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/12/24.
//

import UIKit

class ShareBottomVC: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var NextButton: UIButton!
    
    // MARK: - Properties
    private let stackView = UIStackView()
    private var numberLabels: [UILabel] = []
    private var pageNumbers: [String] = []
    
    let instaGIF = ["Insta1", "Insta2", "Insta3", "Insta4"]
    let snapGIF = ["Snap1", "Snap2", "Snap3", "Snap4", "Snap5"]
    
    var currentPage = 0
    var coverImageURL: String?
    var prankLink: String?
    var prankName: String?
    var sharePrank: String?
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.color = .black
        return indicator
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPageControl()
        loadInitialGif()
        setupNotifications()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        imageView.layer.cornerRadius = 16
        NextButton.layer.cornerRadius = 13
        
        NextButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: NextButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: NextButton.centerYAnchor)
        ])
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToBackground),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
    }
    
    private func setupPageControl() {
        // Stack view setup
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        // Constraints
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.bottomAnchor.constraint(equalTo: imageView.topAnchor, constant: -10),
            stackView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        updatePageControlLabels()
    }
    
    private func updatePageControlLabels() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        numberLabels.removeAll()
        
        let totalPages = sharePrank == "Instagram" ? 4 : 5
        pageNumbers = (1...totalPages).map { String($0) }
        
        for (index, number) in pageNumbers.enumerated() {
            let label = UILabel()
            label.text = number
            label.textAlignment = .center
            label.font = UIFont(name: "Avenir-Heavy", size: 16)
            label.textColor = .black
            label.backgroundColor = .customGray
            label.layer.cornerRadius = 20
            label.layer.masksToBounds = true
            label.translatesAutoresizingMaskIntoConstraints = false
            
            label.widthAnchor.constraint(equalToConstant: 40).isActive = true
            label.heightAnchor.constraint(equalToConstant: 40).isActive = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePageControlTap(_:)))
            label.isUserInteractionEnabled = true
            label.tag = index
            label.addGestureRecognizer(tapGesture)
            
            numberLabels.append(label)
            stackView.addArrangedSubview(label)
        }
        
        updateSelectedPage(0)
    }
    
    private func updateSelectedPage(_ pageIndex: Int) {
        numberLabels.enumerated().forEach { (index, label) in
            if index == pageIndex {
                label.backgroundColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
                label.textColor = .black
            } else {
                label.backgroundColor = .customGray
                label.textColor = .black
            }
        }
    }
    
    private func loadInitialGif() {
        if sharePrank == "Instagram" {
            loadGif(named: instaGIF[0])
        } else {
            loadGif(named: snapGIF[0])
        }
        // Add this line to set initial button title
        updateButtonTitle()
    }
    
    // MARK: - Action Methods
    @objc private func handlePageControlTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel else { return }
        currentPage = label.tag
        updateSelectedPage(currentPage)
        
        if sharePrank == "Instagram" {
            loadGif(named: instaGIF[currentPage])
        } else {
            loadGif(named: snapGIF[currentPage])
        }
        
        // Add this line to update button title
        updateButtonTitle()
    }
    
    // Add this function to update button title
    private func updateButtonTitle() {
        let maxPages = sharePrank == "Instagram" ? instaGIF.count : snapGIF.count
        if currentPage == maxPages - 1 {
            NextButton.setTitle("Share Link", for: .normal)
        } else {
            NextButton.setTitle("Next", for: .normal)
        }
    }

    // Modify the btnNextTapped function
    @IBAction func btnNextTapped(_ sender: UIButton) {
        let maxPages = sharePrank == "Instagram" ? instaGIF.count : snapGIF.count
        
        if currentPage < maxPages - 1 {
            currentPage += 1
            updateSelectedPage(currentPage)
            
            if sharePrank == "Instagram" {
                loadGif(named: instaGIF[currentPage])
            } else {
                loadGif(named: snapGIF[currentPage])
            }
            
            // Update button title after changing page
            updateButtonTitle()
        } else {
            if sharePrank == "Instagram" {
                shareInstagramStory()
            } else {
                shareToSnapchat()
            }
        }
    }
    
    @objc func appMovedToBackground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            UIPasteboard.general.string = self.prankLink
        }
    }
    
    // MARK: - Helper Methods
    func loadGif(named gifName: String) {
        if let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL),
           let image = UIImage.gif(data: gifData) {
            imageView.image = image
        }
    }
    
    private func shareInstagramStory() {
        guard let prankLink = prankLink,
              let prankName = prankName,
              let coverImageURLString = coverImageURL,
              let coverImageURL = URL(string: coverImageURLString) else {
            return
        }
        
        if let urlScheme = URL(string: "instagram-stories://share?source_application=com.prank.memes.fun"),
           UIApplication.shared.canOpenURL(urlScheme) {
            
            NextButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
            NextButton.isEnabled = false
            
            let screenSize = UIScreen.main.bounds.size
            let targetAspectRatio: CGFloat = 9.0 / 16.0
            let screenAspectRatio = screenSize.width / screenSize.height
            
            var targetSize: CGSize
            if screenAspectRatio > targetAspectRatio {
                targetSize = CGSize(width: screenSize.height * targetAspectRatio, height: screenSize.height)
            } else {
                targetSize = CGSize(width: screenSize.width, height: screenSize.width / targetAspectRatio)
            }
            
            let shareView = ShareView(frame: CGRect(origin: .zero, size: targetSize))
            shareView.pasteLinkImageView.image = UIImage(named: "InstagramLink")
            
            shareView.configureShareView(imageURL: coverImageURL, name: prankName) { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    DispatchQueue.main.async {
                        shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                        shareView.layoutIfNeeded()
                        
                        UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, false, 0)
                        guard let context = UIGraphicsGetCurrentContext() else {
                            self.handleShareFailure()
                            return
                        }
                        
                        shareView.layer.render(in: context)
                        guard let image = UIGraphicsGetImageFromCurrentImageContext(),
                              let imageData = image.pngData() else {
                            UIGraphicsEndImageContext()
                            self.handleShareFailure()
                            return
                        }
                        UIGraphicsEndImageContext()
                        
                        if let url = URL(string: prankLink) {
                            let items: [String: Any] = [
                                "com.instagram.sharedSticker.backgroundImage": imageData,
                                "com.instagram.sharedSticker.contentURL": url,
                            ]
                            UIPasteboard.general.setItems([items], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
                            UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
                        }
                        
                        self.activityIndicator.stopAnimating()
                        self.NextButton.setTitle("Share Link", for: .normal)
                        self.NextButton.isEnabled = true
                    }
                } else {
                    self.handleShareFailure()
                }
            }
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/us/app/instagram/id389801252") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func handleShareFailure() {
        DispatchQueue.main.async { [weak self] in
            self?.activityIndicator.stopAnimating()
            self?.NextButton.setTitle("Share Link", for: .normal)
            self?.NextButton.isEnabled = true
            
            let snackbar = CustomSnackbar(message: "Failed to load image. Please try again.", backgroundColor: .snackbar)
            snackbar.show(in: self!.view, duration: 3.0)
        }
    }
    
    private func shareToSnapchat() {
        guard let prankLink = prankLink,
              let prankName = prankName,
              let coverImageURLString = coverImageURL,
              let coverImageURL = URL(string: coverImageURLString) else {
            return
        }
        
        let snapchatURL = URL(string: "snapchat://")
        if let url = snapchatURL, UIApplication.shared.canOpenURL(url) {
            NextButton.setTitle("", for: .normal)
            activityIndicator.startAnimating()
            NextButton.isEnabled = false
            
            let screenSize = UIScreen.main.bounds.size
            let targetAspectRatio: CGFloat = 9.0 / 16.0
            let screenAspectRatio = screenSize.width / screenSize.height
            
            var targetSize: CGSize
            if screenAspectRatio > targetAspectRatio {
                targetSize = CGSize(width: screenSize.height * targetAspectRatio, height: screenSize.height)
            } else {
                targetSize = CGSize(width: screenSize.width, height: screenSize.width / targetAspectRatio)
            }
            
            UIPasteboard.general.string = prankLink
            
            let shareView = ShareView(frame: CGRect(origin: .zero, size: targetSize))
            shareView.pasteLinkImageView.image = UIImage(named: "SnapchatLink")
            
            shareView.configureShareView(imageURL: coverImageURL, name: prankName) { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    DispatchQueue.main.async {
                        shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                        shareView.layoutIfNeeded()
                        
                        UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, false, 0)
                        guard let context = UIGraphicsGetCurrentContext() else {
                            self.handleShareFailure()
                            return
                        }
                        
                        shareView.layer.render(in: context)
                        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                            UIGraphicsEndImageContext()
                            self.handleShareFailure()
                            return
                        }
                        UIGraphicsEndImageContext()
                        
                        UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
                        
                        self.activityIndicator.stopAnimating()
                        self.NextButton.setTitle("Share Link", for: .normal)
                        self.NextButton.isEnabled = true
                        
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                } else {
                    self.handleShareFailure()
                }
            }
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/app/snapchat/id447188370") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving photo: \(error.localizedDescription)")
        } else {
            print("Successfully saved snapchat story Image to gallery.")
        }
    }
}
    
