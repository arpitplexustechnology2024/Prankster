//
//  ImageVC.swift
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

class ImageVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var oneTimeBlurView: UIView!
    @IBOutlet weak var AudioShowView: UIView!
    @IBOutlet weak var floatingButton: UIButton!
    @IBOutlet var floatingCollectionButton: [UIButton]!
    @IBOutlet weak var ImageImageView: UIImageView!
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var imageCustomCollectionView: UICollectionView!
    @IBOutlet weak var imageCharacterCollectionView: UICollectionView!
    @IBOutlet weak var lottieLoader: LottieAnimationView!
    @IBOutlet weak var coverImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageCustomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageCharacterHeightConstraint: NSLayoutConstraint!
    
    private let favoriteViewModel = FavoriteViewModel()
    private var selectedImageData: CharacterAllData?
    
    var selectedCoverImageURL: String?
    
    var selectedImageURL: String?
    var selectedImageName: String?
    
    let plusImage = UIImage(named: "Plus")
    let cancelImage = UIImage(named: "Cancel")
    
    private var selectedAudioIndex: Int?
    var selectedCoverPage1Index: IndexPath?
    
    var currentlySelectedCollectionView: UICollectionView?
    var currentlySelectedIndexPath: IndexPath?
    
    var customImages: [UIImage] = []
    
    private var currentAudioIsFavorite: Bool = false {
        didSet {
            updateFavoriteButton(isFavorite: currentAudioIsFavorite)
        }
    }
    
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
        
        if let selectedIndexPath = imageCustomCollectionView.indexPathsForSelectedItems?.first {
            imageCustomCollectionView.deselectItem(at: selectedIndexPath, animated: false)
        }
        selectedCoverPage1Index = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController()?.gestureEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupViewModel()
        setupNoDataView()
        loadSavedImages()
        setupLottieLoader()
        showSkeletonLoader()
        setupNoInternetView()
        setupFloatingButtons()
        checkInternetAndFetchData()
        addBottomShadow(to: navigationbarView)
        
        if let imageURL = selectedCoverImageURL{
            print("=== Received Data in Cover Image ===")
            print("Image URL: \(imageURL)")
            print("=========================================")
        }
        
        ImageImageView.loadGif(name: "CoverGIF")
        self.favouriteButton.isHidden = true
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            viewModel.fetchCharacters(categoryId: 3)
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
        if defaults.bool(forKey: "hasLaunchedImage") {
            return false
        } else {
            defaults.set(true, forKey: "hasLaunchedImage")
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
        ImageImageView.layer.cornerRadius = 8
        AudioShowView.layer.cornerRadius = 8
        updateFavoriteButton(isFavorite: false)
        self.imageCharacterCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        imageCustomCollectionView.delegate = self
        imageCustomCollectionView.dataSource = self
        imageCharacterCollectionView.delegate = self
        imageCharacterCollectionView.dataSource = self
        
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
            imageCustomHeightConstraint.constant = 180
            imageCharacterHeightConstraint.constant = 360
        } else {
            coverImageViewHeightConstraint.constant = 240
            coverImageViewWidthConstraint.constant = 205
            scrollViewHeightConstraint.constant = 530
            imageCustomHeightConstraint.constant = 140
            imageCharacterHeightConstraint.constant = 280
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
                    self?.imageCharacterCollectionView.reloadData()
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
            noDataView.topAnchor.constraint(equalTo: ImageImageView.bottomAnchor, constant: 16),
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
            noInternetView.topAnchor.constraint(equalTo: ImageImageView.bottomAnchor, constant: 16),
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
        imageCharacterCollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        imageCharacterCollectionView.reloadData()
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
        ImageImageView.isHidden = true
        favouriteButton.isHidden = true
        lottieLoader.play()
    }
    
    func hideLottieLoader() {
        lottieLoader.stop()
        lottieLoader.isHidden = true
        ImageImageView.isHidden = false
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
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "FavouriteVC") as! FavouriteVC
        self.navigationController?.pushViewController(vc, animated: true)
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
        var imageURLToPass: String?
        var imageNameToPass: String?
        
        if let selectedIndex = selectedAudioIndex {
            
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "CustomImage_\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            
            if let imageData = customImages[selectedIndex].jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                imageURLToPass = fileURL.absoluteString
                imageNameToPass = "Custom Image \(selectedIndex + 1)"
            }
        }
        else if let selectedData = selectedImageData {
            imageURLToPass = selectedData.image
            imageNameToPass = selectedData.name
        }
        if let imageURL = imageURLToPass {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "PremiumVC") as? PremiumVC {
                nextVC.selectedURL = imageURL
                nextVC.selectedName = imageNameToPass
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
        if let selectedData = selectedImageData {
            let newFavoriteStatus = !currentAudioIsFavorite
            
            favoriteViewModel.setFavorite(itemId: selectedData.itemID,
                                          isFavorite: newFavoriteStatus,
                                          categoryId: 3) { [weak self] success, message in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.currentAudioIsFavorite = newFavoriteStatus
                        self.updateFavoriteButton(isFavorite: newFavoriteStatus)
                        self.selectedImageData?.isFavorite = newFavoriteStatus
                        
                        print("=== Favorite Status Updated ===")
                        print("Item ID: \(selectedData.itemID)")
                        print("New Favorite Status: \(newFavoriteStatus)")
                        print("\(message ?? "Success")")
                        print("==============================")
                    } else {
                        print("Failed to update favorite status: \(message ?? "Unknown error")")
                        self.updateFavoriteButton(isFavorite: self.currentAudioIsFavorite)
                    }
                }
            }
        }
    }
    
    func updateSelectedImage(with coverData: CharacterAllData) {
        showLottieLoader()
        selectedImageData = coverData
        selectedImageURL = coverData.image
        selectedImageName = coverData.name
        
        if let url = URL(string: coverData.image) {
            ImageImageView.sd_setImage(with: url, completed: { [weak self] (image, error, cacheType, imageURL) in
                self?.hideLottieLoader()
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                } else {
                    print("=== Selected Image from Preview ===")
                    print("Name: \(coverData.name)")
                    print("Image URL: \(coverData.image)")
                    print("Is Favorite: \(coverData.isFavorite)")
                    print("Item ID: \(coverData.itemID)")
                    print("Premium: \(coverData.premium)")
                    print("=====================================")
                    self?.favouriteButton.isHidden = false
                    self?.currentAudioIsFavorite = coverData.isFavorite
                    self?.updateFavoriteButton(isFavorite: coverData.isFavorite)
                }
            })
        }
    }
}

