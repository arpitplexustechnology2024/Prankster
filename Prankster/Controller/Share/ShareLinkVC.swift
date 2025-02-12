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
import StoreKit

class ShareLinkVC: UIViewController, UITextViewDelegate {
    
    // MARK: - IBOutlet
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var scrollViewView: UIView!
    @IBOutlet weak var prankImageView: UIImageView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var prankNameLabel: UITextView!
    @IBOutlet weak var nameChangeButton: UIButton!
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    
    // MARK: - Properties
    var selectedURL: String?
    var selectedFile: Data?
    var selectedName: String?
    var selectedCoverURL: String?
    var selectedCoverFile: Data?
    var selectedPranktype: String?
    var selectedFileType: String?
    var selectedImage: String?
    private var isPlaying = false
    var coverImageURL: String?
    var prankDataURL: String?
    var prankName: String?
    var prankLink: String?
    var prankAudioImage: String?
    var prankShareURL: String?
    var sharePrank: Bool = false
    private var adsViewModel: AdsViewModel!
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    var bannerAdUtility = BannerAdUtility()
    private var viewModel: PrankViewModel!
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    private var loadingAlert: LoadingAlertView?
    private let rewardAdUtility = RewardAdUtility()
    private var skeletonLoadingView: SkeletonShareLoadingView?
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    init(viewModule: PrankViewModel, adsViewModel: AdsViewModel) {
        self.viewModel = viewModule
        self.adsViewModel = adsViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = PrankViewModel(apiService: PrankAPIManager.shared)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSkeletonView()
        self.setupUI()
        self.setupNoDataView()
        self.setupScrollView()
        self.setupSwipeGesture()
        self.setupNoInternetView()
        self.addContentToStackView()
        
        print(selectedURL)
        print(selectedFile)
        print(selectedImage)
    }
    
    private func setupSkeletonView() {
        skeletonLoadingView = SkeletonShareLoadingView()
        skeletonLoadingView?.translatesAutoresizingMaskIntoConstraints = false
        
        if let skeletonView = skeletonLoadingView {
            view.addSubview(skeletonView)
            
            NSLayoutConstraint.activate([
                skeletonView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
                skeletonView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                skeletonView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                skeletonView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        }
    }
    
    func rateUs() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            print(" - - - - - - Rating view in not present - - - -")
        }
    }
    
    private func showLoadingAlert() {
        loadingAlert = LoadingAlertView(frame: view.bounds)
        if let loadingAlert = loadingAlert {
            view.addSubview(loadingAlert)
            loadingAlert.startAnimating()
        }
    }
    
    private func hideLoadingAlert() {
        DispatchQueue.main.async {
            self.loadingAlert?.removeFromSuperview()
            self.loadingAlert = nil
        }
    }
    
