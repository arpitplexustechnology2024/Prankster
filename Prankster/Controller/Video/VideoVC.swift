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
    
    // MARK: - IBOutlet
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var videoShowView: UIView!
    @IBOutlet weak var videoImageView: UIImageView!
    @IBOutlet weak var pauseImageView: UIImageView!
    @IBOutlet weak var videoCustomCollectionView: UICollectionView!
    @IBOutlet weak var videoCharacterCollectionView: UICollectionView!
    @IBOutlet weak var lottieLoader: LottieAnimationView!
    @IBOutlet weak var coverImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoCustomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoCharacterHeightConstraint: NSLayoutConstraint!
    
    // MARK: - Properties
    private var isLoading = true
    private var isPlaying = false
    private var player: AVPlayer?
    var selectedCoverImageURL: String?
    var selectedCoverImageFile: Data?
    var selectedCoverImageName: String?
    private var selectedVideoIndex: Int?
    private var customVideos: [URL] = []
    private var shouldAutoPlayVideo = false
    private var playerLayer: AVPlayerLayer?
    private var audioSession: AVAudioSession?
    private var viewModel: CategoryViewModel!
    private var noDataView: NoDataBottomBarView!
    private var selectedVideoData: CategoryAllData?
    private var selectedVideoCustomCell: IndexPath?
    private var selectedVideoCategoryCell: IndexPath?
    private var noInternetView: NoInternetBottombarView!
    
    init(viewModel: CategoryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = CategoryViewModel(apiService: CategoryAPIService.shared)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseVideo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseVideo()
    }
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupViewModel()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.setupAudioSession()
        self.setupLottieLoader()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupVideoImageView()
        self.loadCustomVideoURLs()
        self.checkInternetAndFetchData()
        self.navigationbarView.addBottomShadow()
        self.videoCustomCollectionView.reloadData()
        self.pauseImageView.isHidden = true
        self.pauseImageView.image = UIImage(named: "PlayButton")
    }
    
    // MARK: - checkInternetAndFetchData
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            viewModel.fetchCategorys(typeId: 2)
            self.noInternetView?.isHidden = true
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    // MARK: - setupUI
    func setupUI() {
        self.bottomView.layer.shadowColor = UIColor.black.cgColor
        self.bottomView.layer.shadowOpacity = 0.5
        self.bottomView.layer.shadowOffset = CGSize(width: 0, height: 5)
        self.bottomView.layer.shadowRadius = 12
        self.bottomView.layer.cornerRadius = 20
        self.bottomView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        self.bottomScrollView.layer.cornerRadius = 20
        self.bottomScrollView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        self.videoImageView.loadGif(name: "VideoGIF")
        self.videoImageView.layer.cornerRadius = 8
        self.videoShowView.layer.cornerRadius = 8
        self.videoShowView.layer.shadowColor = UIColor.black.cgColor
        self.videoShowView.layer.shadowOpacity = 0.1
        self.videoShowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        self.videoShowView.layer.shadowRadius = 12
        
        self.videoCustomCollectionView.delegate = self
        self.videoCustomCollectionView.dataSource = self
        self.videoCharacterCollectionView.delegate = self
        self.videoCharacterCollectionView.dataSource = self
        
        self.videoCharacterCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.coverImageViewHeightConstraint.constant = 280
            self.coverImageViewWidthConstraint.constant = 230
            self.scrollViewHeightConstraint.constant = 830
            self.videoCustomHeightConstraint.constant = 180
            self.videoCharacterHeightConstraint.constant = 575
        } else {
            self.coverImageViewHeightConstraint.constant = 240
            self.coverImageViewWidthConstraint.constant = 190
            self.scrollViewHeightConstraint.constant = 530
            self.videoCustomHeightConstraint.constant = 140
            self.videoCharacterHeightConstraint.constant = 280
        }
        self.view.layoutIfNeeded()
    }
    
    // MARK: - setupViewModel
    func setupViewModel() {
        viewModel.reloadData = { [weak self] in
            DispatchQueue.main.async {
                if self?.viewModel.categorys.isEmpty ?? true {
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
    
    // MARK: - setupNoDataView
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
    
    // MARK: - setupNoInternetView
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
    
    // MARK: - retryButtonTapped
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
    
    private func showSkeletonLoader() {
        isLoading = true
        videoCharacterCollectionView.reloadData()
    }
    
    private func hideSkeletonLoader() {
        isLoading = false
        videoCharacterCollectionView.reloadData()
    }
    
    private func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - showLottieLoader
    private func showLottieLoader() {
        lottieLoader.isHidden = false
        lottieLoader.play()
    }
    
    // MARK: - hideLottieLoader
    private func hideLottieLoader() {
        lottieLoader.stop()
        lottieLoader.isHidden = true
    }
    
    // MARK: - setupLottieLoader
    private func setupLottieLoader() {
        lottieLoader.isHidden = true
        lottieLoader.loopMode = .loop
        lottieLoader.contentMode = .scaleAspectFill
        lottieLoader.animation = LottieAnimation.named("Loader")
    }
    
    // MARK: - btnDoneTapped
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        if isConnectedToInternet() {
            var videoURLToPass: String?
            var videoFileToPass: Data?
            
            if let selectedIndex = selectedVideoIndex {
                
                let videoData = customVideos[selectedIndex]
                print(videoData)
                if let fileData = try? Data(contentsOf: videoData) {
                    videoFileToPass = fileData
                    videoURLToPass = nil
                }
            }
            else if let selectedData = selectedVideoData {
                videoURLToPass = selectedData.file
                videoFileToPass = nil
            }
            if videoURLToPass != nil || videoFileToPass != nil {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let nextVC = storyboard.instantiateViewController(withIdentifier: "ShareLinkVC") as? ShareLinkVC {
                    nextVC.selectedURL = videoURLToPass
                    nextVC.selectedFile = videoFileToPass
                    nextVC.selectedName = selectedCoverImageName
                    nextVC.selectedCoverURL = selectedCoverImageURL
                    nextVC.selectedCoverFile = selectedCoverImageFile
                    nextVC.selectedPranktype = "video"
                    nextVC.selectedFileType = "mp4"
                    nextVC.sharePrank = true
                    self.navigationController?.pushViewController(nextVC, animated: true)
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please select a video.", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    // MARK: - btnBackTapped
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupVideoImageView() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(videoImageViewTapped))
        videoShowView.addGestureRecognizer(tapGesture)
        videoShowView.isUserInteractionEnabled = true
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
    
    // MARK: - updateSelectedVideo
    func updateSelectedVideo(with coverData: CategoryAllData) {
        selectedVideoIndex = nil
        if let previousCustomCell = selectedVideoCustomCell {
            videoCustomCollectionView.deselectItem(at: previousCustomCell, animated: false)
            selectedVideoCustomCell = nil
        }
        videoImageView.isHidden = true
        showLottieLoader()
        self.selectedVideoData = coverData
        print("Name: \(coverData.name)")
        print("File URL: \(coverData.file ?? "No URL")")
        
        if let videoURLString = coverData.file,
           let videoURL = URL(string: videoURLString) {
            pauseVideo()
            
            let playerItem = AVPlayerItem(url: videoURL)
            player = AVPlayer(playerItem: playerItem)
            
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = videoShowView.bounds
            playerLayer?.videoGravity = .resizeAspectFill
            
            if let playerLayer = playerLayer {
                videoShowView.layer.addSublayer(playerLayer)
                playerLayer.cornerRadius = 8
                playerLayer.masksToBounds = true
                videoShowView.bringSubviewToFront(pauseImageView)
            }
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidStartPlaying), name: .AVPlayerItemNewAccessLogEntry, object: playerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
            player?.volume = 1.0
            pauseVideo()
            pauseImageView.isHidden = false
            videoShowView.layer.backgroundColor = UIColor.icon.cgColor
            isPlaying = false
        }
        self.hideLottieLoader()
    }
    
    @objc private func playerDidStartPlaying() {
        playerLayer?.videoGravity = .resizeAspect
    }
    
    // MARK: - setupbackSwipeGesture
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
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension VideoVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == videoCustomCollectionView {
            return customVideos.count + 1
        } else if collectionView == videoCharacterCollectionView {
            return isLoading ? 6 : viewModel.categorys.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddVideoCollectionViewCell", for: indexPath) as! AddVideoCollectionViewCell
                cell.imageView.image = UIImage(named: "AddVideo")
                cell.addAudioLabel.text = "Add video"
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCustomCollectionViewCell", for: indexPath) as! VideoCustomCollectionViewCell
                let videoURL = customVideos[indexPath.item - 1]
                cell.setThumbnail(for: videoURL)
                
                if let selectedCell = selectedVideoCustomCell {
                    cell.isSelected = selectedCell == indexPath
                }
                
                return cell
            }
        } else if collectionView == videoCharacterCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCharacterCollectionViewCell", for: indexPath) as! VideoCharacterCollectionViewCell
                let category = viewModel.categorys[indexPath.item]
                if let url = URL(string: category.categoryImage) {
                    cell.imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "PlaceholderVideo")) { image, error, cacheType, imageURL in
                        if image != nil {
                            cell.categoryName.text = "\(category.categoryName) \n Video"
                            cell.categoryName.isHidden = false
                        } else {
                            cell.categoryName.isHidden = true
                        }
                    }
                }
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                showVideoOptionsActionSheet(sourceView: collectionView.cellForItem(at: indexPath)!)
            } else {
                
                if indexPath == selectedVideoCustomCell {
                    return
                }
                
                if let previousCharacterCell = selectedVideoCategoryCell {
                    videoCharacterCollectionView.deselectItem(at: previousCharacterCell, animated: true)
                    selectedVideoCategoryCell = nil
                }
                
                if let previousCell = selectedVideoCustomCell {
                    collectionView.deselectItem(at: previousCell, animated: true)
                }
                
                selectedVideoCustomCell = indexPath
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                videoImageView.isHidden = true
                showLottieLoader()
                let videoURL = customVideos[indexPath.item - 1]
                playCustomVideo(url: videoURL, autoPlay: false)
                selectedVideoIndex = indexPath.item - 1
                
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = "\(UUID().uuidString).mp4"
                let destinationURL = documentsDirectory.appendingPathComponent(fileName)
                print("Custom Video URL: \(destinationURL.absoluteString)")
                hideLottieLoader()
            }
        } else if collectionView == videoCharacterCollectionView {
            selectedVideoCategoryCell = indexPath
            let character = viewModel.categorys[indexPath.item]
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "VideoCategoryAllVC") as! VideoCategoryAllVC
            vc.categoryId = character.categoryID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
            if collectionView == videoCustomCollectionView {
                return indexPath.item == 0 || indexPath != selectedVideoCustomCell
            }
            return true
        }
    
    func deselectCharacterCell() {
        if let selectedCell = selectedVideoCategoryCell {
            videoCharacterCollectionView.deselectItem(at: selectedCell, animated: false)
            selectedVideoCategoryCell = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        deselectCharacterCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 155 : 115
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 165 : 125
        let width1: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 260 : 115
        let height1: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 270 : 125
        
        if collectionView == videoCustomCollectionView {
            if indexPath.item == 0 {
                return CGSize(width: width, height: height)
            }
            return CGSize(width: width, height: height)
        } else if collectionView == videoCharacterCollectionView {
            return CGSize(width: width1, height: height1)
        }
        return CGSize(width: width, height: height)
    }
}

