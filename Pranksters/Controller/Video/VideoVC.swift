//
//  VideoVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 18/10/24.
//

import UIKit
import Alamofire
import SDWebImage
import Lottie
import AVFoundation
import MobileCoreServices
import Photos

class VideoVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var AudioShowView: UIView!
    @IBOutlet weak var oneTimeBlurView: UIView!
    @IBOutlet weak var floatingButton: UIButton!
    @IBOutlet var floatingCollectionButton: [UIButton]!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var pauseImageView: UIImageView!
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var videoCustomCollectionView: UICollectionView!
    @IBOutlet weak var videoCharacterCollectionView: UICollectionView!
    @IBOutlet weak var lottieLoader: LottieAnimationView!
    @IBOutlet weak var coverImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoCustomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoCharacterHeightConstraint: NSLayoutConstraint!
    
    private var currentAudioIsFavorite: Bool = false {
        didSet {
            updateFavoriteButton(isFavorite: currentAudioIsFavorite)
        }
    }
    var currentlySelectedCollectionView: UICollectionView?
    var currentlySelectedIndexPath: IndexPath?
    private let favoriteViewModel = FavoriteViewModel()
    private var selectedVideoData: CharacterAllData?
    private var selectedCustomVideoCell: IndexPath?
    var selectedCoverImageURL: String?
    var shouldAutoPlayVideo = false
    let plusImage = UIImage(named: "Plus")
    let cancelImage = UIImage(named: "Cancel")
    var customVideos: [URL] = []
    var selectedCustomVideoIndex: Int?
    var selectedCoverPage1Index: IndexPath?
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var isPlaying = false
    var audioSession: AVAudioSession?
    private var viewModel: CharacterViewModel!
    var isLoading = true
    private var noDataView: NoDataBottomBarView!
    private var noInternetView: NoInternetBottombarView!
    
    init(viewModel: CharacterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = CharacterViewModel(apiService: CharacterAPIService.shared)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.revealViewController()?.gestureEnabled = false
        
        // Restore the previous selection if it exists
        if let selectedIndex = selectedCustomVideoCell {
            videoCustomCollectionView.selectItem(at: selectedIndex, animated: false, scrollPosition: [])
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController()?.gestureEnabled = true
        stopVideo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopVideo()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
        loadSavedImages()
        setupNoDataView()
        setupLottieLoader()
        showSkeletonLoader()
        setupNoInternetView()
        setupFloatingButtons()
        checkInternetAndFetchData()
        addBottomShadow(to: navigationbarView)
        setupVideoImageView()
        setupAudioSession()
        
        if let imageURL = selectedCoverImageURL{
            print("=== Received Data in Cover Image ===")
            print("Image URL: \(imageURL)")
            print("=========================================")
        }
        
        self.pauseImageView.image = UIImage(named: "pause")
        self.pauseImageView.isHidden = true
        videoImageView.loadGif(name: "CoverGIF")
        self.favouriteButton.isHidden = true
    }
    
    private func stopVideo() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        isPlaying = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupVideoImageView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoImageViewTapped))
        videoImageView.addGestureRecognizer(tapGesture)
        videoImageView.isUserInteractionEnabled = true
    }
    
    @objc private func videoImageViewTapped() {
        if isPlaying {
            pauseVideo()
        } else {
            playVideo()
        }
    }
    
    private func playVideo() {
        player?.play()
        isPlaying = true
        pauseImageView.isHidden = true
    }
    
    private func pauseVideo() {
        player?.pause()
        isPlaying = false
        pauseImageView.isHidden = false
    }
    
    private func setupAudioSession() {
        do {
            audioSession = AVAudioSession.sharedInstance()
            try audioSession?.setCategory(.playback, mode: .moviePlayback)
            try audioSession?.setActive(true)
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            viewModel.fetchCharacters(categoryId: 2)
            self.noInternetView?.isHidden = true
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.3) {
            self.oneTimeBlurView.alpha = 0
        } completion: { _ in
            self.oneTimeBlurView.isHidden = true
        }
    }
    
    func isFirstLaunch() -> Bool {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "hasLaunchedVideo") {
            return false
        } else {
            defaults.set(true, forKey: "hasLaunchedVideo")
            return true
        }
    }
    
    func setupUI() {
        bottomView.layer.shadowColor = UIColor.black.cgColor
        bottomView.layer.shadowOpacity = 0.5
        bottomView.layer.shadowOffset = CGSize(width: 0, height: 5)
        bottomView.layer.shadowRadius = 12
        bottomView.layer.cornerRadius = 28
        bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        bottomScrollView.layer.cornerRadius = 28
        bottomScrollView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        floatingButton.setImage(plusImage, for: .normal)
        floatingButton.layer.cornerRadius = 19
        videoImageView.layer.cornerRadius = 8
        AudioShowView.layer.cornerRadius = 8
        self.videoCharacterCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        videoCustomCollectionView.delegate = self
        videoCustomCollectionView.dataSource = self
        videoCharacterCollectionView.delegate = self
        videoCharacterCollectionView.dataSource = self
        
        self.oneTimeBlurView.isHidden = true
        if isFirstLaunch() {
            self.oneTimeBlurView.isHidden = false
        } else {
            self.oneTimeBlurView.isHidden = true
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        oneTimeBlurView.addGestureRecognizer(tapGesture)
        oneTimeBlurView.isUserInteractionEnabled = true
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            coverImageViewHeightConstraint.constant = 280
            coverImageViewWidthConstraint.constant = 245
            scrollViewHeightConstraint.constant = 680
            videoCustomHeightConstraint.constant = 180
            videoCharacterHeightConstraint.constant = 360
        } else {
            coverImageViewHeightConstraint.constant = 240
            coverImageViewWidthConstraint.constant = 205
            scrollViewHeightConstraint.constant = 530
            videoCustomHeightConstraint.constant = 140
            videoCharacterHeightConstraint.constant = 280
        }
        self.view.layoutIfNeeded()
    }
    
    func setupViewModel() {
        viewModel.reloadData = { [weak self] in
            DispatchQueue.main.async {
                if self?.viewModel.characters.isEmpty ?? true {
                    self?.noDataView.isHidden = false
                } else {
                    self?.hideSkeletonLoader()
                    self?.noDataView.isHidden = true
                    self?.videoCharacterCollectionView.reloadData()
                }
            }
        }
        
        viewModel.onError = { error in
            self.hideSkeletonLoader()
            self.noDataView.isHidden = false
            print("Error fetching cover pages: \(error)")
        }
    }
    
    private func setupNoDataView() {
        noDataView = NoDataBottomBarView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        noDataView.isHidden = true
        self.view.addSubview(noDataView)
        
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: videoImageView.bottomAnchor, constant: 16),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        noDataView.layer.cornerRadius = 28
        noDataView.layer.masksToBounds = true
        
        noDataView.layoutIfNeeded()
    }
    
    func setupNoInternetView() {
        noInternetView = NoInternetBottombarView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        
        noInternetView.isHidden = true
        self.view.addSubview(noInternetView)
        
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: videoImageView.bottomAnchor, constant: 16),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        noInternetView.layer.cornerRadius = 28
        noInternetView.layer.masksToBounds = true
        
        noInternetView.layoutIfNeeded()
    }
    
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            noDataView.isHidden = true
            checkInternetAndFetchData()
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showSkeletonLoader() {
        isLoading = true
        videoCharacterCollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        videoCharacterCollectionView.reloadData()
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    func showLottieLoader() {
        lottieLoader.isHidden = false
        videoImageView.isHidden = true
        favouriteButton.isHidden = true
        lottieLoader.play()
    }
    
    func hideLottieLoader() {
        lottieLoader.stop()
        lottieLoader.isHidden = true
        videoImageView.isHidden = false
        favouriteButton.isHidden = false
    }
    
    private func setupLottieLoader() {
        lottieLoader.isHidden = true
        lottieLoader.loopMode = .loop
        lottieLoader.contentMode = .scaleAspectFill
        lottieLoader.animation = LottieAnimation.named("Loader")
    }
    
    private func setupFloatingButtons() {
        for button in floatingCollectionButton {
            button.layer.cornerRadius = 19
            button.clipsToBounds = true
            button.layer.shadowColor = UIColor.black.cgColor
            button.layer.shadowOpacity = 0.25
            button.layer.shadowOffset = CGSize(width: 0, height: 2)
            button.layer.shadowRadius = 4
            button.layer.masksToBounds = false
            button.isHidden = true
            button.alpha = 0
        }
    }
    
    func addBottomShadow(to view: UIView) {
        view.layer.masksToBounds = false
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 7)
        view.layer.shadowRadius = 12
        view.layer.shadowPath = UIBezierPath(rect: CGRect(x: 0, y: view.bounds.maxY - 4, width: view.bounds.width, height: 4)).cgPath
    }
    
    @IBAction func btnFloatingTapped(_ sender: UIButton) {
        floatingCollectionButton.forEach { btn in
            UIView.animate(withDuration: 0.5) {
                btn.isHidden = !btn.isHidden
                btn.alpha = btn.alpha == 0 ? 1 : 0
            }
        }
        if floatingButton.currentImage == plusImage {
            floatingButton.setImage(cancelImage, for: .normal)
        } else {
            floatingButton.setImage(plusImage, for: .normal)
        }
    }
    
    @IBAction func btnMoreAppTapped(_ sender: UIButton) {
        animate(toggel: false)
        floatingButton.setImage(plusImage, for: .normal)
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MoreAppVC") as! MoreAppVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnFavouriteTapped(_ sender: UIButton) {
        animate(toggel: false)
        floatingButton.setImage(plusImage, for: .normal)
    }
    
    @IBAction func btnPremiumTapped(_ sender: UIButton) {
        animate(toggel: false)
        floatingButton.setImage(plusImage, for: .normal)
    }
    
    func animate(toggel: Bool) {
        if toggel {
            floatingCollectionButton.forEach { btn in
                UIView.animate(withDuration: 0.5) {
                    btn.isHidden = false
                    btn.alpha = btn.alpha == 0 ? 1 : 0
                }
            }
        } else {
            floatingCollectionButton.forEach { btn in
                UIView.animate(withDuration: 0.5) {
                    btn.isHidden = true
                    btn.alpha = btn.alpha == 0 ? 1 : 0
                }
            }
        }
    }
    
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        var videoURLToPass: String?
        var videoNameToPass: String?
        
        if let selectedIndex = selectedCustomVideoIndex {
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "\(UUID().uuidString).mp4"
            let destinationURL = documentsDirectory.appendingPathComponent(fileName)
            
            videoURLToPass = destinationURL.absoluteString
            videoNameToPass = "Custom Video \(selectedIndex + 1)"
        }
        else if let selectedData = selectedVideoData {
            videoURLToPass = selectedData.file
            videoNameToPass = selectedData.name
        }
        if let imageURL = videoURLToPass {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "PremiumVC") as? PremiumVC {
                nextVC.selectedURL = imageURL
                nextVC.selectedName = videoNameToPass
                nextVC.selectedCoverURL = selectedCoverImageURL
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        } else {
            let alert = UIAlertController(title: "No Image Selected",
                                          message: "Please select an image before proceeding.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnFavouriteSetTapped(_ sender: UIButton) {
        if let selectedData = selectedVideoData {
            let newFavoriteStatus = !selectedData.isFavorite
            
            favoriteViewModel.setFavorite(
                itemId: selectedData.itemID,
                isFavorite: newFavoriteStatus,
                categoryId: 2
            ) { [weak self] success, message in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.selectedVideoData?.isFavorite = newFavoriteStatus
                        self.currentAudioIsFavorite = newFavoriteStatus
                        self.updateFavoriteButton(isFavorite: newFavoriteStatus)
                        
                        print("=== Favorite Status Updated ===")
                        print("Item ID: \(selectedData.itemID)")
                        print("New Favorite Status: \(newFavoriteStatus)")
                        print("\(message ?? "Success")")
                        print("==============================")
                        
                    } else {
                        print("Failed to update favorite status: \(message ?? "Unknown error")")
                        self.updateFavoriteButton(isFavorite: selectedData.isFavorite)
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension VideoVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == videoCustomCollectionView {
            return customVideos.count + 1
        } else if collectionView == videoCharacterCollectionView {
            return isLoading ? 6 : viewModel.characters.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddVideoCollectionViewCell", for: indexPath) as! AddVideoCollectionViewCell
                cell.imageView.image = UIImage(named: "AddVideo")
                cell.addAudioLabel.text = "Add Video"
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCustomCollectionViewCell", for: indexPath) as! VideoCustomCollectionViewCell
                let videoURL = customVideos[indexPath.item - 1]
                cell.setThumbnail(for: videoURL)
                return cell
            }
        } else if collectionView == videoCharacterCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCharacterCollectionViewCell", for: indexPath) as! VideoCharacterCollectionViewCell
                let character = viewModel.characters[indexPath.item]
                if let url = URL(string: character.characterImage) {
                    cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder"))
                }
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let previousCollectionView = currentlySelectedCollectionView,
           let previousIndexPath = currentlySelectedIndexPath,
           previousCollectionView != collectionView {
            previousCollectionView.deselectItem(at: previousIndexPath, animated: true)
        }
        
        currentlySelectedCollectionView = collectionView
        currentlySelectedIndexPath = indexPath
        
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                // For the "Add Video" cell
                collectionView.deselectItem(at: indexPath, animated: true)
                showVideoOptionsActionSheet(sourceView: collectionView.cellForItem(at: indexPath)!)
            } else {
                // For video cells
                if let previousSelection = selectedCustomVideoCell, previousSelection != indexPath {
                    collectionView.deselectItem(at: previousSelection, animated: true)
                }
                selectedCustomVideoCell = indexPath
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                
                showLottieLoader()
                let videoURL = customVideos[indexPath.item - 1]
                playCustomVideo(url: videoURL, autoPlay: true)
                selectedCustomVideoIndex = indexPath.item - 1
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "\(UUID().uuidString).mp4"
                let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                
                print("=== Selected Custom Video ===")
                print("=====================================")
                print("Video URL: \(destinationURL.absoluteString)")
                print("=====================================")
                
                hideLottieLoader()
                self.favouriteButton.isHidden = true
            }
        } else if collectionView == videoCharacterCollectionView {
            let character = viewModel.characters[indexPath.item]
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "VideoCharacterAllVC") as! VideoCharacterAllVC
            vc.characterId = character.characterID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldDeselectItemAt indexPath: IndexPath) -> Bool {
        if collectionView == videoCustomCollectionView && indexPath.item != 0 {
            return false // Prevent deselection for video cells
        }
        return true // Allow deselection for other cells
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 155 : 115
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 165 : 125
        
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                return CGSize(width: width, height: height)
            }
            return CGSize(width: width, height: height)
        } else if collectionView == videoCharacterCollectionView {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
}

