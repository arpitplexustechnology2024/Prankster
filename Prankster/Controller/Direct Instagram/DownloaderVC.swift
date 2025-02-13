//
//  DownloaderVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 11/02/25.
//

import UIKit
import Alamofire
import AVFoundation

@available(iOS 15.0, *)
class DownloaderVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var nativeSmallAds: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var adHeightConstaints: NSLayoutConstraint!
    @IBOutlet weak var CancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var videoPlayerView: UIView!
    @IBOutlet weak var topView: UIView!
    
    @IBOutlet weak var downloadImageView: UIImageView!
    @IBOutlet weak var instaView: UIView!
    @IBOutlet weak var snapView: UIView!
    
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    // MARK: - Properties
    private var downloadedVideoURL: URL?
    private var downloadedVideoStringURL: String?
    private var loadingAlertView: LoadingAlertView?
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    let interstitialAdUtility = InterstitialAdUtility()
    private var adsViewModel: AdsViewModel!
    
    private var socialViewModule: SocialViewModule!
    
    // MARK: - Initialization
    init(socialViewModule: SocialViewModule, adViewModule: AdsViewModel) {
        self.socialViewModule = socialViewModule
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.socialViewModule = SocialViewModule(apiService: SocialAPIManger.shared)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.layer.cornerRadius = 28
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNotification()
        self.hideKeyboardTappedAround()
        self.setupKeyboardObservers()
        self.topView.clipsToBounds = true
        self.topView.layer.cornerRadius = 15
        self.topView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        self.videoPlayerView.isHidden = true
        self.downloadImageView.isHidden = false
        self.videoPlayerView.layer.cornerRadius = 10
        self.searchView.layer.cornerRadius = searchView.layer.frame.height / 2
        self.snapView.layer.cornerRadius = 13
        self.instaView.layer.cornerRadius = 13
        self.CancelButton.isHidden = true
        self.doneButton.isHidden = true
        self.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Paste Link",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        
        self.searchTextField.delegate = self
        self.searchTextField.returnKeyType = .done
        
        setupAds()
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(setUrl),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setUrl()
    }
    
    @objc func setUrl() {
        if let incomingURL = UserDefaults(suiteName: "group.com.prank.memes.fun")?.value(forKey: "incomingURL") as? String {
            searchTextField.text = incomingURL
            UserDefaults(suiteName: "group.com.prank.memes.fun")?.removeObject(forKey: "incomingURL")
        }
    }
    
    private func setupAds() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.adHeightConstaints.constant = 150
            if isConnectedToInternet() {
                if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                    nativeSmallAds.isHidden = true
                } else {
                    if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
                        print("Native Ad ID: \(nativeAdID)")
                        nativeSmallIpadAdUtility = NativeSmallIpadAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                    } else {
                        print("No Native Ad ID found")
                        nativeSmallAds.isHidden = true
                    }
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        } else {
            self.adHeightConstaints.constant = 120
            if isConnectedToInternet() {
                if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                    nativeSmallAds.isHidden = true
                } else {
                    if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
                        print("Native Ad ID: \(nativeAdID)")
                        nativeSmallIphoneAdUtility = NativeSmallIphoneAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                    } else {
                        print("No Native Ad ID found")
                        nativeSmallAds.isHidden = true
                    }
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoPlayerView.bounds
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    private func startLoading() {
        if loadingAlertView == nil {
            loadingAlertView = LoadingAlertView(frame: view.bounds)
            loadingAlertView?.translatesAutoresizingMaskIntoConstraints = false
            if let loadingView = loadingAlertView {
                view.addSubview(loadingView)
                NSLayoutConstraint.activate([
                    loadingView.topAnchor.constraint(equalTo: view.topAnchor),
                    loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                    loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
                ])
            }
        }
        loadingAlertView?.startAnimating()
    }
    
    private func stopLoading() {
        loadingAlertView?.stopAnimating()
        loadingAlertView?.removeFromSuperview()
        loadingAlertView = nil
    }
    
    
    // MARK: - Video Handling Methods
    private func handleVideoDownload(videoURL: URL) {
        VideoProcessingManager.shared.downloadVideo(from: videoURL) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let downloadedURL):
                    self?.processDownloadedVideo(downloadedURL)
                case .failure(let error):
                    self?.stopLoading()
                    self?.showError(error.message)
                }
            }
        }
    }
    
    private func processDownloadedVideo(_ url: URL) {
        VideoProcessingManager.shared.compressVideo(inputURL: url) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let processedURL):
                    self?.downloadedVideoURL = processedURL
                    self?.setupVideoPlayer(with: processedURL)
                case .failure(let error):
                    self?.stopLoading()
                    self?.showError(error.message)
                }
            }
        }
    }
    
    private func setupVideoPlayer(with url: URL) {
        playerLayer?.removeFromSuperlayer()
        
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPlayerView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        if let playerLayer = playerLayer {
            videoPlayerView.layer.addSublayer(playerLayer)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerItemDidReachEnd), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
        
        videoPlayerView.isHidden = false
        doneButton.isHidden = false
        downloadImageView.isHidden = true
        
        player?.play()
        stopLoading()
    }
    
    @objc func playerItemDidReachEnd() {
        player?.seek(to: .zero)
        player?.play()
    }
    
    @objc private func doneButtonTapped() {
        player?.pause()
        player = nil
        
        if isConnectedToInternet() {
            let coverVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CoverBottomVC") as! CoverBottomVC
            coverVC.DownloadURL = downloadedVideoStringURL
            if let sheet = coverVC.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.preferredCornerRadius = 28
                sheet.prefersGrabberVisible = true
            }
            present(coverVC, animated: true)
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }

    
    private func showError(_ message: String) {
        stopLoading()
        let snackbar = CustomSnackbar(message: message, backgroundColor: .snackbar)
        snackbar.show(in: view, duration: 3.0)
    }
    
    
    @IBAction func btnDownloadTapped(_ sender: UIButton) {
        
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let shouldShowAd = !isContentUnlocked && adsViewModel.getAdID(type: .interstitial) != nil
        
        if isConnectedToInternet() {
            if shouldShowAd {
                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                    interstitialAdUtility.onInterstitialEarned = { [weak self] in
                        self?.startLoading()
                        self?.processDownload()
                    }
                    interstitialAdUtility.loadAndShowAd(adUnitID: interstitialAdID, rootViewController: self)
                }
            } else {
                processDownload()
            }
        } else {
            self.stopLoading()
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    private func processDownload() {
        guard let urlString = searchTextField.text, !urlString.isEmpty,
              let videoURL = URL(string: urlString) else {
            self.stopLoading()
            showError("Please enter a valid URL")
            return
        }
        
        self.socialViewModule.fetchSocial(url: urlString) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let socialResponse):
                    self.downloadedVideoStringURL = socialResponse.data
                    if let videoURL = URL(string: socialResponse.data) {
                        self.handleVideoDownload(videoURL: videoURL)
                    } else {
                        self.stopLoading()
                        self.showError("Invalid video URL")
                    }
                case .failure(let error):
                    self.stopLoading()
                    self.showError("Download Failed")
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
    }
    
    @IBAction func btnCancelTapped(_ sender: UIButton) {
        searchTextField.text = ""
        searchTextField.resignFirstResponder()
        CancelButton.isHidden = true
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "HomeVC") as! HomeVC
        self.navigationController?.pushViewController(vc, animated: false)
        
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text, !text.isEmpty {
            CancelButton.isHidden = false
        } else {
            CancelButton.isHidden = true
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if let text = textField.text, text.isEmpty {
            CancelButton.isHidden = true
        }
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let keyboardHeight = keyboardFrame.height
        let textViewBottomY = searchTextField.convert(searchTextField.bounds, to: view).maxY
        let overlap = textViewBottomY - (view.frame.height - keyboardHeight)
        
        let additionalSpace: CGFloat = 50
        
        if overlap > 0 {
            UIView.animate(withDuration: 0.3) {
                self.view.frame.origin.y = -(overlap + additionalSpace)
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y = 0
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.removeObserver(self)
    }
}
