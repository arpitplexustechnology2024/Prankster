//
//  ShareLinkPopup.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 01/12/24.
//

import UIKit
import Alamofire
import AVFAudio
import AVFoundation

class ShareLinkPopup: UIViewController {
    
    @IBOutlet weak var shareLinkPopup: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    
    var coverImageURL: String?
    var prankDataURL: String?
    var prankName: String?
    var prankLink: String?
    var prankType: String?
    private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var blurEffectView: UIVisualEffectView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareLinkPopup.layer.cornerRadius = 18
        self.imageView.layer.cornerRadius = 18
        self.setupScrollView()
        self.setupBlurEffect()
        self.addContentToStackView()
        
        if let coverImageUrl = self.coverImageURL {
            self.loadImage(from: coverImageUrl, into: self.imageView)
        }
        
        self.playPauseImageView.image = UIImage(named: "PlayButton")
        self.playPauseImageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(tapGesture)
        
        let playPauseTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.playPauseImageView.isUserInteractionEnabled = true
        self.playPauseImageView.addGestureRecognizer(playPauseTapGesture)
        
        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.viewClickDissmiss))
        self.view.addGestureRecognizer(viewTapGesture)
    }
    
    @objc private func viewClickDissmiss() {
        self.dismiss(animated: true)
    }
    
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.alpha = 0.9
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - setupScrollView
    func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = true
        shareView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: shareView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: shareView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: shareView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: shareView.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        AF.request(urlString).response { response in
            switch response.result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            case .failure(let error):
                print("Image download error: \(error)")
                DispatchQueue.main.async {
                    imageView.image = UIImage(named: "placeholder")
                }
            }
        }
    }
    
    @objc private func togglePlayPause() {
        if isConnectedToInternet() {
            isPlaying.toggle()
            
            guard let prankDataUrl = prankDataURL else { return }
            
            if prankType == "audio" {
                if isPlaying {
                    if audioPlayer == nil {
                        URLSession.shared.dataTask(with: URL(string: prankDataUrl)!) { [weak self] (data, response, error) in
                            guard let self = self, let data = data else {
                                print("Error loading audio: \(error?.localizedDescription ?? "Unknown error")")
                                DispatchQueue.main.async {
                                    self?.isPlaying = false
                                }
                                return
                            }
                            
                            DispatchQueue.main.async {
                                do {
                                    self.audioPlayer = try AVAudioPlayer(data: data)
                                    self.audioPlayer?.prepareToPlay()
                                    self.audioPlayer?.play()
                                    self.audioPlayer?.delegate = self
                                    self.imageView.image = UIImage(named: "audioPrankImage")
                                    self.playPauseImageView.isHidden = true
                                } catch {
                                    print("Error creating audio player: \(error)")
                                    self.isPlaying = false
                                }
                            }
                        }.resume()
                    } else {
                        audioPlayer?.play()
                        imageView.image = UIImage(named: "audioPrankImage")
                        playPauseImageView.isHidden = true
                    }
                } else {
                    audioPlayer?.pause()
                    imageView.image = UIImage(named: "audioPrankImage")
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                }
            } else if prankType == "video" {
                if isPlaying {
                    if videoPlayer == nil {
                        URLSession.shared.dataTask(with: URL(string: prankDataUrl)!) { [weak self] (data, response, error) in
                            guard let self = self, let data = data else {
                                print("Error loading video: \(error?.localizedDescription ?? "Unknown error")")
                                DispatchQueue.main.async {
                                    self?.isPlaying = false
                                }
                                return
                            }
                            
                            do {
                                let temporaryDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                let temporaryFileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
                                
                                try data.write(to: temporaryFileURL)
                                
                                DispatchQueue.main.async {
                                    self.videoPlayer = AVPlayer(url: temporaryFileURL)
                                    self.playerLayer = AVPlayerLayer(player: self.videoPlayer)
                                    self.playerLayer?.videoGravity = .resizeAspectFill
                                    self.playerLayer?.frame = self.imageView.bounds
                                    
                                    if let playerLayer = self.playerLayer {
                                        self.imageView.layer.addSublayer(playerLayer)
                                    }
                                    
                                    self.videoPlayer?.play()
                                    self.playPauseImageView.isHidden = true
                                    
                                    NotificationCenter.default.addObserver(
                                        self,
                                        selector: #selector(self.videoDidFinishPlaying),
                                        name: .AVPlayerItemDidPlayToEndTime,
                                        object: self.videoPlayer?.currentItem
                                    )
                                }
                            } catch {
                                print("Error saving video: \(error)")
                                DispatchQueue.main.async {
                                    self.isPlaying = false
                                }
                            }
                        }.resume()
                    } else {
                        videoPlayer?.play()
                        playPauseImageView.isHidden = true
                    }
                } else {
                    videoPlayer?.pause()
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                }
            } else {
                if isPlaying {
                    loadImage(from: prankDataUrl, into: imageView)
                    playPauseImageView.isHidden = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                        if let coverImageUrl = self.coverImageURL {
                            self.loadImage(from: coverImageUrl, into: self.imageView)
                        }
                        playPauseImageView.image = UIImage(named: "PlayButton")
                        playPauseImageView.isHidden = false
                        isPlaying = false
                    }
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    @objc private func videoDidFinishPlaying() {
        DispatchQueue.main.async {
            self.videoPlayer?.seek(to: .zero)
            self.videoPlayer?.pause()
            self.isPlaying = false
            if let coverImageUrl = self.coverImageURL {
                self.loadImage(from: coverImageUrl, into: self.imageView)
            }
            self.playerLayer?.removeFromSuperlayer()
            self.playerLayer = nil
            self.videoPlayer = nil
            self.playPauseImageView.image = UIImage(named: "PlayButton")
            self.playPauseImageView.isHidden = false
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - addContentToStackView
    func addContentToStackView() {
        let items = [
            (icon: UIImage(named: "copylink"), title: "Copy link"),
            (icon: UIImage(named: "instagram"), title: "Message"),
            (icon: UIImage(named: "instagram"), title: "Story"),
            (icon: UIImage(named: "snapchat"), title: "Message"),
            (icon: UIImage(named: "snapchat"), title: "Story"),
            (icon: UIImage(named: "telegram"), title: "Message"),
            (icon: UIImage(named: "whatsapp"), title: "Message"),
            (icon: UIImage(named: "moreShare"), title: "More")
        ]
        
        for (index, item) in items.enumerated() {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.tag = index
            
            let verticalStackView = UIStackView()
            verticalStackView.axis = .vertical
            verticalStackView.alignment = .center
            verticalStackView.spacing = 5
            verticalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView(image: item.icon)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = item.title
            label.textColor = .icon
            label.font = UIFont.systemFont(ofSize: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            verticalStackView.addArrangedSubview(imageView)
            verticalStackView.addArrangedSubview(label)
            containerView.addSubview(verticalStackView)
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 50),
                imageView.heightAnchor.constraint(equalToConstant: 50)
            ])
            NSLayoutConstraint.activate([
                verticalStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                verticalStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            
            containerView.widthAnchor.constraint(equalToConstant: 78).isActive = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            containerView.addGestureRecognizer(tapGesture)
            containerView.isUserInteractionEnabled = true
            
            
            stackView.addArrangedSubview(containerView)
        }
    }
    
    // MARK: - viewTapped
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        
        switch tappedView.tag {
        case 0: // Copy link
            if let prankLink = prankLink {
                UIPasteboard.general.string = prankLink
                let snackbar = CustomSnackbar(message: "Link copied to clipboard!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
                
            }
        case 1:  // Instagram Message
            guard let prankLink = prankLink,
                  let prankName = prankName else { return }
            let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
            if let url = URL(string: "instagram://sharesheet?text=\(message)") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case 2:  // Instagram Story
            guard let prankLink = prankLink,
                  let prankName = prankName else { return }
            
            let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
            if let url = URL(string: "snapchat://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case 3:  // Snapchat Message
            if let prankLink = prankLink,
               let coverImageURL = coverImageURL {
                // Download the cover image
                AF.request(coverImageURL).responseData { response in
                    switch response.result {
                    case .success(let data):
                        if let coverImage = UIImage(data: data) {
                            // Save the image to a temporary location
                            let tempDirectory = FileManager.default.temporaryDirectory
                            let imagePath = tempDirectory.appendingPathComponent("prankCoverImage.jpg")
                            
                            do {
                                // Write image data to a temporary file
                                try data.write(to: imagePath)
                                
                                // Use Snapchat URL scheme for sharing
                                let snapURL = URL(string: "snapchat://")!
                                if UIApplication.shared.canOpenURL(snapURL) {
                                    // Use UIActivityViewController for sharing
                                    let activityVC = UIActivityViewController(activityItems: [coverImage, prankLink], applicationActivities: nil)
                                    self.present(activityVC, animated: true)
                                } else {
                                    let snackbar = CustomSnackbar(message: "Snapchat is not installed!", backgroundColor: .snackbar)
                                    snackbar.show(in: self.view, duration: 3.0)
                                }
                            } catch {
                                print("Error saving image: \(error)")
                            }
                        } else {
                            print("Failed to create image from data.")
                        }
                    case .failure(let error):
                        print("Error downloading cover image: \(error)")
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Failed to prepare content for sharing!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 4:   // Snapchat Story
            guard let prankLink = prankLink,
                  let prankName = prankName else { return }
            let promoText = "Check out this great new video from \(prankName), I found on talent app"
            let shareString = "snapchat://text=\(promoText)&url=\(prankLink)"
            let escapedShareString = shareString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            let url = URL(string: escapedShareString)
            UIApplication.shared.openURL(url!)
        case 5:    // Telegram Message
            if let prankLink = prankLink {
                let telegramMessage = "\(prankLink)"
                let encodedMessage = telegramMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                if let url = URL(string: "tg://msg?text=\(encodedMessage ?? "")"), UIApplication.shared.canOpenURL(url) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    let snackbar = CustomSnackbar(message: "Telegram app not installed!", backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
            }
        case 6:  // WhatsApp Message
            shareURLToSnapchat()
            // shareViaWhatsAppMessage()
        case 7:  // More
            
            guard let prankLink = prankLink,
                  let prankName = prankName,
                  let coverImageURL = coverImageURL else { return }
            
            AF.request(coverImageURL).responseData { [weak self] response in
                switch response.result {
                case .success(let imageData):
                    guard let image = UIImage(data: imageData) else { return }
                    
                    let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
                    self?.openShareSheetWithImageAndLink(image: image, link: message)
                case .failure:
                    self?.openShareSheetWithLink(prankLink)
                }
            }
        default:
            break
        }
    }
    
    func shareURLToSnapchat() {
        let urlToShare = "https://your-url.com"
        UIPasteboard.general.string = urlToShare
        if let snapchatURL = URL(string: "snapchat://chat") {
            if UIApplication.shared.canOpenURL(snapchatURL) {
                UIApplication.shared.open(snapchatURL, options: [:], completionHandler: nil)
                print("URL copied to clipboard. Share it in Snapchat manually.")
            } else {
                print("Snapchat is not installed.")
            }
        }
    }
    
    func shareOnTelegram(prankLink: String, coverImageURL: URL?) {
        // Validate inputs
        guard let imageURL = coverImageURL else {
            print("No image URL provided")
            return
        }
        
        // Check if Telegram is installed
        let telegramURLScheme = "tg://msg?text=\(prankLink)"
        guard let telegramURL = URL(string: telegramURLScheme.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") else {
            print("Invalid Telegram URL")
            return
        }
        
        // Attempt to download the image
        URLSession.shared.dataTask(with: imageURL) { (data, response, error) in
            if let error = error {
                print("Image download error: \(error.localizedDescription)")
                return
            }
            
            guard let imageData = data, let image = UIImage(data: imageData) else {
                print("Could not load image")
                return
            }
            
            // Perform UI updates on the main thread
            DispatchQueue.main.async {
                // Prepare activity items
                let itemsToShare = [image, prankLink] as [Any]
                
                // Create activity view controller
                let activityViewController = UIActivityViewController(
                    activityItems: itemsToShare,
                    applicationActivities: nil
                )
                
                // Configure exclusion list to prioritize Telegram
                activityViewController.excludedActivityTypes = [
                    .addToReadingList,
                    .assignToContact,
                    .print
                ]
                
                // Present the share sheet
                self.present(activityViewController, animated: true, completion: nil)
            }
        }.resume()
    }
    
    
    func shareToTelegram(link: String, image: UIImage) {
        // Prepare the message
        let message = link
        
        // Create an array of items to share
        let items: [Any] = [message, image]
        
        // Initialize UIActivityViewController
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Filter activities to ensure Telegram is included
        activityVC.excludedActivityTypes = [.postToFacebook, .postToTwitter]
        
        // Present the activity view controller
        activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
            if let activityType = activityType, activityType.rawValue.contains("com.apple.UIKit.activity.Message") && !UIApplication.shared.canOpenURL(URL(string: "tg://")!) {
                let snackbar = CustomSnackbar(message: "Telegram app not installed!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        }
        
        // Show the Activity View Controller
        self.present(activityVC, animated: true, completion: nil)
    }
    
    
    private func shareToTelegram() {
        guard let prankLink = prankLink else { return }
        
        // Step 1: Download the image
        guard let coverImageUrl = coverImageURL, let imageUrl = URL(string: coverImageUrl) else {
            print("Invalid cover image URL")
            return
        }
        
        AF.download(imageUrl).responseData { response in
            switch response.result {
            case .success(let data):
                if let image = UIImage(data: data) {
                    let sharingMessage = "Check this out: \(prankLink)"
                    let sharingItems: [Any] = [image, sharingMessage]
                    
                    let activityVC = UIActivityViewController(activityItems: sharingItems, applicationActivities: nil)
                    
                    activityVC.excludedActivityTypes = [
                        .postToFacebook,
                        .postToTwitter,
                        .message,
                        .mail,
                        .postToWeibo,
                        .print,
                        .copyToPasteboard,
                        .assignToContact,
                        .saveToCameraRoll
                    ]
                    
                    // Step 4: Present the activity view controller
                    self.present(activityVC, animated: true, completion: nil)
                } else {
                    print("Failed to create image from data")
                }
            case .failure(let error):
                print("Failed to download cover image: \(error)")
            }
        }
    }
    
    private func openShareSheetWithImageAndLink(image: UIImage, link: String) {
        let activityViewController = UIActivityViewController(
            activityItems: [image, link],
            applicationActivities: nil
        )
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func openShareSheetWithLink(_ link: String) {
        let activityViewController = UIActivityViewController(
            activityItems: [link],
            applicationActivities: nil
        )
        present(activityViewController, animated: true, completion: nil)
    }
    
    private func shareViaWhatsAppMessage() {
        guard let prankLink = prankLink,
              let prankName = prankName,
              let coverImageURL = coverImageURL else { return }
        
        AF.request(coverImageURL).responseData { [weak self] response in
            switch response.result {
            case .success(let imageData):
                guard let image = UIImage(data: imageData) else { return }
                
                let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
                
                if let imageURL = self?.saveImageToTemporaryFile(image: image) {
                    let whatsappURL = URL(string: "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
                    
                    if let url = whatsappURL, UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    }
                }
                
            case .failure:
                self?.openShareSheetWithLink(prankLink)
            }
        }
    }
    
    private func saveImageToTemporaryFile(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileURL = tempDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        
        do {
            try data.write(to: tempFileURL)
            return tempFileURL
        } catch {
            print("Error saving image to temporary file: \(error)")
            return nil
        }
    }
}

extension ShareLinkPopup: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            if let coverImageUrl = self.coverImageURL {
                self.loadImage(from: coverImageUrl, into: self.imageView)
            }
            self.playPauseImageView.image = UIImage(named: "PlayButton")
            self.playPauseImageView.isHidden = false
            self.audioPlayer = nil
        }
    }
}