extension VideoVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func showVideoOptionsActionSheet(sourceView: UIView) {
        let titleString = NSAttributedString(string: "Select Video", attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
        ])
        
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(titleString, forKey: "attributedTitle")
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.openVideoCamera()
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.openVideoGallery()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(cameraAction)
        alertController.addAction(galleryAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func openVideoCamera() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.showVideoPicker(for: .camera)
                    } else {
                        self?.showPermissionSnackbar(for: "camera")
                    }
                }
            }
        case .authorized:
            showVideoPicker(for: .camera)
        case .denied, .restricted:
            showPermissionSnackbar(for: "camera")
        @unknown default:
            break
        }
    }
    
    private func openVideoGallery() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.showVideoPicker(for: .photoLibrary)
                    } else {
                        self?.showPermissionSnackbar(for: "photo library")
                    }
                }
            }
        case .authorized, .limited:
            showVideoPicker(for: .photoLibrary)
        case .denied, .restricted:
            showPermissionSnackbar(for: "photo library")
        @unknown default:
            break
        }
    }
    
    private func showVideoPicker(for sourceType: UIImagePickerController.SourceType) {
        guard UIImagePickerController.isSourceTypeAvailable(sourceType) else {
            print("Source type \(sourceType) is not available")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.videoQuality = .typeHigh
        picker.allowsEditing = true
        
        present(picker, animated: true)
    }
    
    private func showPermissionSnackbar(for feature: String) {
        let messageKey: String
        
        switch feature {
        case "camera":
            messageKey = "We need access to your camera to record a video."
        case "photo library":
            messageKey = "We need access to your photo library to select a video."
        default:
            messageKey = "SnackbarDefaultPermissionAccess"
        }
        
        let localizedMessage = NSLocalizedString(messageKey, comment: "")
        let settingsText = NSLocalizedString("Settings", comment: "")
        
        let snackbar = Snackbar(message: localizedMessage, backgroundColor: .snackbar)
        snackbar.setAction(title: settingsText) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        
        snackbar.show(in: self.view, duration: 5.0)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        showLottieLoader()
        picker.dismiss(animated: true)
        
        guard let videoURL = info[.mediaURL] as? URL else { return }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).mp4"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        
        print("📱 New Custom Video Added:")
        print("=====================================")
        print("Source: \(picker.sourceType == .camera ? "Camera" : "Gallery")")
        print("Video URL: \(destinationURL.absoluteString)")
        print("=====================================")
        
        do {
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            customVideos.append(destinationURL)
            videoCustomCollectionView.reloadData()
            saveImages()
            let indexPath = IndexPath(item: 1, section: 0)
            videoCustomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            self.selectedCoverPage1Index = indexPath
            self.videoCustomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            selectedCustomVideoIndex = customVideos.count - 1
            playCustomVideo(url: destinationURL, autoPlay: true)
            self.hideLottieLoader()
            self.favouriteButton.isHidden = true
        } catch {
            print("Error copying video: \(error)")
        }
    }
    
    func playCustomVideo(url: URL, autoPlay: Bool = false) {
        showLottieLoader()
        playerLayer?.removeFromSuperlayer()
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoImageView.bounds
        playerLayer?.videoGravity = .resizeAspectFill
        
        if let playerLayer = playerLayer {
            videoImageView.layer.addSublayer(playerLayer)
        }
        
        player?.volume = 1.0
        
        self.videoImageView.isHidden = false
        self.favouriteButton.isHidden = false
        
        hideLottieLoader()
        
        if autoPlay {
            playVideo()
        } else {
            pauseVideo()
            pauseImageView.isHidden = true
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        if let index = selectedCustomVideoIndex {
            let indexPath = IndexPath(item: index + 1, section: 0)
            videoCustomCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    func loadSavedImages() {
        showLottieLoader()
        if let savedImagesData = UserDefaults.standard.object(forKey: "is_UserSelectedVideo") as? Data {
            do {
                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [URL] {
                    customVideos = decodedImages
                    videoCustomCollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved images: \(error)")
            }
        }
        selectedCoverPage1Index = nil
        hideLottieLoader()
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customVideos, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: "is_UserSelectedVideo")
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        player?.seek(to: CMTime.zero)
        playVideo()
    }
    
    func updateSelectedVideo(with coverData: CharacterAllData) {
        showLottieLoader()
        self.selectedVideoData = coverData
        self.currentAudioIsFavorite = coverData.isFavorite
        print("=== Selected Video from Preview ===")
        print("Name: \(coverData.name)")
        print("File URL: \(coverData.file ?? "No URL")")
        print("Is Favorite: \(coverData.isFavorite)")
        print("Item ID: \(coverData.itemID)")
        print("Premium: \(coverData.premium)")
        print("=====================================")
        
        updateFavoriteButton(isFavorite: coverData.isFavorite)
        
        if let videoURLString = coverData.file,
           let videoURL = URL(string: videoURLString) {
            stopVideo()
            
            self.videoImageView.isHidden = false
            self.favouriteButton.isHidden = false
            
            let playerItem = AVPlayerItem(url: videoURL)
            player = AVPlayer(playerItem: playerItem)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = videoImageView.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            
            if let playerLayer = playerLayer {
                videoImageView.layer.addSublayer(playerLayer)
            }
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: playerItem
            )
            
            player?.volume = 1.0
            playVideo()
            
            pauseImageView.isHidden = true
            isPlaying = true
        }
        hideLottieLoader()
    }
    
    private func updateFavoriteButton(isFavorite: Bool) {
        favouriteButton.setImage(UIImage(named: isFavorite ? "Heart_Fill" : "Heart"), for: .normal)
    }
}
