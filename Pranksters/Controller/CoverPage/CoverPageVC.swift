//
//  CoverPageVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import Alamofire
import SDWebImage
import Photos
import Lottie

class CoverPageVC: UIViewController {
    
    // MARK: - outlet
    @IBOutlet weak var coverView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var oneTimeBlurView: UIView!
    @IBOutlet weak var floatingButton: UIButton!
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet var floatingCollectionButton: [UIButton]!
    @IBOutlet weak var lottieLoader: LottieAnimationView!
    @IBOutlet weak var coverPage1CollectionView: UICollectionView!
    @IBOutlet weak var coverPage2CollectionView: UICollectionView!
    @IBOutlet weak var coverPage3CollectionView: UICollectionView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverPage1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverPage2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverPage3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewHeightConstraint: NSLayoutConstraint!
    
    
    // MARK: - variable
    var isLoading = true
    var selectedCustomImage: UIImage?
    var viewType: CoverViewType = .audio
    private var selectedCoverIndex: Int?
    let emojiViewModel = EmojiViewModel()
    let plusImage = UIImage(named: "Plus")
    var selectedEmojiCoverIndex: IndexPath?
    var selectedCustomCoverIndex: IndexPath?
    let cancelImage = UIImage(named: "Cancel")
    var selectedCoverImageURL: String?
    var selectedRealisticCoverIndex: IndexPath?
    private var noDataView: NoDataBottomBarView!
    let realisticViewModel = RealisticViewModel()
    private var selectedCoverImageData: CoverPageData?
    private let favoriteViewModel = FavoriteViewModel()
    private var noInternetView: NoInternetBottombarView!
    var customCoverImages: [UIImage] = []
    private var currentCoverIsFavorite: Bool = false {
        didSet {
            updateFavoriteButton(isFavorite: currentCoverIsFavorite)
        }
    }
    
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
        self.setupLottieLoader()
        self.showSkeletonLoader()
        self.setupNoInternetView()
        self.setupFloatingButtons()
        self.checkInternetAndFetchData()
        self.navigationbarView.addBottomShadow()
        self.favouriteButton.isHidden = true
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
        if defaults.bool(forKey: "hasLaunchedCover") {
            return false
        } else {
            defaults.set(true, forKey: "hasLaunchedCover")
            return true
        }
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
        
        coverImageView.layer.cornerRadius = 8
        coverView.layer.cornerRadius = 8
        coverView.layer.shadowColor = UIColor.black.cgColor
        coverView.layer.shadowOpacity = 0.1
        coverView.layer.shadowOffset = CGSize(width: 0, height: 3)
        coverView.layer.shadowRadius = 12
        
        coverPage1CollectionView.delegate = self
        coverPage1CollectionView.dataSource = self
        coverPage2CollectionView.delegate = self
        coverPage2CollectionView.dataSource = self
        coverPage3CollectionView.delegate = self
        coverPage3CollectionView.dataSource = self
        
