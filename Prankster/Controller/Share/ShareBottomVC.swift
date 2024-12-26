//
//  ShareBottomVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/12/24.
//

import UIKit

class ShareBottomVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var NextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    let instaGIF = ["Insta1", "Insta2", "Insta3", "Insta4"]
    let snapGIF = ["Snap1", "Snap2", "Snap3", "Snap4", "Snap5"]
    
    var instaCurrentGifIndex = 0
    var snapCurrentGifIndex = 0
    
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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 16
        NextButton.layer.cornerRadius = 13
        backButton.layer.cornerRadius = 13
        
        NextButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: NextButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: NextButton.centerYAnchor)
        ])
        
        backButton.setTitle("Cancel", for: .normal)
        
        if sharePrank == "Instagram" {
            loadGif(named: instaGIF[instaCurrentGifIndex])
        } else {
            loadGif(named: snapGIF[snapCurrentGifIndex])
        }
        
         NotificationCenter.default.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
             UIPasteboard.general.string = self.prankLink
        }
    }
    
    func loadGif(named gifName: String) {
        if let gifURL = Bundle.main.url(forResource: gifName, withExtension: "gif"),
           let gifData = try? Data(contentsOf: gifURL),
           let image = UIImage.gif(data: gifData) {
            imageView.image = image
        }
    }
    
    @IBAction func btnNextTapped(_ sender: UIButton) {
        if sharePrank == "Instagram" {
            instaCurrentGifIndex += 1
            if instaCurrentGifIndex < instaGIF.count {
                loadGif(named: instaGIF[instaCurrentGifIndex])
                backButton.setTitle("Back", for: .normal)
            } else {
                shareInstagramStory()
            }
        } else {
            snapCurrentGifIndex += 1
            if snapCurrentGifIndex < snapGIF.count {
                loadGif(named: snapGIF[snapCurrentGifIndex])
                backButton.setTitle("Back", for: .normal)
            } else {
                shareToSnapchat()
            }
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        if sharePrank == "Instagram" {
            instaCurrentGifIndex -= 1
            if instaCurrentGifIndex < 0 && instaGIF[0] == "Insta1" {
                instaCurrentGifIndex = 0
                dismiss(animated: true, completion: nil)
                return
            }
            if instaCurrentGifIndex >= 0 {
                loadGif(named: instaGIF[instaCurrentGifIndex])
                if instaGIF[instaCurrentGifIndex] == "Insta1" {
                    backButton.setTitle("Cancel", for: .normal)
                }
            } else {
                instaCurrentGifIndex = instaGIF.count - 1
                loadGif(named: instaGIF[instaCurrentGifIndex])
            }
        } else {
            snapCurrentGifIndex -= 1
            if snapCurrentGifIndex < 0 && snapGIF[0] == "Snap1" {
                snapCurrentGifIndex = 0
                dismiss(animated: true, completion: nil)
                return
            }
            if snapCurrentGifIndex >= 0 {
                loadGif(named: snapGIF[snapCurrentGifIndex])
                if snapGIF[snapCurrentGifIndex] == "Snap1" {
                    backButton.setTitle("Cancel", for: .normal)
                }
            } else {
                snapCurrentGifIndex = snapGIF.count - 1
                loadGif(named: snapGIF[snapCurrentGifIndex])
            }
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
                        self.NextButton.setTitle("Next", for: .normal)
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
            self?.NextButton.setTitle("Next", for: .normal)
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
                        self.NextButton.setTitle("Next", for: .normal)
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
