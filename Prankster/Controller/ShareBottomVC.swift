//
//  ShareBottomVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/12/24.
//

import UIKit

class ShareBottomVC: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.layer.cornerRadius = 16
        self.shareButton.layer.cornerRadius = 13
    }
    
    @IBAction func btnShareLinkTapped(_ sender: UIButton) {
        
    }
}
    
//    //    private func shareInstagramStory() {
//    //        guard let prankLink = viewModel.createPrankLink,
//    //              let prankName = viewModel.createPrankName,
//    //              let coverImageURLString = coverImageURL,
//    //              let coverImageURL = URL(string: coverImageURLString) else { return }
//    //
//    //        if let urlScheme = URL(string: "instagram-stories://share?source_application=com.plexustechnology.Pranksters"), UIApplication.shared.canOpenURL(urlScheme) {
//    //
//    //                UIPasteboard.general.string = prankLink
//    //
//    //                let screenSize = UIScreen.main.bounds.size
//    //                let targetAspectRatio: CGFloat = 9.0 / 16.0
//    //                let screenAspectRatio = screenSize.width / screenSize.height
//    //
//    //                var targetSize: CGSize
//    //
//    //                if screenAspectRatio > targetAspectRatio {
//    //                    targetSize = CGSize(width: screenSize.height * targetAspectRatio, height: screenSize.height)
//    //                } else {
//    //                    targetSize = CGSize(width: screenSize.width, height: screenSize.width / targetAspectRatio)
//    //                }
//    //                let shareView = ShareView(frame: CGRect(origin: .zero, size: targetSize))
//    //                shareView.configure(with: coverImageURL, name: prankName)
//    //
//    //                shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
//    //                shareView.layoutIfNeeded()
//    //                UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
//    //                guard let context = UIGraphicsGetCurrentContext() else { return }
//    //                shareView.layer.render(in: context)
//    //                let image = UIGraphicsGetImageFromCurrentImageContext()
//    //                UIGraphicsEndImageContext()
//    //
//    //                if let imageData = image?.pngData() {
//    //                    if let url = URL(string: prankLink) {
//    //                        let items: [String: Any] = [
//    //                            "com.instagram.sharedSticker.backgroundImage": imageData,
//    //                            "com.instagram.sharedSticker.contentURL": url,
//    //                        ]
//    //                        UIPasteboard.general.setItems([items])
//    //                      //  UIPasteboard.general.setItems([items], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
//    //                        UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
//    //                    }
//    //                }
//    //                self.dismiss(animated: true)
//    //            } else {
//    //                let snackbar = CustomSnackbar(message: "Instagram is not installed!", backgroundColor: .snackbar)
//    //                snackbar.show(in: self.view, duration: 3.0)
//    //            }
//    //    }
//    
//    private func shareInstagramStory() {
//        guard let prankLink = viewModel.createPrankLink,
//              let encodedLink = prankLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
//            // Show error if link is invalid
//            let snackbar = CustomSnackbar(message: "Invalid link!", backgroundColor: .snackbar)
//            snackbar.show(in: self.view, duration: 3.0)
//            return
//        }
//        
//        // Instagram Stories URL scheme for sharing a link
//        guard let urlScheme = URL(string: "instagram-stories://share?source_application=com.plexustechnology.Pranksters&source_url=\(encodedLink)") else {
//            return
//        }
//        
//        // Check if Instagram is installed
//        if UIApplication.shared.canOpenURL(urlScheme) {
//            // Attempt to open Instagram Stories with the link
//            UIApplication.shared.open(urlScheme, options: [:]) { success in
//                if !success {
//                    // Show error if opening failed
//                    DispatchQueue.main.async {
//                        let snackbar = CustomSnackbar(message: "Could not open Instagram!", backgroundColor: .snackbar)
//                        snackbar.show(in: self.view, duration: 3.0)
//                    }
//                }
//            }
//        } else {
//            // Show error if Instagram is not installed
//            let snackbar = CustomSnackbar(message: "Instagram is not installed!", backgroundColor: .snackbar)
//            snackbar.show(in: self.view, duration: 3.0)
//        }
//    }
//    
//    // MARK: - viewTapped
//    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
//        guard let tappedView = gesture.view else { return }
//        
//        switch tappedView.tag {
//        case 0: // Copy link
//            if let prankLink = viewModel.createPrankLink {
//                UIPasteboard.general.string = prankLink
//                let snackbar = CustomSnackbar(message: "Link copied to clipboard!", backgroundColor: .snackbar)
//                snackbar.show(in: self.view, duration: 3.0)
//            }
//        case 1:  // Instagram Message
//            // interstitialAdUtility.presentInterstitial(from: self)
//            guard let prankLink = viewModel.createPrankLink,
//                  let prankName = viewModel.createPrankName else { return }
//            let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
//            if let url = URL(string: "instagram://sharesheet?text=\(message)") {
//                UIApplication.shared.open(url, options: [:], completionHandler: nil)
//            }
//            
//        case 2:  // Instagram Story
//            interstitialAdUtility.presentInterstitial(from: self)
//        case 3:  // Snapchat Message
//            if let prankLink = viewModel.createPrankLink,
//               let coverImageURL = viewModel.createPrankCoverImage {
//                // Download the cover image
//                AF.request(coverImageURL).responseData { response in
//                    switch response.result {
//                    case .success(let data):
//                        if let coverImage = UIImage(data: data) {
//                            // Save the image to a temporary location
//                            let tempDirectory = FileManager.default.temporaryDirectory
//                            let imagePath = tempDirectory.appendingPathComponent("prankCoverImage.jpg")
//                            
//                            do {
//                                // Write image data to a temporary file
//                                try data.write(to: imagePath)
//                                
//                                // Use Snapchat URL scheme for sharing
//                                let snapURL = URL(string: "snapchat://")!
//                                if UIApplication.shared.canOpenURL(snapURL) {
//                                    // Use UIActivityViewController for sharing
//                                    let activityVC = UIActivityViewController(activityItems: [coverImage, prankLink], applicationActivities: nil)
//                                    self.present(activityVC, animated: true)
//                                } else {
//                                    let snackbar = CustomSnackbar(message: "Snapchat is not installed!", backgroundColor: .snackbar)
//                                    snackbar.show(in: self.view, duration: 3.0)
//                                }
//                            } catch {
//                                print("Error saving image: \(error)")
//                            }
//                        } else {
//                            print("Failed to create image from data.")
//                        }
//                    case .failure(let error):
//                        print("Error downloading cover image: \(error)")
//                    }
//                }
//            } else {
//                let snackbar = CustomSnackbar(message: "Failed to prepare content for sharing!", backgroundColor: .snackbar)
//                snackbar.show(in: self.view, duration: 3.0)
//            }
//            
//        case 4:   // Snapchat Story
//            shareToSnapchat()
//        case 5: // WhatsApp Message
//            guard let prankLink = viewModel.createPrankLink,
//                  let prankName = viewModel.createPrankName,
//                  let coverImageURL = coverImageURL else { return }
//            
//            AF.request(coverImageURL).responseData { [weak self] response in
//                switch response.result {
//                case .success(let imageData):
//                    guard let image = UIImage(data: imageData) else { return }
//                    
//                    let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
//                    self?.openShareSheetWithImageAndLink(image: image, link: message)
//                case .failure:
//                    self?.openShareSheetWithLink(prankLink)
//                }
//            }
//        case 6: // More
//            //  sharePrank()
//            shareViaWhatsAppMessage()
//        default:
//            break
//        }
//    }
//    
//    func shareViaSnapchatMessage() {
//        guard let prankLink = viewModel.createPrankLink,
//              let prankName = viewModel.createPrankName,
//              let coverImageURL = coverImageURL else { return }
//        
//        AF.request(coverImageURL).responseData { [weak self] response in
//            switch response.result {
//            case .success(let imageData):
//                guard let image = UIImage(data: imageData) else { return }
//                
//                let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
//                
//                if let imageURL = self?.saveImageToTemporaryFile(image: image) {
//                    let snapchatURL = URL(string: "snapchat://post?media=file://\(imageURL.path)&caption=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
//                    
//                    if let url = snapchatURL, UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                    } else {
//                        self?.openShareSheetWithImageAndLink(image: image, link: message)
//                    }
//                }
//                
//            case .failure:
//                self?.openShareSheetWithLink(prankLink)
//            }
//        }
//    }
//    
//    func sharePrank() {
//        guard let prankLink = viewModel.createPrankLink,
//              let prankName = viewModel.createPrankName,
//              let coverImageURL = coverImageURL else { return }
//        
//        AF.request(coverImageURL).responseData { [weak self] response in
//            switch response.result {
//            case .success(let imageData):
//                guard let image = UIImage(data: imageData) else { return }
//                
//                let message = "\(prankName)\n\n🔗 Check it out:\(prankLink)"
//                self?.openShareSheetWithImageAndLink(image: image, link: message)
//            case .failure:
//                self?.openShareSheetWithLink(prankLink)
//            }
//        }
//    }
//    
//    private func openShareSheetWithImageAndLink(image: UIImage, link: String) {
//        let activityViewController = UIActivityViewController(
//            activityItems: [image, link],
//            applicationActivities: nil
//        )
//        present(activityViewController, animated: true, completion: nil)
//    }
//    
//    private func openShareSheetWithLink(_ link: String) {
//        let activityViewController = UIActivityViewController(
//            activityItems: [link],
//            applicationActivities: nil
//        )
//        present(activityViewController, animated: true, completion: nil)
//    }
//    
//    private func shareViaWhatsAppMessage() {
//        guard let prankLink = viewModel.createPrankLink,
//              let prankName = viewModel.createPrankName,
//              let coverImageURL = coverImageURL else { return }
//        
//        AF.request(coverImageURL).responseData { [weak self] response in
//            switch response.result {
//            case .success(let imageData):
//                guard let image = UIImage(data: imageData) else { return }
//                
//                let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
//                
//                if let imageURL = self?.saveImageToTemporaryFile(image: image) {
//                    let whatsappURL = URL(string: "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
//                    
//                    if let url = whatsappURL, UIApplication.shared.canOpenURL(url) {
//                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
//                    }
//                }
//                
//            case .failure:
//                self?.openShareSheetWithLink(prankLink)
//            }
//        }
//    }
//    
//    private func saveImageToTemporaryFile(image: UIImage) -> URL? {
//        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
//        
//        let tempDirectory = FileManager.default.temporaryDirectory
//        let tempFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
//        
//        do {
//            try data.write(to: tempFileURL)
//            return tempFileURL
//        } catch {
//            print("Error saving image to temporary file: \(error)")
//            return nil
//        }
//    }