extension ImageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == imageCustomCollectionView {
            return 1 + customImages.count
        } else if collectionView == imageCharacterCollectionView {
            return isLoading ? 6 : viewModel.characters.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == imageCustomCollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddImageCollectionViewCell", for: indexPath) as! AddImageCollectionViewCell
                cell.imageView.image = UIImage(named: "AddImage")
                cell.addAudioLabel.text = "Add Image"
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCustomCollectionViewCell", for: indexPath) as! ImageCustomCollectionViewCell
                let customImage = customImages[indexPath.item - 1]
                cell.imageView.image = customImage
                return cell
            }
        } else if collectionView == imageCharacterCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterCollectionViewCell", for: indexPath) as! ImageCharacterCollectionViewCell
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
        
        if collectionView == imageCustomCollectionView {
            if indexPath.item == 0 {
                showImageOptionsActionSheet(sourceView: collectionView.cellForItem(at: indexPath)!)
            } else {
                showLottieLoader()
                let customImage = customImages[indexPath.item - 1]
                selectedAudioIndex = indexPath.item - 1
                ImageImageView.image = customImage
                
                let temporaryDirectory = NSTemporaryDirectory()
                let fileName = "\(UUID().uuidString).jpg"
                let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
                
                print("=== Selected Custom Image ===")
                print("Image URL: \(fileURL.absoluteString)")
                print("==============================")
                
                hideLottieLoader()
                self.favouriteButton.isHidden = true
            }
        } else if collectionView == imageCharacterCollectionView {
            let character = viewModel.characters[indexPath.item]
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ImageCharacterAllVC") as! ImageCharacterAllVC
            vc.characterId = character.characterID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 155 : 115
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 165 : 125
        
        if collectionView == imageCustomCollectionView {
            if indexPath.item == 0 {
                return CGSize(width: width, height: height)
            }
            return CGSize(width: width, height: height)
        } else if collectionView == imageCharacterCollectionView {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
}

extension ImageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private func showImageOptionsActionSheet(sourceView: UIView) {
        let titleString = NSAttributedString(string: "Select Image", attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
        ])
        
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(titleString, forKey: "attributedTitle")
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
            self?.btnCameraTapped()
        }
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.btnGalleryTapped()
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
    
    // MARK: - Camera Button
    func btnCameraTapped() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.showImagePicker(for: .camera)
                    } else {
                        self.showPermissionSnackbar(for: "camera")
                    }
                }
            }
        case .authorized:
            showImagePicker(for: .camera)
        case .restricted, .denied:
            showPermissionSnackbar(for: "camera")
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }
    
    // MARK: - Gallery Button
    func btnGalleryTapped() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.showImagePicker(for: .photoLibrary)
                    } else {
                        self.showPermissionSnackbar(for: "photo library")
                    }
                }
            }
        case .authorized, .limited:
            showImagePicker(for: .photoLibrary)
        case .restricted, .denied:
            showPermissionSnackbar(for: "photo library")
        @unknown default:
            fatalError("Unknown authorization status")
        }
    }
    
    func showImagePicker(for sourceType: UIImagePickerController.SourceType) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            imagePicker.allowsEditing = true
            if sourceType == .camera {
                imagePicker.cameraDevice = .front
            }
            DispatchQueue.main.async {
                self.present(imagePicker, animated: true, completion: nil)
            }
        } else {
            print("\(sourceType) is not available")
        }
    }
    
    func showPermissionSnackbar(for feature: String) {
        let messageKey: String
        
        switch feature {
        case "camera":
            messageKey = "We need access to your camera to set the profile picture."
        case "photo library":
            messageKey = "We need access to your photo library to set the profile picture."
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
    
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        showLottieLoader()
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            
            if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                
                print("📱 New Custom Cover Image Added:")
                print("=====================================")
                print("Source: \(picker.sourceType == .camera ? "Camera" : "Gallery")")
                print("Image URL: \(fileURL.absoluteString)")
                print("=====================================")
            }
            
            customImages.insert((selectedImage), at: 0)
            ImageImageView.image = selectedImage
            selectedAudioIndex = 0
            saveImages()
            
            DispatchQueue.main.async {
                self.imageCustomCollectionView.reloadData()
                let indexPath = IndexPath(item: 1, section: 0)
                self.imageCustomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.selectedCoverPage1Index = indexPath
                self.imageCustomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.hideLottieLoader()
                self.favouriteButton.isHidden = true
            }
        } else {
            hideLottieLoader()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func loadSavedImages() {
        showLottieLoader()
        if let savedImagesData = UserDefaults.standard.object(forKey: "is_UserSelectedImages") as? Data {
            do {
                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [UIImage] {
                    customImages = decodedImages
                    imageCustomCollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved images: \(error)")
            }
        }
        selectedCoverPage1Index = nil
        hideLottieLoader()
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customImages, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: "is_UserSelectedImages")
        }
    }
    
    func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "Heart_Fill" : "Heart"
        favouriteButton.setImage(UIImage(named: imageName), for: .normal)
    }
}
