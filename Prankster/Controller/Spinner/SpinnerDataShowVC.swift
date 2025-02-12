//
//  SpinnerDataShowVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 06/02/25.
//

import UIKit
import Alamofire
import AVFAudio
import AVFoundation

class SpinnerDataShowVC: UIViewController {
    
    @IBOutlet weak var shareLinkPopup: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    
    @IBOutlet weak var cancelButton: UIButton!
    
    var sharePrank: Bool = false
    var coverImageURL: String?
    var prankDataURL: String?
    var prankName: String?
    var prankLink: String?
    var prankShareURL: String?
    var prankType: String?
    var prankImage: String?
    private var isLoading = false
    private var isPlaying = false
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var blurEffectView: UIVisualEffectView!
    private var adsViewModel: AdsViewModel!
    private var loadingAlert: LoadingAlertView?
    private let rewardAdUtility = RewardAdUtility()
    
    init(adViewModule: AdsViewModel) {
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareLinkPopup.layer.cornerRadius = 18
        self.imageView.layer.cornerRadius = 18
        self.setupScrollView()
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
        
        let viewTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewTap))
        self.view.addGestureRecognizer(viewTapGesture)
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
    
    private func loadImage(from urlString: String, into imageView: UIImageView, completion: (() -> Void)? = nil) {
        
        AF.request(urlString).response { [weak self] response in
            switch response.result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                        completion?()
                    }
                }
            case .failure(let error):
                print("Image download error: \(error)")
                DispatchQueue.main.async {
                    imageView.image = UIImage(named: "placeholder")
                    completion?()
                }
            }
        }
    }
    
    private func showLoadingAlert() {
        isLoading = true
        loadingAlert = LoadingAlertView(frame: view.bounds)
        if let loadingAlert = loadingAlert {
            view.addSubview(loadingAlert)
            loadingAlert.startAnimating()
        }
    }
    
    private func hideLoadingAlert() {
        DispatchQueue.main.async {
            self.isLoading = false
            self.loadingAlert?.removeFromSuperview()
            self.loadingAlert = nil
        }
    }
    
    @objc private func handleViewTap() {
        if !isLoading {
            self.dismiss(animated: true)
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
                                DispatchQueue.main.async {
                                    self?.isPlaying = false
                                    let snackbar = CustomSnackbar(message: "Failed to load audio!", backgroundColor: .snackbar)
                                    snackbar.show(in: self?.view ?? UIView(), duration: 3.0)
                                }
                                return
                            }
                            
                            DispatchQueue.main.async {
                                do {
                                    self.audioPlayer = try AVAudioPlayer(data: data)
                                    self.audioPlayer?.prepareToPlay()
                                    self.audioPlayer?.play()
                                    self.audioPlayer?.delegate = self
                                    if let audioImageUrl = self.prankImage {
                                        self.loadImage(from: audioImageUrl, into: self.imageView)
                                    }
                                    self.playPauseImageView.isHidden = true
                                } catch {
                                    print("Error creating audio player: \(error)")
                                    self.isPlaying = false
                                    let snackbar = CustomSnackbar(message: "Failed to play audio!", backgroundColor: .snackbar)
                                    snackbar.show(in: self.view, duration: 3.0)
                                }
                            }
                        }.resume()
                    } else {
                        audioPlayer?.play()
                        if let audioImageUrl = self.prankImage {
                            self.loadImage(from: audioImageUrl, into: self.imageView)
                        }
                        playPauseImageView.isHidden = true
                    }
                } else {
                    audioPlayer?.pause()
                    if let audioImageUrl = self.prankImage {
                        self.loadImage(from: audioImageUrl, into: self.imageView)
                    }
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                }
            } else if prankType == "video" {
                if isPlaying {
                    showLoadingAlert()
                    
                    if videoPlayer == nil {
                        URLSession.shared.dataTask(with: URL(string: prankDataUrl)!) { [weak self] (data, response, error) in
                            guard let self = self, let data = data else {
                                DispatchQueue.main.async {
                                    self?.isPlaying = false
                                    self?.hideLoadingAlert()
                                    let snackbar = CustomSnackbar(message: "Failed to load video!", backgroundColor: .snackbar)
                                    snackbar.show(in: self?.view ?? UIView(), duration: 3.0)
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
                                    
                                    self.hideLoadingAlert()
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
                                    self.hideLoadingAlert()
                                    let snackbar = CustomSnackbar(message: "Failed to play video!", backgroundColor: .snackbar)
                                    snackbar.show(in: self.view, duration: 3.0)
                                }
                            }
                        }.resume()
                    } else {
                        videoPlayer?.play()
                        playPauseImageView.isHidden = true
                        self.hideLoadingAlert()
                    }
                } else {
                    videoPlayer?.pause()
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                }
            } else {
                if isPlaying {
                    loadImage(from: prankDataUrl, into: imageView) {
                        self.playPauseImageView.isHidden = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            if let coverImageUrl = self.coverImageURL {
                                self.loadImage(from: coverImageUrl, into: self.imageView)
                            }
                            self.playPauseImageView.image = UIImage(named: "PlayButton")
                            self.playPauseImageView.isHidden = false
                            self.isPlaying = false
                        }
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
            self.hideLoadingAlert()
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - addContentToStackView
    func addContentToStackView() {
        let items = [
            (icon: UIImage(named: "copylink"), title: "Copy link"),
            (icon: UIImage(named: "whatsapp"), title: "Whatsapp"),
            (icon: UIImage(named: "instagram"), title: "IG message"),
            (icon: UIImage(named: "instagram"), title: "IG story"),
            (icon: UIImage(named: "snapchat"), title: "Snap story"),
            (icon: UIImage(named: "telegram"), title: "Telegram"),
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
            label.textColor = .white
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
        
        let shouldShareDirectly = PremiumManager.shared.isContentUnlocked(itemID: -1) ||
        adsViewModel.getAdID(type: .reward) == nil || sharePrank == false
        
        switch tappedView.tag {
        case 0: // Copy link
            if let prankLink = prankShareURL {
                UIPasteboard.general.string = prankLink
                let snackbar = CustomSnackbar(message: "Link copied to clipboard!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 1:  // WhatsApp Message
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.shareWhatsAppMessage()
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.shareWhatsAppMessage()
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 2:  // Instagram Message
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.shareInstagramMessage()
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.shareInstagramMessage()
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 3:  // Instagram Story
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.NavigateToShareSnapchat(sharePrank: "Instagram")
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.NavigateToShareSnapchat(sharePrank: "Instagram")
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 4:   // Snapchat Story
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.NavigateToShareSnapchat(sharePrank: "Snapchat")
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.NavigateToShareSnapchat(sharePrank: "Snapchat")
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 5:    // Telegram Message
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.shareTelegramMessage()
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.shareTelegramMessage()
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 6:  // More
            if isConnectedToInternet() {
                if shouldShareDirectly {
                    self.shareMoreMessage()
                } else {
                    if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                        rewardAdUtility.onRewardEarned = { [weak self] in
                            self?.shareMoreMessage()
                        }
                        rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID,rootViewController: self)
                    }
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        default:
            break
        }
    }
    
    private func NavigateToShareSnapchat(sharePrank: String?) {
        guard let prankLink = prankShareURL,
              let prankName = prankName,
              let coverImageURL = coverImageURL else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bottomSheetVC = storyboard.instantiateViewController(withIdentifier: "ShareBottomVC") as! ShareBottomVC
        bottomSheetVC.coverImageURL = coverImageURL
        bottomSheetVC.prankLink = prankLink
        bottomSheetVC.prankName = prankName
        bottomSheetVC.sharePrank = sharePrank
        if UIDevice.current.userInterfaceIdiom == .pad {
            bottomSheetVC.modalPresentationStyle = .formSheet
            bottomSheetVC.preferredContentSize = CGSize(width: 540, height: 540)
        } else {
            if #available(iOS 15.0, *) {
                if let sheet = bottomSheetVC.sheetPresentationController {
                    sheet.detents = [.medium()]
                    sheet.prefersGrabberVisible = true
                }
            } else {
                bottomSheetVC.modalPresentationStyle = .custom
                bottomSheetVC.transitioningDelegate = self
            }
        }
        present(bottomSheetVC, animated: true, completion: nil)
    }
    
    private func shareWhatsAppMessage() {
        guard let prankLink = prankShareURL,
              let coverImageURL = coverImageURL,
              let prankName = prankName else { return }
        
        let message = "\(prankName)\n\n👇🏻 tap on link 👇🏻:\n\(prankLink)"
        DispatchQueue.global().async {
            if let url = URL(string: coverImageURL),
               let imageData = try? Data(contentsOf: url),
               let image = UIImage(data: imageData) {
                
                DispatchQueue.main.async {
                    let activityItems: [Any] = [message, image]
                    let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
                    activityVC.excludedActivityTypes = [.airDrop, .addToReadingList, .message, .mail, .saveToCameraRoll]
                    if let topController = self.topViewController() {
                        topController.present(activityVC, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    private func topViewController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while let presentedController = topController?.presentedViewController {
            topController = presentedController
        }
        return topController
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
        let telegramMessage = "\(prankName)\n\n👇🏻 tap on link 👇🏻:\n\(prankLink)"
        let encodedMessage = telegramMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if let url = URL(string: "tg://msg?text=\(encodedMessage ?? "")"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            if let appStoreURL = URL(string: "https://apps.apple.com/ng/app/telegram-messenger/id686449807") {
                UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
            }
        }
    }
    
    private func shareMoreMessage() {
        guard let prankLink = prankShareURL,
              let prankName = prankName else { return }
        let message = "\(prankName)\n\n👇🏻 tap on link 👇🏻:\n\(prankLink)"
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

extension SpinnerDataShowVC: AVAudioPlayerDelegate {
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

extension SpinnerDataShowVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let customPresentationController = CustomePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        customPresentationController.heightPercentage = 0.5
        return customPresentationController
    }
}