        self.oneTimeBlurView.isHidden = true
        if isFirstLaunch() {
            self.oneTimeBlurView.isHidden = false
        } else {
            self.oneTimeBlurView.isHidden = true
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        oneTimeBlurView.addGestureRecognizer(tapGesture)
        oneTimeBlurView.isUserInteractionEnabled = true
        self.coverPage2CollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        self.coverPage3CollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        coverImageView.loadGif(name: "CoverGIF")
        if UIDevice.current.userInterfaceIdiom == .pad {
            coverImageViewHeightConstraint.constant = 280
            coverImageViewWidthConstraint.constant = 245
            scrollViewHeightConstraint.constant = 750
            coverPage1HeightConstraint.constant = 180
            coverPage2HeightConstraint.constant = 180
            coverPage3HeightConstraint.constant = 180
        } else {
            coverImageViewHeightConstraint.constant = 240
            coverImageViewWidthConstraint.constant = 205
            scrollViewHeightConstraint.constant = 600
            coverPage1HeightConstraint.constant = 140
            coverPage2HeightConstraint.constant = 140
            coverPage3HeightConstraint.constant = 140
        }
        self.view.layoutIfNeeded()
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
    
    private func setupLottieLoader() {
        lottieLoader.isHidden = true
        lottieLoader.loopMode = .loop
        lottieLoader.contentMode = .scaleAspectFill
        lottieLoader.animation = LottieAnimation.named("Loader")
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
        if let imageURL = selectedCoverImageURL {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            switch viewType {
            case .audio:
                if isConnectedToInternet() {
                    if let nextVC = storyboard.instantiateViewController(identifier: "AudioVC") as? AudioVC {
                        nextVC.selectedCoverImageURL = imageURL
                        self.navigationController?.pushViewController(nextVC, animated: true)
                    }
                } else {
                    let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
                
            case .video:
                if isConnectedToInternet() {
                    if let nextVC = storyboard.instantiateViewController(identifier: "VideoVC") as? VideoVC {
                        nextVC.selectedCoverImageURL = imageURL
                        self.navigationController?.pushViewController(nextVC, animated: true)
                    }
                } else {
                    let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
                
            case .image:
                if isConnectedToInternet() {
                    if let nextVC = storyboard.instantiateViewController(identifier: "ImageVC") as? ImageVC {
                        nextVC.selectedCoverImageURL = imageURL
                        self.navigationController?.pushViewController(nextVC, animated: true)
                    }
                } else {
                    let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                    snackbar.show(in: self.view, duration: 3.0)
                }
            }
        } else {
            let alert = UIAlertController(title: "No Cover Selected",
                                          message: "Please select a cover before proceeding.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnCoverPage1ShowAllTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let customCoverAllVC = storyboard.instantiateViewController(withIdentifier: "CustomCoverPageVC") as? CustomCoverPageVC {
            customCoverAllVC.allCustomCovers = Array(customCoverImages)
            self.navigationController?.pushViewController(customCoverAllVC, animated: true)
        }
    }
    
    @IBAction func btnCoverPage2ShowAllTapped(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "EmojiCoverPageVC") as! EmojiCoverPageVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnCoverPage3ShowAllTapped(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "RealisticCoverPageVC") as! RealisticCoverPageVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func fetchEmojiCoverPages() {
        emojiViewModel.resetPagination()
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
        realisticViewModel.resetPagination()
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
            noDataView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
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
            noInternetView.topAnchor.constraint(equalTo: coverImageView.bottomAnchor, constant: 16),
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
    
    func showLottieLoader() {
        lottieLoader.isHidden = false
        coverImageView.isHidden = true
        favouriteButton.isHidden = true
        lottieLoader.play()
    }
    
    func hideLottieLoader() {
        lottieLoader.stop()
        lottieLoader.isHidden = true
        coverImageView.isHidden = false
        favouriteButton.isHidden = false
    }
    
    @IBAction func btnFavouriteSetTapped(_ sender: UIButton) {
        if let selectedData = selectedCoverImageData {
            let newFavoriteStatus = !currentCoverIsFavorite
            
            favoriteViewModel.setFavorite(itemId: selectedData.itemID,
                                          isFavorite: newFavoriteStatus,
                                          categoryId: 4) { [weak self] success, message in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.currentCoverIsFavorite = newFavoriteStatus
                        self.updateFavoriteButton(isFavorite: newFavoriteStatus)
                        self.selectedCoverImageData?.isFavorite = newFavoriteStatus
                        
                        print("=== Favorite Status Updated ===")
                        print("Item ID: \(selectedData.itemID)")
                        print("New Favorite Status: \(newFavoriteStatus)")
                        print("\(message ?? "Success")")
                        print("==============================")
                    } else {
                        print("Failed to update favorite status: \(message ?? "Unknown error")")
                        self.updateFavoriteButton(isFavorite: self.currentCoverIsFavorite)
                    }
                }
            }
        } else if let selectedCoverPage = getSelectedCoverPage() {
            
            let favoriteViewModel = FavoriteViewModel()
            let newFavoriteStatus = !selectedCoverPage.isFavorite
            let categoryId: Int = 4
            
            favoriteViewModel.setFavorite(itemId: selectedCoverPage.itemID, isFavorite: newFavoriteStatus, categoryId: categoryId) { [weak self] success, message in
                guard let self = self else { return }
                
                if success {
                    self.updateFavoriteStatus(newStatus: newFavoriteStatus)
                    print(message ?? "Favorite status updated successfully")
                } else {
                    print("Failed to update favorite status: \(message ?? "Unknown error")")
                }
            }
        } else {
            guard let selectedIndex = selectedCoverIndex else { return }
            currentCoverIsFavorite.toggle()
            updateFavoriteButton(isFavorite: currentCoverIsFavorite)
            coverPage1CollectionView.reloadItems(at: [IndexPath(item: selectedIndex + 1, section: selectedIndex + 1)])
            saveImages()
        }
    }
    
    func updateSelectedImage(with coverData: CoverPageData, customImage: UIImage? = nil) {
        showLottieLoader()
        selectedCoverImageData = coverData
        selectedCoverImageURL = coverData.coverURL
        
        if let customImage = customImage {
            // Handle custom image
            self.coverImageView.image = customImage
            self.selectedCustomImage = customImage
            self.hideLottieLoader()
            self.favouriteButton.isHidden = true
            
            let temporaryDirectory = NSTemporaryDirectory()
            let fileName = "\(UUID().uuidString).jpg"
            let fileURL = URL(fileURLWithPath: temporaryDirectory).appendingPathComponent(fileName)
            
            if let imageData = customImage.jpegData(compressionQuality: 1.0) {
                try? imageData.write(to: fileURL)
                self.selectedCoverImageURL = fileURL.absoluteString
                
                print("Selected Custom Image from Preview:")
                print("=====================================")
                print("Image URL: \(fileURL.absoluteString)")
                print("=====================================")
            }
            
        } else if let url = URL(string: coverData.coverURL) {
            // Handle remote image
            coverImageView.sd_setImage(with: url) { [weak self] (image, error, cacheType, imageURL) in
                self?.hideLottieLoader()
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                } else {
                    print("=== Selected Image from Preview ===")
                    print("Cover URL: \(coverData.coverURL)")
                    print("Is Favorite: \(coverData.isFavorite)")
                    print("Item ID: \(coverData.itemID)")
                    print("Premium: \(coverData.coverPremium)")
                    print("=====================================")
                    self?.favouriteButton.isHidden = false
                    self?.currentCoverIsFavorite = coverData.isFavorite
                    self?.updateFavoriteButton(isFavorite: coverData.isFavorite)
                }
            }
        }
    }
    
    private func getSelectedCoverPage() -> CoverPageData? {
        if let selectedIndex = selectedEmojiCoverIndex {
            return emojiViewModel.emojiCoverPages[selectedIndex.item]
        } else if let selectedIndex = selectedRealisticCoverIndex {
            return realisticViewModel.realisticCoverPages[selectedIndex.item]
        }
        return nil
    }
    
    private func updateFavoriteStatus(newStatus: Bool) {
        if let selectedIndex = selectedEmojiCoverIndex {
            emojiViewModel.emojiCoverPages[selectedIndex.item].isFavorite = newStatus
        } else if let selectedIndex = selectedRealisticCoverIndex {
            realisticViewModel.realisticCoverPages[selectedIndex.item].isFavorite = newStatus
        }
        updateFavoriteButton(isFavorite: newStatus)
    }
    
    func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "Heart_Fill" : "Heart"
        favouriteButton.setImage(UIImage(named: imageName), for: .normal)
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension CoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
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
                    showLottieLoader()
                    let customImage = customCoverImages[indexPath.item - 1]
                    selectedCoverIndex = indexPath.item - 1
                    coverImageView.image = customImage
                    
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
                    hideLottieLoader()
                    self.favouriteButton.isHidden = true
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
            
            self.favouriteButton.isHidden = false
            handleCellSelection(coverPageData: coverPageData, collectionView: collectionView, indexPath: indexPath)
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
            
            self.favouriteButton.isHidden = false
            handleCellSelection(coverPageData: coverPageData, collectionView: collectionView, indexPath: indexPath)
        }
    }
    
