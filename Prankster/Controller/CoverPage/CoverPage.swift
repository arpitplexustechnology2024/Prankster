//
//  CoverPage.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 24/01/25.
//

import UIKit
import Photos

class CoverPageViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var chipSelector: ChipSelectorView!
    @IBOutlet weak var topCollectionView: UICollectionView!
    @IBOutlet weak var bottomCollectionView: UICollectionView!
    var searchBar: UISearchBar!
    
    var isLoading = true
    var selectedCustomImage: UIImage?
    var selectedCoverImageURL: String?
    var selectedCoverImageFile: Data?
    var selectedCoverImageName: String?
    var viewType: CoverViewType = .audio
    private var selectedCoverIndex: Int?
    let emojiViewModel = EmojiViewModel()
    var customCoverImages: [UIImage] = []
    var selectedEmojiCoverIndex: IndexPath?
    var selectedCustomCoverIndex: IndexPath?
    var selectedRealisticCoverIndex: IndexPath?
    private var noDataView: NoDataBottomBarView!
    let realisticViewModel = RealisticViewModel()
    private var selectedCoverImageData: CoverPageData?
    private var noInternetView: NoInternetBottombarView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.loadSavedImages()
        self.hideKeyboardTappedAround()
        self.topCollectionView.delegate = self
        self.topCollectionView.dataSource = self
        self.topCollectionView.isPagingEnabled = true
        self.bottomCollectionView.delegate = self
        self.bottomCollectionView.dataSource = self
        
        self.bottomCollectionView.reloadData()
        self.topCollectionView.reloadData()
//        let bottomIndexPath = !customCoverImages.isEmpty ? IndexPath(item: 1, section: 0) : IndexPath(item: 0, section: 0)
//        let topIndexPath = IndexPath(item: 0, section: 0)
//        self.bottomCollectionView.selectItem(at: bottomIndexPath, animated: true, scrollPosition: .centeredHorizontally)
//        self.topCollectionView.selectItem(at: topIndexPath, animated: false, scrollPosition: [])
//        self.selectedCustomCoverIndex = !customCoverImages.isEmpty ? bottomIndexPath : nil
//        self.bottomCollectionView.scrollToItem(at: bottomIndexPath, at: .centeredHorizontally, animated: true)
//        self.topCollectionView.scrollToItem(at: topIndexPath, at: .centeredHorizontally, animated: true)
    }
    
    func setupUI() {
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Cover page"
        titleLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
        titleLabel.textColor = .white
        navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: titleLabel)]
        
        searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search Album Title"
        searchBar.barStyle = .black
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .white
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search cover image",
                attributes: [.foregroundColor: UIColor.lightGray]
            )
        }
        
        if let textField = searchBar.value(forKey: "searchField") as? UITextField,
           let leftIconView = textField.leftView as? UIImageView {
            leftIconView.tintColor = .lightGray
            leftIconView.image = leftIconView.image?.withRenderingMode(.alwaysTemplate)
        }
        
        chipSelector.onSelectionChanged = { [weak self] selectedType in
            guard let self = self else { return }

            if selectedType == "Add cover image 📸" {
                navigationItem.rightBarButtonItem = nil
                self.bottomCollectionView.reloadData()
                self.topCollectionView.reloadData()
                let bottomIndexPath = !customCoverImages.isEmpty ? IndexPath(item: 1, section: 0) : IndexPath(item: 0, section: 0)
                let topIndexPath = IndexPath(item: 0, section: 0)
                self.bottomCollectionView.selectItem(at: bottomIndexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.topCollectionView.selectItem(at: topIndexPath, animated: false, scrollPosition: [])
                self.selectedCustomCoverIndex = !customCoverImages.isEmpty ? bottomIndexPath : nil
                self.bottomCollectionView.scrollToItem(at: bottomIndexPath, at: .centeredHorizontally, animated: true)
                self.topCollectionView.scrollToItem(at: topIndexPath, at: .centeredHorizontally, animated: true)
            } else {
                let searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchBarTapped))
                searchButton.tintColor = .white
                navigationItem.rightBarButtonItem = searchButton
                self.bottomCollectionView.reloadData()
                self.topCollectionView.reloadData()
                let indexPath = IndexPath(item: 0, section: 0)
                self.bottomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.topCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedCustomCoverIndex = indexPath
                self.bottomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.topCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
    
    @objc func searchBarTapped() {
        chipSelector.setSearchBarActiveState(true)
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.tintColor = .white
        navigationItem.leftBarButtonItems = [backButton]
        
        navigationItem.rightBarButtonItem = nil
        navigationItem.titleView = searchBar
        searchBar.becomeFirstResponder()
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        chipSelector.setSearchBarActiveState(false)
        searchBar.resignFirstResponder()
        searchBar.text = ""
        navigationItem.titleView = nil
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(backButtonTapped))
        backButton.tintColor = .white
        
        let titleLabel = UILabel()
        titleLabel.text = "Cover page"
        titleLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
        titleLabel.textColor = .white
        
        navigationItem.leftBarButtonItems = [backButton, UIBarButtonItem(customView: titleLabel)]
        
        let searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchBarTapped))
        searchButton.tintColor = .white
        navigationItem.rightBarButtonItem = searchButton
    }
    
    @objc func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
}

