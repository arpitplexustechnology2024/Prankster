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
    var prankShareURL: String?
    var prankType: String?
    private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var blurEffectView: UIVisualEffectView!
    private let adsViewModel = AdsViewModel()
    let interstitialAdUtility = InterstitialAdUtility()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareLinkPopup.layer.cornerRadius = 18
        self.imageView.layer.cornerRadius = 18
        self.setupScrollView()
        self.setupBlurEffect()
        self.addContentToStackView()
        
        if let coverImageUrl = self.coverImageURL {
            self.loadImage(from: coverImageUrl, into: self.imageView)
            UserDefaults.standard.set(coverImageUrl, forKey: "CoverImage")
            NotificationCenter.default.post(name: Notification.Name("PrankInfoUpdated"), object: coverImageUrl)
        }
        
        UserDefaults.standard.set(prankName, forKey: "Name")
        
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
        
        if isConnectedToInternet() {
            if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                print("Interstitial Ad ID: \(interstitialAdID)")
                interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
            } else {
                print("No Interstitial Ad ID found")
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
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
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shareInstagramMessage()
            }
        case 2:  // Instagram Story
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.NavigateToShareSnapchat(sharePrank: "Instagram")
            }
        case 3:   // Snapchat Story
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.NavigateToShareSnapchat(sharePrank: "Snapchat")
            }
        case 4:    // Telegram Message
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shareTelegramMessage()
            }
        case 5:  // WhatsApp Message
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shareWhatsAppMessage()
            }
        case 6:  // More
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.shareSnapchatMessage()
            }
        default:
            break
        }
    }
    
    private func NavigateToShareSnapchat(sharePrank: String?) {
        guard let prankLink = prankShareURL,
              let coverImageURL = coverImageURL else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bottomSheetVC = storyboard.instantiateViewController(withIdentifier: "ShareBottomVC") as! ShareBottomVC
        bottomSheetVC.coverImageURL = coverImageURL
        bottomSheetVC.prankLink = prankLink
        bottomSheetVC.sharePrank = sharePrank
        if UIDevice.current.userInterfaceIdiom == .pad {
            bottomSheetVC.modalPresentationStyle = .formSheet
            bottomSheetVC.preferredContentSize = CGSize(width: 540, height: 540)
        } else {
            bottomSheetVC.modalPresentationStyle = .custom
            bottomSheetVC.transitioningDelegate = self
        }
        present(bottomSheetVC, animated: true, completion: nil)
    }
    
    private func shareWhatsAppMessage() {
        guard let prankLink = prankShareURL,
              let prankName = prankName else { return }
        let message = "\(prankName)\n\n🔗 Check this out: \(prankLink)"
        let whatsappURL = URL(string: "whatsapp://send?text=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        if let url = whatsappURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/us/app/whatsapp-messenger/id310633997") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func shareInstagramMessage() {
        guard let prankLink = prankShareURL,
              let prankName = prankName else { return }
        let message = "\(prankName)\n\n\(prankLink)"
        if let url = URL(string: "instagram://sharesheet?text=\(message)") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/us/app/instagram/id389801252") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func shareTelegramMessage() {
        guard let prankLink = prankShareURL,
              let prankName = prankName else { return }
        let telegramMessage = "\(prankName)\n\n🔗 Check this out: \(prankLink)"
        let encodedMessage = telegramMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: "tg://msg?text=\(encodedMessage ?? "")"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/ng/app/telegram-messenger/id686449807") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func shareSnapchatMessage() {
        guard let prankLink = prankShareURL,
              let prankName = prankName else { return }
        let message = "\(prankName)\n\n🔗 Check this out: \(prankLink)"
        let itemsToShare: [Any] = [message]
        let activityVC = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        self.present(activityVC, animated: true, completion: nil)
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

extension ShareLinkPopup: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let customPresentationController = CustomePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        customPresentationController.heightPercentage = 0.5
        return customPresentationController
    }
}
