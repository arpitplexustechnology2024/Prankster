//
//  ShareLinkVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

import UIKit
import Alamofire
import AVFAudio
import AVFoundation

class ShareLinkVC: UIViewController, UITextViewDelegate {
    
    // MARK: - IBOutlet
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var scrollViewView: UIView!
    @IBOutlet weak var prankImageView: UIImageView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var prankNameLabel: UITextView!
    @IBOutlet weak var nameChangeButton: UIButton!
    
    // MARK: - Properties
    var selectedURL: String?
    var selectedFile: Data?
    var selectedName: String?
    var selectedCoverURL: String?
    var selectedCoverFile: Data?
    var selectedPranktype: String?
    private var isPlaying = false
    private var coverImageURL: String?
    private var prankDataURL: String?
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    var bannerAdUtility = BannerAdUtility()
    private var viewModel = PrankViewModel()
    private var noDataView: NoDataBottomBarView!
    let interstitialAdUtility = InterstitialAdUtility()
    private var noInternetView: NoInternetBottombarView!
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.createPrank()
        self.setupNoDataView()
        self.setupScrollView()
        self.setupSwipeGesture()
        self.setupNoInternetView()
        self.addContentToStackView()
        self.hideKeyboardTappedAround()
        self.checkInternetAndFetchData()
        bannerAdUtility.setupBannerAd(in: self, adUnitID: "ca-app-pub-3940256099942544/2435281174")
        interstitialAdUtility.delegate = self
        Task {
            await interstitialAdUtility.loadInterstitial(adUnitID: "ca-app-pub-3940256099942544/4411468910")
        }
        self.prankNameLabel.isEditable = false
        self.prankNameLabel.delegate = self
        self.prankNameLabel.returnKeyType = .done
    }
    
    // MARK: - setupUI
    func setupUI() {
        self.shareView.layer.cornerRadius = 15
        self.prankImageView.layer.cornerRadius = 15
        self.nameChangeButton.layer.cornerRadius = nameChangeButton.frame.height / 2
    }
    
    // MARK: - checkInternetAndFetchData
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            createPrank()
            self.noInternetView?.isHidden = true
            self.scrollViewView.isHidden = false
            self.hideNoDataView()
        } else {
            self.showNoInternetView()
        }
    }
    
    // MARK: - setupScrollView
    func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollViewView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: scrollViewView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: scrollViewView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: scrollViewView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scrollViewView.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    // MARK: - createPrank
    func createPrank() {
        let coverImageURL = selectedCoverURL ?? ""
        let coverImageFile = selectedCoverFile ?? Data()
        let fileURL = selectedURL ?? ""
        let file = selectedFile ?? Data()
        let name = selectedName ?? "Unnamed Prank"
        let type = selectedPranktype ?? "Unknown"
        
        prankImageView.showShimmer()
        prankNameLabel.showShimmer()
        nameChangeButton.showShimmer()
        
        viewModel.createPrank(coverImage: coverImageFile, coverImageURL: coverImageURL, type: type, name: name, file: file, fileURL: fileURL) { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.prankImageView.hideShimmer()
                    self.prankNameLabel.hideShimmer()
                    self.nameChangeButton.hideShimmer()
                    
                    print("Prank Link :- \(self.viewModel.createPrankLink ?? "")")
                    print("Prank Link :- \(self.viewModel.createPrankData ?? "")")
                    print("Prank ID :- \(self.viewModel.createPrankID ?? "")")
                    
                    self.coverImageURL = self.viewModel.createPrankCoverImage
                    self.prankDataURL = self.viewModel.createPrankData
                    
                    if let coverImageUrl = self.coverImageURL {
                        self.loadImage(from: coverImageUrl, into: self.prankImageView)
                    }
                    
                    self.playPauseImageView.image = UIImage(named: "PlayButton")
                    self.playPauseImageView.isUserInteractionEnabled = true
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
                    self.prankImageView.isUserInteractionEnabled = true
                    self.prankImageView.addGestureRecognizer(tapGesture)
                    
                    let playPauseTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
                    self.playPauseImageView.isUserInteractionEnabled = true
                    self.playPauseImageView.addGestureRecognizer(playPauseTapGesture)
                    
                    if let prankName = self.viewModel.createPrankName {
                        self.prankNameLabel.text = prankName
                    }
                } else {
                    if let error = self.viewModel.errorMessage {
                        print("Prank failed: \(error)")
                        self.showNoDataView()
                    }
                }
            }
        }
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
        isPlaying.toggle()
        
        guard let prankDataUrl = prankDataURL else { return }
        
        if selectedPranktype == "audio" {
            if isPlaying {
                if audioPlayer == nil {
                    do {
                        let audioData = try Data(contentsOf: URL(string: prankDataUrl)!)
                        audioPlayer = try AVAudioPlayer(data: audioData)
                        audioPlayer?.prepareToPlay()
                    } catch {
                        print("Error loading audio: \(error)")
                        isPlaying = false
                        return
                    }
                }
                audioPlayer?.play()
                audioPlayer?.delegate = self
                prankImageView.image = UIImage(named: "audioPrankImage")
                playPauseImageView.isHidden = true
            } else {
                audioPlayer?.pause()
                prankImageView.image = UIImage(named: "audioPrankImage")
                playPauseImageView.image = UIImage(named: "PlayButton")
                playPauseImageView.isHidden = false
            }
        } else if selectedPranktype == "video" {
            if isPlaying {
                if videoPlayer == nil {
                    do {
                        let videoData = try Data(contentsOf: URL(string: prankDataUrl)!)
                        let temporaryDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                        let temporaryFileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
                        
                        try videoData.write(to: temporaryFileURL)
                        
                        videoPlayer = AVPlayer(url: temporaryFileURL)
                        playerLayer = AVPlayerLayer(player: videoPlayer)
                        playerLayer?.videoGravity = .resizeAspectFill
                        playerLayer?.frame = prankImageView.bounds
                        
                        if let playerLayer = playerLayer {
                            prankImageView.layer.addSublayer(playerLayer)
                        }
                    } catch {
                        print("Error loading video: \(error)")
                        isPlaying = false
                        return
                    }
                }
                
                videoPlayer?.play()
                playPauseImageView.isHidden = true
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(videoDidFinishPlaying),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: videoPlayer?.currentItem
                )
            } else {
                videoPlayer?.pause()
                playPauseImageView.image = UIImage(named: "PlayButton")
                playPauseImageView.isHidden = false
            }
        } else {
            if isPlaying {
                loadImage(from: prankDataUrl, into: prankImageView)
                playPauseImageView.isHidden = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                    if let coverImageUrl = self.coverImageURL {
                        self.loadImage(from: coverImageUrl, into: self.prankImageView)
                    }
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                    isPlaying = false
                }
            }
        }
    }
    
    @objc private func videoDidFinishPlaying() {
        DispatchQueue.main.async {
            self.videoPlayer?.seek(to: .zero)
            self.videoPlayer?.pause()
            self.isPlaying = false
            if let coverImageUrl = self.coverImageURL {
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
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
    
    // MARK: - setupNoDataView
    private func setupNoDataView() {
        noDataView = NoDataBottomBarView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        self.shareView.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: shareView.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: shareView.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: shareView.topAnchor),
            noDataView.bottomAnchor.constraint(equalTo: shareView.bottomAnchor)
        ])
        noDataView.layer.cornerRadius = 15
        noDataView.layer.masksToBounds = true
        noDataView.layoutIfNeeded()
    }
    
    // MARK: - setupNoInternetView
    func setupNoInternetView() {
        noInternetView = NoInternetBottombarView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        self.shareView.addSubview(noInternetView)
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: shareView.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: shareView.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: shareView.topAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: shareView.bottomAnchor)
        ])
        noInternetView.layer.cornerRadius = 15
        noInternetView.layer.masksToBounds = true
        noInternetView.layoutIfNeeded()
    }
    
    // MARK: - retryButtonTapped
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            hideNoDataView()
            checkInternetAndFetchData()
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
        self.scrollViewView.isHidden = true
    }
    
    private func showNoDataView() {
        noDataView?.isHidden = false
        scrollViewView.isHidden = true
    }
    
    private func hideNoDataView() {
        noDataView?.isHidden = true
        scrollViewView.isHidden = false
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - setupSwipeGesture
    private func setupSwipeGesture() {
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.edges = .left
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - addContentToStackView
    func addContentToStackView() {
        let items = [
            (icon: UIImage(named: "copylink"), title: "Copy link"),
            (icon: UIImage(named: "instagram"), title: "Message"),
            (icon: UIImage(named: "instagram"), title: "Story"),
            (icon: UIImage(named: "snapchat"), title: "Message"),
            (icon: UIImage(named: "snapchat"), title: "Story"),
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
    
    private func shareToSnapchat() {
        
        guard let prankLink = viewModel.createPrankLink,
              let prankName = viewModel.createPrankName,
              let coverImageURLString = coverImageURL,
              let coverImageURL = URL(string: coverImageURLString) else { return }
        
        let snapchatURL = URL(string: "snapchat://")
        if let url = snapchatURL, UIApplication.shared.canOpenURL(url) {
            UIPasteboard.general.string = prankLink
            let shareView = ShareView(frame: view.bounds)
            shareView.configure(with: coverImageURL, name: prankName)

            UIGraphicsBeginImageContextWithOptions(shareView.bounds.size, false, 0)
            shareView.layer.render(in: UIGraphicsGetCurrentContext()!)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let image = image {
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            }
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            self.dismiss(animated: true)
        } else {
            let snackbar = CustomSnackbar(message: "Snapchat is not installed!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    @objc private func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving photo: \(error.localizedDescription)")
        } else {
            print("Successfully saved snapchat story Image to gallery.")
        }
    }
    
//    private func shareInstagramStory() {
//        guard let prankLink = viewModel.createPrankLink,
//              let prankName = viewModel.createPrankName,
//              let coverImageURLString = coverImageURL,
//              let coverImageURL = URL(string: coverImageURLString) else { return }
//        
//        if let urlScheme = URL(string: "instagram-stories://share?source_application=com.plexustechnology.Pranksters"), UIApplication.shared.canOpenURL(urlScheme) {
//                
//                UIPasteboard.general.string = prankLink
//                
//                let screenSize = UIScreen.main.bounds.size
//                let targetAspectRatio: CGFloat = 9.0 / 16.0
//                let screenAspectRatio = screenSize.width / screenSize.height
//                
//                var targetSize: CGSize
//                
//                if screenAspectRatio > targetAspectRatio {
//                    targetSize = CGSize(width: screenSize.height * targetAspectRatio, height: screenSize.height)
//                } else {
//                    targetSize = CGSize(width: screenSize.width, height: screenSize.width / targetAspectRatio)
//                }
//                let shareView = ShareView(frame: CGRect(origin: .zero, size: targetSize))
//                shareView.configure(with: coverImageURL, name: prankName)
//                
//                shareView.center = CGPoint(x: screenSize.width / 2, y: screenSize.height / 2)
//                shareView.layoutIfNeeded()
//                UIGraphicsBeginImageContextWithOptions(targetSize, false, UIScreen.main.scale)
//                guard let context = UIGraphicsGetCurrentContext() else { return }
//                shareView.layer.render(in: context)
//                let image = UIGraphicsGetImageFromCurrentImageContext()
//                UIGraphicsEndImageContext()
//                
//                if let imageData = image?.pngData() {
//                    if let url = URL(string: prankLink) {
//                        let items: [String: Any] = [
//                            "com.instagram.sharedSticker.backgroundImage": imageData,
//                            "com.instagram.sharedSticker.contentURL": url,
//                        ]
//                        UIPasteboard.general.setItems([items])
//                      //  UIPasteboard.general.setItems([items], options: [.expirationDate: Date().addingTimeInterval(60 * 5)])
//                        UIApplication.shared.open(urlScheme, options: [:], completionHandler: nil)
//                    }
//                }
//                self.dismiss(animated: true)
//            } else {
//                let snackbar = CustomSnackbar(message: "Instagram is not installed!", backgroundColor: .snackbar)
//                snackbar.show(in: self.view, duration: 3.0)
//            }
//    }
    
    private func shareInstagramStory() {
        guard let prankLink = viewModel.createPrankLink,
              let encodedLink = prankLink.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            // Show error if link is invalid
            let snackbar = CustomSnackbar(message: "Invalid link!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        // Instagram Stories URL scheme for sharing a link
        guard let urlScheme = URL(string: "instagram-stories://share?source_application=com.plexustechnology.Pranksters&source_url=\(encodedLink)") else {
            return
        }
        
        // Check if Instagram is installed
        if UIApplication.shared.canOpenURL(urlScheme) {
            // Attempt to open Instagram Stories with the link
            UIApplication.shared.open(urlScheme, options: [:]) { success in
                if !success {
                    // Show error if opening failed
                    DispatchQueue.main.async {
                        let snackbar = CustomSnackbar(message: "Could not open Instagram!", backgroundColor: .snackbar)
                        snackbar.show(in: self.view, duration: 3.0)
                    }
                }
            }
        } else {
            // Show error if Instagram is not installed
            let snackbar = CustomSnackbar(message: "Instagram is not installed!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    // MARK: - viewTapped
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        
        switch tappedView.tag {
        case 0: // Copy link
            if let prankLink = viewModel.createPrankLink {
                UIPasteboard.general.string = prankLink
                let snackbar = CustomSnackbar(message: "Link copied to clipboard!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        case 1:  // Instagram Message
          // interstitialAdUtility.presentInterstitial(from: self)
            guard let prankLink = viewModel.createPrankLink,
                  let prankName = viewModel.createPrankName else { return }
            let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
            if let url = URL(string: "instagram://sharesheet?text=\(message)") {
               UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            
        case 2:  // Instagram Story
            interstitialAdUtility.presentInterstitial(from: self)
        case 3:  // Snapchat Message
            if let prankLink = viewModel.createPrankLink,
               let coverImageURL = viewModel.createPrankCoverImage {
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
            shareToSnapchat()
        case 5: // WhatsApp Message
            guard let prankLink = viewModel.createPrankLink,
                  let prankName = viewModel.createPrankName,
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
        case 6: // More
            //  sharePrank()
            shareViaWhatsAppMessage()
        default:
            break
        }
    }
    
    func shareViaSnapchatMessage() {
        guard let prankLink = viewModel.createPrankLink,
              let prankName = viewModel.createPrankName,
              let coverImageURL = coverImageURL else { return }
        
        AF.request(coverImageURL).responseData { [weak self] response in
            switch response.result {
            case .success(let imageData):
                guard let image = UIImage(data: imageData) else { return }
                
                let message = "\(prankName)\n\n🔗 Check it out: \(prankLink)"
                
                if let imageURL = self?.saveImageToTemporaryFile(image: image) {
                    // Snapchat's URL scheme for sharing
                    let snapchatURL = URL(string: "snapchat://post?media=file://\(imageURL.path)&caption=\(message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
                    
                    if let url = snapchatURL, UIApplication.shared.canOpenURL(url) {
                        UIApplication.shared.open(url, options: [:], completionHandler: nil)
                    } else {
                        // Fallback to standard share sheet if Snapchat is not installed
                        self?.openShareSheetWithImageAndLink(image: image, link: message)
                    }
                }
                
            case .failure:
                self?.openShareSheetWithLink(prankLink)
            }
        }
    }
    
    func sharePrank() {
        guard let prankLink = viewModel.createPrankLink,
              let prankName = viewModel.createPrankName,
              let coverImageURL = coverImageURL else { return }
        
        AF.request(coverImageURL).responseData { [weak self] response in
            switch response.result {
            case .success(let imageData):
                guard let image = UIImage(data: imageData) else { return }
                
                let message = "\(prankName)\n\n🔗 Check it out:\(prankLink)"
                self?.openShareSheetWithImageAndLink(image: image, link: message)
            case .failure:
                self?.openShareSheetWithLink(prankLink)
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
        guard let prankLink = viewModel.createPrankLink,
              let prankName = viewModel.createPrankName,
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
    
    // MARK: - btnNameChangeTapped
    @IBAction func btnNameChangeTapped(_ sender: UIButton) {
        prankNameLabel.isEditable = true
        prankNameLabel.becomeFirstResponder()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            textView.isEditable = false
            guard let updatedName = prankNameLabel.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !updatedName.isEmpty else {
                print("Name cannot be empty")
                return false
            }

            guard let prankID = viewModel.createPrankID else {
                print("Prank ID not available")
                return false
            }
            
            viewModel.updatePrankName(id: prankID, name: updatedName) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let success):
                        print(success.message)
                        self.viewModel.createPrankName = updatedName
                    case .failure(let failure):
                        print(failure.localizedDescription)
                        self.prankNameLabel.text = self.viewModel.createPrankName
                    }
                }
            }
            return false
        }
        return true
    }
    
    // MARK: - btnBackTapped
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ShareLinkVC: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            if let coverImageUrl = self.coverImageURL {
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
            }
            self.playPauseImageView.image = UIImage(named: "PlayButton")
            self.playPauseImageView.isHidden = false
            self.audioPlayer = nil
        }
    }
}

extension ShareLinkVC: InterstitialAdUtilityDelegate {
        
        // MARK: - InterstitialAdUtilityDelegate
        func didFailToLoadInterstitial() {
            navigateToSecondViewController()
        }
        
        func didFailToPresentInterstitial() {
            navigateToSecondViewController()
        }
        
        func didDismissInterstitial() {
            navigateToSecondViewController()
        }
        
        private func navigateToSecondViewController() {
            shareInstagramStory()
        }
}