    // MARK: - setupUI
    func setupUI() {
        self.shareView.layer.cornerRadius = 15
        self.prankImageView.layer.cornerRadius = 15
        self.nameChangeButton.layer.cornerRadius = nameChangeButton.frame.height / 2
        self.playPauseImageView.image = UIImage(named: "PlayButton")
        self.playPauseImageView.isUserInteractionEnabled = true
        self.playPauseImageView.isHidden = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.prankImageView.isUserInteractionEnabled = true
        self.prankImageView.addGestureRecognizer(tapGesture)
        
        let playPauseTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.playPauseImageView.isUserInteractionEnabled = true
        self.playPauseImageView.addGestureRecognizer(playPauseTapGesture)
        
        if sharePrank {
            self.checkInternetAndFetchData()
            self.nameChangeButton.isHidden = false
        } else {
            self.nameChangeButton.isHidden = true
            self.prankNameLabel.text = self.prankName
            
            if let coverImageUrl = self.coverImageURL {
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            bottomConstraints.constant = 100
        } else {
            bottomConstraints.constant = 75
        }
        
        if isConnectedToInternet() {
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    bottomConstraints.constant = 16
                } else {
                    bottomConstraints.constant = 16
                }
            } else {
                if let bannerAdID = adsViewModel.getAdID(type: .banner) {
                    print("Banner Ad ID: \(bannerAdID)")
                    bannerAdUtility.setupBannerAd(in: self, adUnitID: bannerAdID)
                } else {
                    print("No Banner Ad ID found")
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        bottomConstraints.constant = 16
                    } else {
                        bottomConstraints.constant = 16
                    }
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
        
        self.prankNameLabel.isEditable = false
        self.prankNameLabel.delegate = self
        self.prankNameLabel.returnKeyType = .done
    }
    
    // MARK: - checkInternetAndFetchData
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            createPrank()
            self.noInternetView?.isHidden = true
            self.scrollViewView.isHidden = false
            self.playPauseImageView.isHidden = false
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
        let fileType = selectedFileType ?? ""
        let imageURL = selectedImage ?? ""
        
        skeletonLoadingView?.startAnimating()
        prankImageView.isHidden = true
        playPauseImageView.isHidden = true
        prankNameLabel.isHidden = true
        scrollViewView.isHidden = true
        
        viewModel.createPrank(coverImage: coverImageFile, coverImageURL: coverImageURL, type: type, name: name, file: file, fileURL: fileURL, imageURL: imageURL, fileType: fileType) { [weak self] success in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if success {
                    self.savePrankToUserDefaults()
                    self.skeletonLoadingView?.stopAnimating()
                    self.skeletonLoadingView?.isHidden = true
                    self.prankImageView.isHidden = false
                    self.playPauseImageView.isHidden = false
                    self.prankNameLabel.isHidden = false
                    self.scrollViewView.isHidden = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.rateUs()
                    }
                    
                    print("Prank Link :- \(self.viewModel.createPrankShareURL ?? "")")
                    print("Prank Data :- \(self.viewModel.createPrankData ?? "")")
                    print("Prank ID :- \(self.viewModel.createPrankID ?? "")")
                    
                    self.coverImageURL = self.viewModel.createPrankCoverImage
                    self.prankDataURL = self.viewModel.createPrankData
                    self.prankName = self.viewModel.createPrankName
                    self.prankLink = self.viewModel.createPrankShareURL
                    self.prankShareURL = self.viewModel.createPrankShareURL
                    self.prankNameLabel.text = self.prankName
                    self.prankAudioImage = self.viewModel.createPrankImage
                    
                    if let coverImageUrl = self.coverImageURL {
                        self.loadImage(from: coverImageUrl, into: self.prankImageView)
                    }
                    
                    self.playPauseImageView.image = UIImage(named: "PlayButton")
                    self.playPauseImageView.isUserInteractionEnabled = true
                    self.playPauseImageView.isHidden = false
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
                    self.prankImageView.isUserInteractionEnabled = true
                    self.prankImageView.addGestureRecognizer(tapGesture)
                    
                    let playPauseTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
                    self.playPauseImageView.isUserInteractionEnabled = true
                    self.playPauseImageView.addGestureRecognizer(playPauseTapGesture)
                } else {
                    if let error = self.viewModel.errorMessage {
                        print("Prank failed: \(error)")
                        self.showNoDataView()
                    }
                }
            }
        }
    }
    
    private func loadImage(from urlString: String, into imageView: UIImageView, completion: (() -> Void)? = nil) {
        
        AF.request(urlString).response { response in
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
                    imageView.image = UIImage(named: "imageplacholder")
                    completion?()
                }
            }
        }
    }
    
    @objc private func togglePlayPause() {
        if isConnectedToInternet() {
            isPlaying.toggle()
            
            guard let prankDataUrl = prankDataURL else { return }
            
            if selectedPranktype == "audio" {
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
                                    if let audioImageUrl = self.prankAudioImage {
                                        self.loadImage(from: audioImageUrl, into: self.prankImageView)
                                    }
                                    self.playPauseImageView.isHidden = true
                                } catch {
                                    print("Error creating audio player: \(error)")
                                    self.isPlaying = false
                                }
                            }
                        }.resume()
                    } else {
                        audioPlayer?.play()
                        playPauseImageView.isHidden = true
                    }
                } else {
                    audioPlayer?.pause()
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                }
            } else if selectedPranktype == "video" {
                if isPlaying {
                    showLoadingAlert()
                    
                    if videoPlayer == nil {
                        URLSession.shared.dataTask(with: URL(string: prankDataUrl)!) { [weak self] (data, response, error) in
                            guard let self = self, let data = data else {
                                print("Error loading video: \(error?.localizedDescription ?? "Unknown error")")
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
                                    self.playerLayer?.frame = self.prankImageView.bounds
                                    
                                    if let playerLayer = self.playerLayer {
                                        self.prankImageView.layer.addSublayer(playerLayer)
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
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
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
    
    // MARK: - setupNoDataView
    private func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        self.shareView.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
    }
    
    // MARK: - setupNoInternetView
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        self.shareView.addSubview(noInternetView)
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - retryButtonTapped
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            hideNoDataView()
            checkInternetAndFetchData()
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    bottomConstraints.constant = 16
                } else {
                    bottomConstraints.constant = 16
                }
            } else {
                if let bannerAdID = adsViewModel.getAdID(type: .banner) {
                    print("Banner Ad ID: \(bannerAdID)")
                    bannerAdUtility.setupBannerAd(in: self, adUnitID: bannerAdID)
                } else {
                    print("No Banner Ad ID found")
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        bottomConstraints.constant = 16
                    } else {
                        bottomConstraints.constant = 16
                    }
                }
                
                if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                    print("Reward Ad ID: \(rewardAdID)")
                    rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID, rootViewController: self)
                } else {
                    print("No Reward Ad ID found")
                }
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    private func navigateToSecondViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let bottomSheetVC = storyboard.instantiateViewController(withIdentifier: "ShareBottomVC") as! ShareBottomVC
        if UIDevice.current.userInterfaceIdiom == .pad {
            bottomSheetVC.modalPresentationStyle = .formSheet
            bottomSheetVC.preferredContentSize = CGSize(width: 540, height: 540)
        } else {
            bottomSheetVC.modalPresentationStyle = .custom
            bottomSheetVC.transitioningDelegate = self
            present(bottomSheetVC, animated: true, completion: nil)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
        self.scrollViewView.isHidden = true
        self.playPauseImageView.isHidden = true
    }
    
    private func showNoDataView() {
        noDataView?.isHidden = false
        scrollViewView.isHidden = true
        self.playPauseImageView.isHidden = true
    }
    
    private func hideNoDataView() {
        noDataView?.isHidden = true
        scrollViewView.isHidden = false
        self.playPauseImageView.isHidden = false
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
        let activityVC = UIActivityViewController(activityItems: [message], applicationActivities: nil)
        
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(activityVC, animated: true, completion: nil)
    }
    
    // MARK: - btnNameChangeTapped
    @IBAction func btnNameChangeTapped(_ sender: UIButton) {
        if isConnectedToInternet() {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let popupVC = storyboard.instantiateViewController(withIdentifier: "SharePrankPopupVC") as! SharePrankPopupVC
            popupVC.currentPrankName = self.prankName
            popupVC.onSave = { [weak self] newName in
                self?.updatePrankName(newName: newName)
            }
            popupVC.modalPresentationStyle = .overCurrentContext
            popupVC.modalTransitionStyle = .crossDissolve
            present(popupVC, animated: true)
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    private func updatePrankName(newName: String) {
        guard let prankID = viewModel.createPrankID else {
            print("Prank ID not available")
            return
        }
        
        viewModel.updatePrankName(id: prankID, name: newName) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let success):
                    print(success.message)
                    self.prankName = newName
                    self.prankNameLabel.text = newName
                    
                    if var savedPranks = self.fetchSavedPrank() {
                        if let index = savedPranks.firstIndex(where: { $0.id == prankID }) {
                            savedPranks[index].name = newName
                            
                            if let encodedData = try? JSONEncoder().encode(savedPranks) {
                                UserDefaults.standard.set(encodedData, forKey: "SavedPranks")
                            }
                        }
                    }
                    
                case .failure(let failure):
                    print(failure.localizedDescription)
                    self.prankNameLabel.text = self.viewModel.createPrankName
                }
            }
        }
    }
    
    func fetchSavedPrank() -> [PrankCreateData]? {
        if let savedPranksData = UserDefaults.standard.data(forKey: "SavedPranks"),
           let savedPranks = try? JSONDecoder().decode([PrankCreateData].self, from: savedPranksData) {
            return savedPranks
        }
        return nil
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

extension ShareLinkVC {
    func savePrankToUserDefaults() {
        var savedPranks = fetchSavedPranks()
        
        let newPrank = PrankCreateData(
            id: viewModel.createPrankID ?? "",
            link: viewModel.createPrankLink ?? "",
            coverImage: viewModel.createPrankCoverImage ?? "", shareURL: viewModel.createPrankShareURL ?? "",
            file: viewModel.createPrankData ?? "",
            image: viewModel.createPrankImage ?? "",
            type: selectedPranktype ?? "",
            name: viewModel.createPrankName ?? ""
        )
        savedPranks.append(newPrank)
        
        if let encodedData = try? JSONEncoder().encode(savedPranks) {
            UserDefaults.standard.set(encodedData, forKey: "SavedPranks")
        }
    }
    
    func fetchSavedPranks() -> [PrankCreateData] {
        if let savedPranksData = UserDefaults.standard.data(forKey: "SavedPranks"),
           let savedPranks = try? JSONDecoder().decode([PrankCreateData].self, from: savedPranksData) {
            return savedPranks
        }
        return []
    }
}

extension ShareLinkVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let customPresentationController = CustomePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        customPresentationController.heightPercentage = 0.5
        return customPresentationController
    }
}
