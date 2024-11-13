//
//  FavCoverPageVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 12/11/24.
//

import UIKit
import Alamofire
import SDWebImage
import Photos
import Lottie

class FavCoverPageVC: UIViewController {
    
    // MARK: - outlet
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var coverPage1CollectionView: UICollectionView!
    @IBOutlet weak var coverPage2CollectionView: UICollectionView!
    @IBOutlet weak var coverPage3CollectionView: UICollectionView!
    @IBOutlet weak var coverPage1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverPage2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverPage3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeightsConstraint: NSLayoutConstraint!
    @IBOutlet weak var doneButton: UIButton!
    
    // MARK: - variable
    var selectedCase: Int = 0
    var passedFile: String?
    var passedName: String?
    var passedItemId: Int = 0
    var passedIsFavourite: Bool = false
    var passedImage: String = ""
    var passedPremium: Bool = false
    var isLoading = true
    private var selectedCoverIndex: Int?
    let emojiViewModel = EmojiViewModel()
    var selectedEmojiCoverIndex: IndexPath?
    var selectedCustomCoverIndex: IndexPath?
    var selectedCoverImageURL: String?
    var selectedRealisticCoverIndex: IndexPath?
    private var noDataView: NoDataBottomBarView!
    let realisticViewModel = RealisticViewModel()
    private var noInternetView: NoInternetBottombarView!
    var customCoverImages: [UIImage] = []
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.revealViewController()?.gestureEnabled = false
    }
    
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.revealViewController()?.gestureEnabled = true
    }
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadSavedImages()
        self.setupNoDataView()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.checkInternetAndFetchData()
        
        print("Received Data in FavCoverPageVC:")
        print("File: \(passedFile ?? "N/A")")
        print("Name: \(passedName ?? "N/A")")
        print("----------------")
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            self.fetchEmojiCoverPages()
            self.fetchRealisticCoverPages()
            self.noInternetView?.isHidden = true
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    func setupUI() {
        coverPage1CollectionView.delegate = self
        coverPage1CollectionView.dataSource = self
        coverPage2CollectionView.delegate = self
        coverPage2CollectionView.dataSource = self
        coverPage3CollectionView.delegate = self
        coverPage3CollectionView.dataSource = self
        
        self.coverPage2CollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.coverPage3CollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollViewHeightsConstraint.constant = 800
            coverPage1HeightConstraint.constant = 180
            coverPage2HeightConstraint.constant = 180
            coverPage3HeightConstraint.constant = 180
        } else {
            scrollViewHeightsConstraint.constant = 650
            coverPage1HeightConstraint.constant = 140
            coverPage2HeightConstraint.constant = 140
            coverPage3HeightConstraint.constant = 140
        }
        self.view.layoutIfNeeded()
    }
    
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        switch selectedCase {
        case 1:  // Audio
            self.dismiss(animated: false) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AudioVC") as! AudioVC
                    vc.selectedCoverImageURL = self.selectedCoverImageURL
                    rootViewController.pushViewController(vc, animated: true)
                }
            }
        case 2:  // Video
            self.dismiss(animated: false) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "VideoVC") as! VideoVC
                    vc.selectedCoverImageURL = self.selectedCoverImageURL
                    rootViewController.pushViewController(vc, animated: true)
                }
            }
        case 3:  // Image
            self.dismiss(animated: false) {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootViewController = scene.windows.first?.rootViewController as? UINavigationController {
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ImageVC") as! ImageVC
                    vc.selectedCoverImageURL = self.selectedCoverImageURL
                    rootViewController.pushViewController(vc, animated: true)
                }
            }
        default:
            return
        }
    }
    
    func fetchEmojiCoverPages() {
        emojiViewModel.fetchEmojiCoverPages { [weak self] success in
            guard let self = self else { return }
            if success {
                if self.emojiViewModel.emojiCoverPages.isEmpty {
                    self.noDataView.isHidden = false
                } else {
                    self.hideSkeletonLoader()
                    self.noDataView.isHidden = true
                    self.coverPage2CollectionView.reloadData()
                }
            } else if let errorMessage = self.emojiViewModel.errorMessage {
                self.hideSkeletonLoader()
                self.noDataView.isHidden = false
                print("Error fetching cover pages: \(errorMessage)")
            }
        }
    }
    
    func fetchRealisticCoverPages() {
        realisticViewModel.fetchRealisticCoverPages { [weak self] success in
            guard let self = self else { return }
            if success {
                if self.emojiViewModel.emojiCoverPages.isEmpty {
                    self.noDataView.isHidden = false
                } else {
                    self.hideSkeletonLoader()
                    self.noDataView.isHidden = true
                    self.coverPage3CollectionView.reloadData()
                }
            } else if let errorMessage = self.emojiViewModel.errorMessage {
                self.hideSkeletonLoader()
                self.noDataView.isHidden = false
                print("Error fetching cover pages: \(errorMessage)")
            }
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
            noDataView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor, constant: 16),
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
            noInternetView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor, constant: 16),
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
        coverPage2CollectionView.reloadData()
        coverPage3CollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        coverPage2CollectionView.reloadData()
        coverPage3CollectionView.reloadData()
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension FavCoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == coverPage1CollectionView {
            return 1 + customCoverImages.count
        } else if collectionView == coverPage2CollectionView {
            return isLoading ? 10 : emojiViewModel.emojiCoverPages.count
        } else if collectionView == coverPage3CollectionView {
            return isLoading ? 10 : realisticViewModel.realisticCoverPages.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == coverPage1CollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCoverPageCollectionCell", for: indexPath) as! AddCoverPageCollectionCell
                cell.imageView.image = UIImage(systemName: "plus")
                cell.addCoverPageLabel.text = "Cover Page"
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverPage1CollectionCell", for: indexPath) as! CoverPage1CollectionCell
                cell.imageView.image = customCoverImages[indexPath.item - 1]
                return cell
            }
        } else if collectionView == coverPage2CollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverPage2CollectionCell", for: indexPath) as! CoverPage2CollectionCell
                let coverPageData = emojiViewModel.emojiCoverPages[indexPath.row]
                cell.configure(with: coverPageData)
                return cell
            }
        } else if collectionView == coverPage3CollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverPage3CollectionCell", for: indexPath) as! CoverPage3CollectionCell
                let coverPageData = realisticViewModel.realisticCoverPages[indexPath.row]
                cell.configure(with: coverPageData)
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isLoading else { return }
        if collectionView == coverPage1CollectionView {
            if let cell = collectionView.cellForItem(at: indexPath) {
                if indexPath.item == 0 {
                    handleCoverPage1Selection(at: indexPath, sender: cell)
                } else {
                    let customImage = customCoverImages[indexPath.item - 1]
                    selectedCoverIndex = indexPath.item - 1
                    
                    let temporaryDirectory = NSTemporaryDirectory()
                    let fileName = "\(UUID().uuidString).jpg"
                    let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
                    
                    if let imageData = customImage.jpegData(compressionQuality: 1.0) {
                        try? imageData.write(to: fileURL)
                        self.selectedCoverImageURL = fileURL.absoluteString
                        
                        print("📱 Selected Custom Cover Image:")
                        print("=====================================")
                        print("Image URL: \(fileURL.absoluteString)")
                        print("=====================================")
                    }
                    handleCoverPage1Selection(at: indexPath, sender: cell)
                }
            }
        } else if collectionView == coverPage2CollectionView {
            let coverPageData = emojiViewModel.emojiCoverPages[indexPath.item]
            self.selectedCoverImageURL = coverPageData.coverURL
            
            print("📱 Selected Emoji Cover:")
            print("=====================================")
            print("Cover URL: \(coverPageData.coverURL)")
            print("Item ID: \(coverPageData.itemID)")
            print("Is Premium: \(coverPageData.coverPremium)")
            print("Is Favorite: \(coverPageData.isFavorite)")
            print("=====================================")
            
            self.updateSelectionForCollectionView(collectionView, at: indexPath)
            self.deselectCellsInOtherCollectionViews(except: collectionView)
            
        } else if collectionView == coverPage3CollectionView {
            let coverPageData = realisticViewModel.realisticCoverPages[indexPath.item]
            self.selectedCoverImageURL = coverPageData.coverURL
            
            print("📱 Selected Realistic Cover:")
            print("=====================================")
            print("Cover URL: \(coverPageData.coverURL)")
            print("Item ID: \(coverPageData.itemID)")
            print("Is Premium: \(coverPageData.coverPremium)")
            print("Is Favorite: \(coverPageData.isFavorite)")
            print("=====================================")
            
            self.updateSelectionForCollectionView(collectionView, at: indexPath)
            self.deselectCellsInOtherCollectionViews(except: collectionView)
        }
    }
    
    private func handleCoverPage1Selection(at indexPath: IndexPath, sender: UIView) {
        if indexPath.item == 0 {
            showImageOptionsActionSheet(sourceView: sender)
        } else {
            let imageIndex = indexPath.item - 1
            let selectedImage = customCoverImages[imageIndex]
            selectedCustomCoverIndex = indexPath
            deselectCellsInOtherCollectionViews(except: coverPage1CollectionView)
        }
    }
    
    private func updateSelectionForCollectionView(_ collectionView: UICollectionView, at indexPath: IndexPath) {
        if collectionView == coverPage2CollectionView {
            selectedEmojiCoverIndex = indexPath
        } else if collectionView == coverPage3CollectionView {
            selectedRealisticCoverIndex = indexPath
        }
    }
    
    private func deselectCellsInOtherCollectionViews(except currentCollectionView: UICollectionView) {
        if currentCollectionView != coverPage1CollectionView {
            if let previousIndex = selectedCustomCoverIndex {
                coverPage1CollectionView.deselectItem(at: previousIndex, animated: true)
                selectedCustomCoverIndex = nil
            }
        }
        if currentCollectionView != coverPage2CollectionView {
            if let previousIndex = selectedEmojiCoverIndex {
                coverPage2CollectionView.deselectItem(at: previousIndex, animated: true)
                selectedEmojiCoverIndex = nil
            }
        }
        if currentCollectionView != coverPage3CollectionView {
            if let previousIndex = selectedRealisticCoverIndex {
                coverPage3CollectionView.deselectItem(at: previousIndex, animated: true)
                selectedRealisticCoverIndex = nil
            }
        }
    }
    
    private func presentPremiumViewController() {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumVC") as! PremiumVC
        present(premiumVC, animated: true, completion: nil)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 155 : 115
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 165 : 125
        
        if collectionView == coverPage1CollectionView {
            if indexPath.item == 0 {
                return CGSize(width: width, height: height)
            }
            return CGSize(width: width, height: height)
        } else if collectionView == coverPage2CollectionView {
            return CGSize(width: width, height: height)
        } else if collectionView == coverPage3CollectionView {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if indexPath.item == emojiViewModel.emojiCoverPages.count - 1 && !emojiViewModel.isLoading && emojiViewModel.hasMorePages {
            fetchEmojiCoverPages()
        } else if indexPath.item == realisticViewModel.realisticCoverPages.count - 1 && !realisticViewModel.isLoading && realisticViewModel.hasMorePages {
            fetchRealisticCoverPages()
        }
    }
}

extension FavCoverPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            
            if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                self.selectedCoverImageURL = fileURL.absoluteString
                
                print("📱 New Custom Cover Image Added:")
                print("=====================================")
                print("Source: \(picker.sourceType == .camera ? "Camera" : "Gallery")")
                print("Image URL: \(fileURL.absoluteString)")
                print("=====================================")
            }
            customCoverImages.insert(selectedImage, at: 0)
            selectedCoverIndex = 0
            saveImages()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.coverPage1CollectionView.reloadData()
                let indexPath = IndexPath(item: 1, section: 0)
                self.coverPage1CollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.selectedCustomCoverIndex = indexPath
                self.coverPage1CollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadSavedImages() {
        if let savedImagesData = UserDefaults.standard.object(forKey: "is_UserSelectedCoverImages") as? Data {
            do {
                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [UIImage] {
                    customCoverImages = decodedImages
                    coverPage1CollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved images: \(error)")
            }
        }
        selectedCustomCoverIndex = nil
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customCoverImages, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: "is_UserSelectedCoverImages")
        }
    }
}

extension FavCoverPageVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
