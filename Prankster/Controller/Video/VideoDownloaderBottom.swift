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
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var doneButton: UIButton!
    
    @IBOutlet weak var customSwitchContainer: UIView!
    private var customSwitch: CustomSwitch!
    
    // MARK: - Properties
    var videoDownloadedCallback: ((URL?, String?) -> Void)?
    private var downloadedVideoURL: URL?
    private var downloadedVideoStringURL: String?
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    let interstitialAdUtility = InterstitialAdUtility()
    private let adsViewModel = AdsViewModel()
    
    private var socialViewModule: SocialViewModule!
    
    private var gifSlider: [DownloadGIFModel] = []
    private var currentPage = 0 {
        didSet {
            updateCurrentPage()
        }
    }
    
    private var autoScrollTimer: Timer?
    
    // MARK: - Initialization
    init(socialViewModule: SocialViewModule) {
        self.socialViewModule = socialViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.socialViewModule = SocialViewModule(apiService: SocialAPIManger.shared)
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
        self.downloadButton.layer.cornerRadius = downloadButton.layer.frame.height / 2
        self.pasteBUTTON.layer.cornerRadius = pasteBUTTON.layer.frame.height / 2
        self.pasteBUTTON.layer.borderWidth = 1
        self.pasteBUTTON.layer.borderColor = #colorLiteral(red: 1, green: 0.8470588235, blue: 0, alpha: 1)
        self.searchView.layer.cornerRadius = 14
        self.previewImageView.layer.cornerRadius = 10
        self.CancelButton.isHidden = true
        self.previewImageView.isHidden = true
        self.doneButton.isHidden = true
        self.doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Paste Link",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray]
        )
        
        self.searchTextField.delegate = self
        self.searchTextField.returnKeyType = .done
        
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
        
        if isConnectedToInternet() {
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
            } else {
                if let interstitialAdID = adsViewModel.getAdID(type: .interstitial) {
                    print("Interstitial Ad ID: \(interstitialAdID)")
                    interstitialAdUtility.loadInterstitialAd(adUnitID: interstitialAdID, rootViewController: self)
                } else {
                    print("No Interstitial Ad ID found")
                }
            }
        }
        
        startAutoScrolling()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        stopAutoScrolling()
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    private func setupUI() {
        gifSlider = [
            DownloadGIFModel(image: UIImage(named: "DownloadImage01")),
            DownloadGIFModel(image: UIImage(named: "DownloadImage02"))
        ]
        
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

        } else {
 
        }
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
    
    // MARK: - Video Processing Methods
    private func loadVideoFromURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            showError("Invalid video URL")
            return
        }
        
        let session = URLSession(configuration: .default)
        let task = session.downloadTask(with: url) { [weak self] (tempLocalUrl, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self?.showError("Download failed: \(error.localizedDescription)")
                    self?.stopLoading()
                    return
                }
                
                guard let tempLocalUrl = tempLocalUrl else {
                    self?.showError("Failed to download video")
                    self?.stopLoading()
                    return
                }
                
                self?.processDownloadedVideo(tempLocalUrl)
            }
        }
        task.resume()
    }
    
    private func processDownloadedVideo(_ url: URL) {
        VideoProcessingManager.shared.processVideo(from: url) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let processedURL):
                    self.downloadedVideoURL = processedURL
                    self.downloadedVideoStringURL = url.absoluteString
                    self.showDownloadedVideo(processedURL)
                    
                case .failure(let error):
                    self.showError(error.message)
                    self.stopLoading()
                }
            }
        }
    }
    
    private func showDownloadedVideo(_ url: URL) {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: .zero, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            collectionView.isHidden = true
            pageControl.isHidden = true
            previewImageView.image = thumbnail
            previewImageView.isHidden = false
            doneButton.isHidden = false
            
        } catch {
            showError("Failed to generate video preview")
        }
        stopLoading()
    }
    
    
    @objc private func doneButtonTapped() {
        if let videoURL = downloadedVideoURL {
            videoDownloadedCallback?(videoURL, downloadedVideoStringURL)
            dismiss(animated: true)
        }
    }
    
    private func showDownloadedImage(_ image: UIImage) {
        ImageProcessingManager.shared.processImage(image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                switch result {
                case .success(let compressedImage):
                    // Only show preview if image is within size limit
                    self.collectionView.isHidden = true
                    self.pageControl.isHidden = true
                    self.previewImageView.image = compressedImage
                    self.previewImageView.isHidden = false
                    self.doneButton.isHidden = false
                    
                case .failure(let error):
                    // Show error and reset UI
                    let snackbar = CustomSnackbar(message: error.message, backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                    
                    // Reset UI state
                    self.previewImageView.image = nil
                    self.previewImageView.isHidden = true
                    self.doneButton.isHidden = true
                    self.collectionView.isHidden = false
                    self.pageControl.isHidden = false
                }
                self.stopLoading()
            }
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
        startLoading()
        
        if !isConnectedToInternet() {
            stopLoading()
            showError("Please turn on internet connection!")
            return
        }
        
        let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
        let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .interstitial) == nil)
        
        if shouldOpenDirectly {
            downloadVideo()
        } else {
            interstitialAdUtility.showInterstitialAd()
            interstitialAdUtility.onInterstitialEarned = { [weak self] in
                self?.downloadVideo()
            }
        }
    }
    
    private func downloadVideo() {
        guard let urlToDownload = searchTextField.text, !urlToDownload.isEmpty else {
            stopLoading()
            showError("Please enter a valid URL")
            return
        }
        
        socialViewModule.fetchSocial(url: urlToDownload) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let socialResponse):
                    print("Social Download successfully: \(socialResponse.data)")
                    self?.downloadedVideoStringURL = socialResponse.data
                    self?.loadVideoFromURL(socialResponse.data)
                case .failure(let error):
                    print("Failed to Social Download: \(error.localizedDescription)")
                    self?.stopLoading()
                    self?.showError("Downloading Failed")
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
        // Show the cancel button if there is text
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

