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
    var sharePrank: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 16
        NextButton.layer.cornerRadius = 13
        backButton.layer.cornerRadius = 13
        
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
            } else {
                shareInstagramStory()
            }
        } else {
            snapCurrentGifIndex += 1
            if snapCurrentGifIndex < snapGIF.count {
                loadGif(named: snapGIF[snapCurrentGifIndex])
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
                return
            }
            if instaCurrentGifIndex >= 0 {
                loadGif(named: instaGIF[instaCurrentGifIndex])
            } else {
                instaCurrentGifIndex = instaGIF.count - 1
                loadGif(named: instaGIF[instaCurrentGifIndex])
            }
        } else {
            snapCurrentGifIndex -= 1
            if snapCurrentGifIndex < 0 && snapGIF[0] == "Snap1" {
                snapCurrentGifIndex = 0
                return
            }
            if snapCurrentGifIndex >= 0 {
                loadGif(named: snapGIF[snapCurrentGifIndex])
            } else {
                snapCurrentGifIndex = snapGIF.count - 1
                loadGif(named: snapGIF[snapCurrentGifIndex])
            }
        }
    }
    
    private func shareInstagramStory() {
        guard let prankLink = prankLink,
              let coverImageURL = coverImageURL else { return }
        
        if let urlScheme = URL(string: "instagram-stories://share?source_application=com.prank.memes.fun"), UIApplication.shared.canOpenURL(urlScheme) {
            
            UIPasteboard.general.string = prankLink
            
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
            shareView.configure(with: URL(string: coverImageURL)!)
            
            shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
            shareView.layoutIfNeeded()
            UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            shareView.layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let imageData = image?.pngData() {
                if let url = URL(string: prankLink) {
                    let items: [String: Any] = [
                        "com.instagram.sharedSticker.backgroundImage": imageData,
                        "com.instagram.sharedSticker.contentURL": url,
                    ]
                    UIPasteboard.general.setItems([items], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
                    UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Instagram is not installed!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
//            if let appStoreURL = URL(string: "https://apps.apple.com/us/app/instagram/id389801252") {
//                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
//            }
        }
    }
    
    private func shareToSnapchat() {
        guard let prankLink = prankLink,
              let coverImageURL = coverImageURL else { return }
        
        let snapchatURL = URL(string: "snapchat://")
        if let url = snapchatURL, UIApplication.shared.canOpenURL(url) {
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
            shareView.configure(with: URL(string: coverImageURL)!)
            
            DispatchQueue.main.async { [self] in
                shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
                shareView.layoutIfNeeded()
                UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, false, 0)
                shareView.layer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                if let image = image {
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
                }
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please Install Snapchat App", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
//            if let appStoreURL = URL(string: "https://apps.apple.com/app/snapchat/id447188370") {
//                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
//            }
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
