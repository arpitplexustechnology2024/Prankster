//
//  VideoDownloaderBottom.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit
import Alamofire
import AVFoundation

class VideoDownloaderBottom: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var nativeSmallAds: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var pasteBUTTON: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var adHeightConstaints: NSLayoutConstraint!
    @IBOutlet weak var CancelButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var customSwitchContainer: UIView!
    @IBOutlet weak var videoPlayerView: UIView!
    
    private var customSwitch: CustomSwitch!
    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    
    // MARK: - Properties
    var videoDownloadedCallback: ((URL?, String?) -> Void)?
    private var downloadedVideoURL: URL?
    private var downloadedVideoStringURL: String?
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    let interstitialAdUtility = InterstitialAdUtility()
    private var adsViewModel: AdsViewModel!
    
    private var socialViewModule: SocialViewModule!
    
    private var currentPlatform: SocialPlatform = .instagram
    
    private enum SocialPlatform {
        case instagram
        case snapchat
        
        var sliderImages: [DownloadGIFModel] {
            switch self {
            case .instagram:
                return [
                    DownloadGIFModel(image: UIImage(named: "DownloadImage01")),
                    DownloadGIFModel(image: UIImage(named: "DownloadImage02"))
                ]
            case .snapchat:
                return [
                    DownloadGIFModel(image: UIImage(named: "DownloadImage03")),
                    DownloadGIFModel(image: UIImage(named: "DownloadImage02"))
                ]
            }
        }
    }
    
    private var gifSlider: [DownloadGIFModel] = []
    private var currentPage = 0 {
        didSet {
            updateCurrentPage()
        }
    }
    
    private var autoScrollTimer: Timer?
    
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
        self.setupUI()
        self.setupCustomSwitch()
        self.setupLoadingIndicator()
        self.hideKeyboardTappedAround()
        self.setupKeyboardObservers()
        self.videoPlayerView.isHidden = true
        self.videoPlayerView.layer.cornerRadius = 10
        self.downloadButton.layer.cornerRadius = downloadButton.layer.frame.height / 2
        self.pasteBUTTON.layer.cornerRadius = pasteBUTTON.layer.frame.height / 2
        self.pasteBUTTON.layer.borderWidth = 1
        self.pasteBUTTON.layer.borderColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
        self.searchView.layer.cornerRadius = 14
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
        startAutoScrolling()
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
        stopAutoScrolling()
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
    
    private func setupUI() {
        gifSlider = currentPlatform.sliderImages
        pageControl.numberOfPages = gifSlider.count
    }
    
    private func updateCurrentPage() {
        pageControl.currentPage = currentPage
    }
    
    private func startAutoScrolling() {
        autoScrollTimer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(moveToNext), userInfo: nil, repeats: true)
    }
    
    private func stopAutoScrolling() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }
    
    @objc private func moveToNext() {
        if currentPage < gifSlider.count - 1 {
            currentPage += 1
        } else {
            currentPage = 0
        }
        
        let indexPath = IndexPath(item: currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        updateCurrentPage()
    }
    
    private func setupCustomSwitch() {
        customSwitch = CustomSwitch(frame: CGRect(x: 0, y: 0, width: customSwitchContainer.frame.width, height: customSwitchContainer.frame.height))
        customSwitchContainer.addSubview(customSwitch)
        customSwitch.addTarget(self, action: #selector(switchValueChanged), for: .valueChanged)
    }
    
    @objc func switchValueChanged(sender: CustomSwitch) {
        if sender.isSwitchOn {
            currentPlatform = .snapchat
        } else {
            currentPlatform = .instagram
        }
        
        gifSlider = currentPlatform.sliderImages
        
        currentPage = 0
        
        collectionView.reloadData()
        
        pageControl.numberOfPages = gifSlider.count
        updateCurrentPage()
        
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    private func setupLoadingIndicator() {
        activityIndicator.color = .black
        activityIndicator.style = .medium
        activityIndicator.hidesWhenStopped = true
        
        downloadButton.addSubview(activityIndicator)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: downloadButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: downloadButton.centerYAnchor)
        ])
    }
    
    private func startLoading() {
        downloadButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        downloadButton.isEnabled = false
    }
    
    private func stopLoading() {
        downloadButton.setTitle("Download", for: .normal)
        activityIndicator.stopAnimating()
        downloadButton.isEnabled = true
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
        
        collectionView.isHidden = true
        pageControl.isHidden = true
        videoPlayerView.isHidden = false
        doneButton.isHidden = false
        
        player?.play()
        stopLoading()
    }
    
    @objc private func doneButtonTapped() {
        if let videoURL = downloadedVideoURL {
            videoDownloadedCallback?(videoURL, downloadedVideoStringURL)
            dismiss(animated: true)
        }
    }
    
    private func showError(_ message: String) {
        stopLoading()
        let snackbar = CustomSnackbar(message: message, backgroundColor: .snackbar)
        snackbar.show(in: view, duration: 3.0)
    }
    
    @IBAction func btnPasteTapped(_ sender: UIButton) {
        if let pastedText = UIPasteboard.general.string {
            searchTextField.text = pastedText
            CancelButton.isHidden = false
        } else {
            print("No text found in clipboard.")
        }
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
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK: - UICollectionView DataSource
extension VideoDownloaderBottom: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifSlider.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DownloadImageCell", for: indexPath) as! DownloadImageCell
        cell.setupCell(gifSlider[indexPath.row])
        return cell
    }
}

//MARK: - UICollectionView Delegates
extension VideoDownloaderBottom: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}

//MARK: - UICollectionView Delegate FlowLayout
extension VideoDownloaderBottom: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