    private func handleCoverPage1Selection(at indexPath: IndexPath, sender: UIView) {
        if indexPath.item == 0 {
            showImageOptionsActionSheet(sourceView: sender)
        } else {
            self.favouriteButton.isHidden = true
            let imageIndex = indexPath.item - 1
            let selectedImage = customCoverImages[imageIndex]
            coverImageView.image = selectedImage
            selectedCustomCoverIndex = indexPath
            deselectCellsInOtherCollectionViews(except: coverPage1CollectionView)
        }
    }
    
    private func handleCellSelection(coverPageData: CoverPageData, collectionView: UICollectionView, indexPath: IndexPath) {
        if coverPageData.coverPremium {
            presentPremiumViewController()
            collectionView.deselectItem(at: indexPath, animated: false)
            
            if collectionView == coverPage2CollectionView, let previousIndex = selectedEmojiCoverIndex {
                collectionView.selectItem(at: previousIndex, animated: false, scrollPosition: [])
            } else if collectionView == coverPage3CollectionView, let previousIndex = selectedRealisticCoverIndex {
                collectionView.selectItem(at: previousIndex, animated: false, scrollPosition: [])
            }
        } else {
            if let imageUrl = URL(string: coverPageData.coverURL) {
                showLottieLoader()
                coverImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder")) { [weak self] (image, error, cacheType, url) in
                    self?.hideLottieLoader()
                    if error == nil {
                        self?.updateSelectionForCollectionView(collectionView, at: indexPath)
                        self?.deselectCellsInOtherCollectionViews(except: collectionView)
                        
                        self?.updateFavoriteButton(isFavorite: coverPageData.isFavorite)
                    } else {
                        print("Error loading image: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
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
}

extension CoverPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
                self.selectedCoverImageURL = fileURL.absoluteString
                
                print("📱 New Custom Cover Image Added:")
                print("=====================================")
                print("Source: \(picker.sourceType == .camera ? "Camera" : "Gallery")")
                print("Image URL: \(fileURL.absoluteString)")
                print("=====================================")
            }
            customCoverImages.insert(selectedImage, at: 0)
            coverImageView.image = selectedImage
            selectedCoverIndex = 0
            saveImages()
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.coverPage1CollectionView.reloadData()
                let indexPath = IndexPath(item: 1, section: 0)
                self.coverPage1CollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                self.selectedCustomCoverIndex = indexPath
                self.coverPage1CollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                self.hideLottieLoader()
                self.favouriteButton.isHidden = true
            }
        } else {
            hideLottieLoader()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func loadSavedImages() {
        showLottieLoader()
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
        hideLottieLoader()
    }
    
    func saveImages() {
        if let encodedData = try? NSKeyedArchiver.archivedData(withRootObject: customCoverImages, requiringSecureCoding: false) {
            UserDefaults.standard.set(encodedData, forKey: "is_UserSelectedCoverImages")
        }
    }
}

extension CoverPageVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return CustomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}