extension VideoVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func showVideoOptionsActionSheet(sourceView: UIView) {
        let titleString = NSAttributedString(string: "Select video prank", attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
        ])
        
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(titleString, forKey: "attributedTitle")
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.openVideoCamera()
            self?.pauseVideo()
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.openVideoGallery()
            self?.pauseVideo()
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
            messageKey = "We need access to your camera to record a video."
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
        videoImageView.isHidden = true
        showLottieLoader()
        
        guard let videoURL = info[.mediaURL] as? URL else {
            picker.dismiss(animated: true)
            return
        }
        
        let asset = AVAsset(url: videoURL)
        let duration = CMTimeGetSeconds(asset.duration)
        
        if duration > 16.0 {
            picker.dismiss(animated: true) {
                let snackbar = CustomSnackbar(message: "Please select a max 15 seconds video file.", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
                self.hideLottieLoader()
            }
            return
        }
        
        picker.dismiss(animated: true)
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileName = "\(UUID().uuidString).mp4"
        let destinationURL = documentsDirectory.appendingPathComponent(fileName)
        print("Video URL: \(destinationURL.absoluteString)")
        
        do {
            try FileManager.default.copyItem(at: videoURL, to: destinationURL)
            customVideos.insert(destinationURL, at: 0)
            selectedVideoIndex = 0
            saveCustomVideoURLs()
            
            DispatchQueue.main.async {
                self.videoCustomCollectionView.reloadData()
                let indexPath = IndexPath(item: 1, section: 0)
                self.videoCustomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.selectedVideoCustomCell = indexPath
                self.videoCustomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.playCustomVideo(url: destinationURL, autoPlay: false)
                self.hideLottieLoader()
            }
        } catch {
            print("Error copying video: \(error)")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func playCustomVideo(url: URL, autoPlay: Bool = false) {
        videoImageView.isHidden = true
        showLottieLoader()
        playerLayer?.removeFromSuperlayer()
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoShowView.bounds
        playerLayer?.videoGravity = .resizeAspect
        
        playerLayer?.cornerRadius = 8
        playerLayer?.masksToBounds = true
        
        if let playerLayer = playerLayer {
            videoShowView.layer.addSublayer(playerLayer)
            videoShowView.bringSubviewToFront(pauseImageView)
        }
        player?.volume = 1.0
        videoShowView.layer.backgroundColor = UIColor.icon.cgColor
        hideLottieLoader()
        if autoPlay {
            playVideo()
        } else {
            pauseVideo()
        }
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        if let index = selectedVideoIndex {
            let indexPath = IndexPath(item: index + 1, section: 0)
            videoCustomCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    @objc func playerDidFinishPlaying(note: NSNotification) {
        player?.seek(to: CMTime.zero)
        playVideo()
    }
    
    private func saveCustomVideoURLs() {
        let videoURLStrings = customVideos.map { $0.absoluteString }
        UserDefaults.standard.set(videoURLStrings, forKey: ConstantValue.is_UserVideos)
    }
    
    private func loadCustomVideoURLs() {
        guard let savedVideoURLStrings = UserDefaults.standard.stringArray(forKey: ConstantValue.is_UserVideos) else {
            return
        }
        
        customVideos = savedVideoURLStrings.compactMap { urlString in
            guard let url = URL(string: urlString),
                  FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return url
        }
    }
}