extension CoverPageViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == topCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            return selectedChipTitle == "Add cover image 📸" ? (customCoverImages.isEmpty ? 1 : customCoverImages.count) : 2
        } else if collectionView == bottomCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            return selectedChipTitle == "Add cover image 📸" ? 1 + customCoverImages.count : 2
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == topCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CovertopCollectionViewCell", for: indexPath) as! CovertopCollectionViewCell
            
            if selectedChipTitle == "Add cover image 📸" {
                cell.imageName.text = customCoverImages.isEmpty ? "Funny name" : "Custom Cover"
                cell.imageView.image = customCoverImages.isEmpty ? UIImage(named: "Pranksters") : customCoverImages[indexPath.item]
            } else {
                cell.imageName.text = "Funny name"
                cell.imageView.image = UIImage(named: "Pranksters")
            }
            return cell
        } else if collectionView == bottomCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                if indexPath.item == 0 {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddCoverPageCollectionCell", for: indexPath) as! AddCoverPageCollectionCell
                    cell.addCoverPageLabel.text = "Add cover"
                    cell.imageView.image = UIImage(named: "AddCover")
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverSliderCollectionViewCell", for: indexPath) as! CoverSliderCollectionViewCell
                    cell.imageView.image = customCoverImages[indexPath.item - 1]
                    return cell
                }
            } else { // "Realistic cover image 😂"
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CoverSliderCollectionViewCell", for: indexPath) as! CoverSliderCollectionViewCell
                cell.imageView.image = UIImage(named: "Pranksters")
                return cell
            }
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == bottomCollectionView {
            let selectedChipTitle = chipSelector.getSelectedChipTitle()
            
            if selectedChipTitle == "Add cover image 📸" {
                if let cell = collectionView.cellForItem(at: indexPath) {
                    if indexPath.item == 0 {
                        handleCoverPage1Selection(at: indexPath, sender: cell)
                    } else {
                        //  showLottieLoader()
                        let customImage = customCoverImages[indexPath.item - 1]
                        selectedCoverIndex = indexPath.item - 1
                        
                        let temporaryDirectory = NSTemporaryDirectory()
                        let fileName = "\(UUID().uuidString).jpg"
                        let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
                        
                        if let imageData = customImage.jpegData(compressionQuality: 1.0) {
                            try? imageData.write(to: fileURL)
                            if let fileData = try? Data(contentsOf: fileURL) {
                                self.selectedCoverImageFile = fileData
                                self.selectedCoverImageURL = nil
                                self.selectedCoverImageName = "Custom Cover Image"
                            }
                            print("Custom Cover Image URL: \(fileURL.absoluteString)")
                        }
                        //   hideLottieLoader()
                        handleCoverPage1Selection(at: indexPath, sender: cell)
                    }
                }
            } else {
                
            }
        } else if collectionView == topCollectionView {

        }
    }
    
    private func handleCoverPage1Selection(at indexPath: IndexPath, sender: UIView) {
        if indexPath.item == 0 {
            showImageOptionsActionSheet(sourceView: sender)
        } else {
            let imageIndex = indexPath.item - 1
            let selectedImage = customCoverImages[imageIndex]
            selectedCustomCoverIndex = indexPath
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == topCollectionView {
            return collectionView.frame.size
        } else {
            if indexPath.item == 0 {
                return CGSize(width: 90, height: 90)
            }
            return CGSize(width: 90, height: 90)
        }
    }
}


// MARK: - UIImagePickerControllerDelegate, UINavigationControllerDelegate
extension CoverPageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Show ImageOptions ActionSheet
    private func showImageOptionsActionSheet(sourceView: UIView) {
        let titleString = NSAttributedString(string: "Select cover image", attributes: [
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
    
    // MARK: - showImagePicker
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
    
    // MARK: - Show permission snackbar
    func showPermissionSnackbar(for feature: String) {
        let messageKey: String
        
        switch feature {
        case "camera":
            messageKey = "We need access to your camera to set the cover image."
        case "photo library":
            messageKey = "We need access to your photo library to set the cover image."
        default:
            messageKey = "We need access to your camera to set the cover image."
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
       // showLottieLoader()
        if let selectedImage = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            
            if let imageData = selectedImage.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                if let fileData = try? Data(contentsOf: fileURL) {
                    self.selectedCoverImageFile = fileData
                    self.selectedCoverImageURL = nil
                    self.selectedCoverImageName = "Custom Cover Image"
                }
                print("Custom Cover Image URL: \(fileURL.absoluteString)")
                
                customCoverImages.insert(selectedImage, at: 0)
                selectedCoverIndex = 0
                saveImages()
                
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    
                    self.bottomCollectionView.reloadData()
                    self.topCollectionView.reloadData()
                    let indexPath = IndexPath(item: 1, section: 0)
                    let indexPath1 = IndexPath(item: 0, section: 0)
                    self.bottomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.topCollectionView.selectItem(at: indexPath1, animated: false, scrollPosition: [])
                    self.selectedCustomCoverIndex = indexPath
                    self.bottomCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                    self.topCollectionView.scrollToItem(at: indexPath1, at: .centeredHorizontally, animated: true)
                  //  self.hideLottieLoader()
                }
            }
        } else {
          //  hideLottieLoader()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadSavedImages() {
      //  showLottieLoader()
        if let savedImagesData = UserDefaults.standard.object(forKey: ConstantValue.is_UserCoverImages) as? Data {
            do {
                if let decodedImages = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(savedImagesData) as? [UIImage] {
                    customCoverImages = decodedImages
                    bottomCollectionView.reloadData()
                    topCollectionView.reloadData()
                }
            } catch {
                print("Error decoding saved images: \(error)")
            }
        }
        selectedCustomCoverIndex = nil
      //  hideLottieLoader()
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customCoverImages, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: ConstantValue.is_UserCoverImages)
        }
    }
}
