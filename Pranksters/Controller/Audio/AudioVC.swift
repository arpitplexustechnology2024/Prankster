//
//  AudioVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 16/10/24.
//

import UIKit
import Alamofire
import SDWebImage
import Lottie
import AVFoundation
import MobileCoreServices

struct CustomAudio: Codable {
    let fileName: String
    let imageFileName: String
    
    init(fileName: String, imageFileName: String) {
        self.fileName = fileName
        self.imageFileName = imageFileName
    }
}

class AudioVC: UIViewController {
    
    // MARK: - outlet
    @IBOutlet weak var songName: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var songMinit: UILabel!
    @IBOutlet weak var AudioShowView: UIView!
    @IBOutlet weak var songProgress: UISlider!
    @IBOutlet weak var oneTimeBlurView: UIView!
    @IBOutlet weak var floatingButton: UIButton!
    @IBOutlet weak var favouriteButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var audioImageView: UIImageView!
    @IBOutlet weak var bottomScrollView: UIScrollView!
    @IBOutlet var floatingCollectionButton: [UIButton]!
    @IBOutlet weak var blureEffect: UIVisualEffectView!
    @IBOutlet weak var lottieLoader: LottieAnimationView!
    @IBOutlet weak var audioCustomCollectionView: UICollectionView!
    @IBOutlet weak var audioCharacterCollectionView: UICollectionView!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioCustomHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var coverImageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioCharacterHeightConstraint: NSLayoutConstraint!
    
    // MARK: - variable
    var isLoading = true
    private var timer: Timer?
    private var isPlaying = false
    var selectedCoverImageURL: String?
    private var selectedAudioIndex: Int?
    let plusImage = UIImage(named: "Plus")
    private var audioPlayer: AVAudioPlayer?
    let cancelImage = UIImage(named: "Cancel")
    var initialAudioData: CharacterAllData?
    private var viewModel: CharacterViewModel!
    private var noDataView: NoDataBottomBarView!
    private var selectedAudioCustomCell: IndexPath?
    private var selectedAudioData: CharacterAllData?
    private var selectedAudioCharacterCell: IndexPath?
    private let favoriteViewModel = FavoriteViewModel()
    private var noInternetView: NoInternetBottombarView!
    private let defaultImages = ["MusicAudio01", "MusicAudio02", "MusicAudio03", "MusicAudio04", "MusicAudio05"]
    private var customAudios: [(url: URL, image: UIImage?)] = [] {
        didSet {
            saveAudios()
        }
    }
    private var currentAudioIsFavorite: Bool = false {
        didSet {
            updateFavoriteButtonImage()
        }
    }
    
    init(viewModel: CharacterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = CharacterViewModel(apiService: CharacterAPIService.shared)
    }
    
    // MARK: - viewWillAppear
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.revealViewController()?.gestureEnabled = false
    }
    
    // MARK: - viewWillDisappear
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        audioPlayer?.stop()
        timer?.invalidate()
        timer = nil
        self.revealViewController()?.gestureEnabled = true
    }
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupSlider()
        setupViewModel()
        setupNoDataView()
        loadSavedAudios()
        setupAudioSession()
        setupLottieLoader()
        showSkeletonLoader()
        setupNoInternetView()
        setupFloatingButtons()
        checkInternetAndFetchData()
        self.navigationbarView.addBottomShadow()
        self.songMinit.isHidden = true
        self.songName.isHidden = true
        self.blureEffect.isHidden = true
        self.songProgress.isHidden = true
        self.favouriteButton.isHidden = true
        self.playPauseButton.isHidden = true
        
        if let audioData = initialAudioData {
            playSelectedAudio(audioData)
        }
        
        if let imageURL = selectedCoverImageURL{
            print("=== Received Data in Cover Image ===")
            print("Image URL: \(imageURL)")
            print("=========================================")
        }
    }
    
    // MARK: - checkInternetAndFetchData
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            viewModel.fetchCharacters(categoryId: 1)
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
        if defaults.bool(forKey: "hasLaunchedAudio") {
            return false
        } else {
            defaults.set(true, forKey: "hasLaunchedAudio")
            return true
        }
    }
    
    // MARK: - setupUI
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
        audioImageView.layer.cornerRadius = 8
        AudioShowView.layer.cornerRadius = 8
        AudioShowView.layer.shadowColor = UIColor.black.cgColor
        AudioShowView.layer.shadowOpacity = 0.1
        AudioShowView.layer.shadowOffset = CGSize(width: 0, height: 3)
        AudioShowView.layer.shadowRadius = 12
        
        blureEffect.layer.cornerRadius = 8
        blureEffect.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        blureEffect.layer.masksToBounds = true
        self.audioCharacterCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
        audioCustomCollectionView.delegate = self
        audioCustomCollectionView.dataSource = self
        audioCharacterCollectionView.delegate = self
        audioCharacterCollectionView.dataSource = self
        audioImageView.loadGif(name: "CoverGIF")
        
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
            audioCustomHeightConstraint.constant = 180
            audioCharacterHeightConstraint.constant = 360
        } else {
            coverImageViewHeightConstraint.constant = 240
            coverImageViewWidthConstraint.constant = 205
            scrollViewHeightConstraint.constant = 530
            audioCustomHeightConstraint.constant = 140
            audioCharacterHeightConstraint.constant = 280
        }
        self.view.layoutIfNeeded()
    }
    
    // MARK: - setupViewModel
    func setupViewModel() {
        viewModel.reloadData = { [weak self] in
            DispatchQueue.main.async {
                if self?.viewModel.characters.isEmpty ?? true {
                    self?.noDataView.isHidden = false
                } else {
                    self?.hideSkeletonLoader()
                    self?.noDataView.isHidden = true
                    self?.audioCharacterCollectionView.reloadData()
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
            noDataView.topAnchor.constraint(equalTo: audioImageView.bottomAnchor, constant: 16),
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
            noInternetView.topAnchor.constraint(equalTo: audioImageView.bottomAnchor, constant: 16),
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
    
    func showSkeletonLoader() {
        isLoading = true
        audioCharacterCollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        audioCharacterCollectionView.reloadData()
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    // MARK: - showLottieLoader
    func showLottieLoader() {
        blureEffect.isHidden = true
        songProgress.isHidden = true
        songName.isHidden = true
        songMinit.isHidden = true
        lottieLoader.isHidden = false
        audioImageView.isHidden = true
        favouriteButton.isHidden = true
        lottieLoader.play()
    }
    
    // MARK: - hideLottieLoader
    func hideLottieLoader() {
        lottieLoader.stop()
        blureEffect.isHidden = false
        songProgress.isHidden = false
        songName.isHidden = false
        songMinit.isHidden = false
        lottieLoader.isHidden = true
        audioImageView.isHidden = false
        favouriteButton.isHidden = false
    }
    
    // MARK: - setupLottieLoader
    private func setupLottieLoader() {
        lottieLoader.isHidden = true
        lottieLoader.loopMode = .loop
        lottieLoader.contentMode = .scaleAspectFill
        lottieLoader.animation = LottieAnimation.named("Loader")
    }
    
    // MARK: - setupFloatingButtons
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
    
    // MARK: - btnFloatingTapped
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
    
    // MARK: - btnMoreAppTapped
    @IBAction func btnMoreAppTapped(_ sender: UIButton) {
        animate(toggel: false)
        floatingButton.setImage(plusImage, for: .normal)
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MoreAppVC") as! MoreAppVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - btnFavouriteTapped
    @IBAction func btnFavouriteTapped(_ sender: UIButton) {
        animate(toggel: false)
        floatingButton.setImage(plusImage, for: .normal)
        //        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "FavouriteViewController") as! FavouriteViewController
        //        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // MARK: - btnPremiumTapped
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
    
    // MARK: - btnDoneTapped
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        var audioURLToPass: String?
        var audioNameToPass: String?
        
        if let selectedIndex = selectedAudioIndex {
            let audioData = customAudios[selectedIndex]
            audioURLToPass = audioData.url.absoluteString
            audioNameToPass = audioData.url.lastPathComponent
        }
        else if let selectedData = selectedAudioData {
            audioURLToPass = selectedData.file
            audioNameToPass = selectedData.name
        }
        
        if let audioURL = audioURLToPass {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let nextVC = storyboard.instantiateViewController(withIdentifier: "PremiumVC") as? PremiumVC {
                nextVC.selectedAudioURL = audioURL
                nextVC.selectedAudioName = audioNameToPass
                nextVC.selectedCoverImageURL = selectedCoverImageURL
                self.navigationController?.pushViewController(nextVC, animated: true)
            }
        } else {
            let alert = UIAlertController(title: "No Audio Selected",
                                          message: "Please select an audio before proceeding.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    // MARK: - btnBackTapped
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - btnFavouriteSetTapped
    @IBAction func btnFavouriteSetTapped(_ sender: UIButton) {
        if let customAudioIndex = selectedAudioIndex {
            currentAudioIsFavorite.toggle()
            saveAudios()
            audioCustomCollectionView.reloadItems(at: [IndexPath(item: customAudioIndex + 1, section: customAudioIndex + 1)])
        } else if let audioData = selectedAudioData {
            let newFavoriteStatus = !currentAudioIsFavorite
            favoriteViewModel.setFavorite(itemId: audioData.itemID, isFavorite: newFavoriteStatus, categoryId: 1) { [weak self] success, message in
                guard let self = self else { return }
                
                DispatchQueue.main.async {
                    if success {
                        self.currentAudioIsFavorite = newFavoriteStatus
                        self.selectedAudioData?.isFavorite = newFavoriteStatus
                        self.updateFavoriteButtonImage()
                        print("\(message ?? "Favorite status updated successfully")")
                    } else {
                        print("Failed to update favorite status: \(message ?? "Unknown error")")
                        self.currentAudioIsFavorite = !newFavoriteStatus
                        self.updateFavoriteButtonImage()
                    }
                }
            }
        }
        updateFavoriteButtonImage()
    }
    
    // MARK: - playPauseButtonTapped
    @IBAction func playPauseButtonTapped(_ sender: UIButton) {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                timer?.invalidate()
                playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            } else {
                startAudioPlayback()
            }
            isPlaying = player.isPlaying
        }
    }
    
    private func startAudioPlayback() {
        guard let player = audioPlayer else { return }
        
        if player.currentTime >= player.duration {
            player.currentTime = 0
            songProgress.value = 0
        }
        
        player.play()
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        setupTimer()
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
extension AudioVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == audioCustomCollectionView {
            return 1 + customAudios.count
        } else if collectionView == audioCharacterCollectionView {
            return isLoading ? 6 : viewModel.characters.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == audioCustomCollectionView {
            if indexPath.item == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AddAudioCollectionCell", for: indexPath) as! AddAudioCollectionCell
                cell.imageView.image = UIImage(named: "AddAudio")
                cell.addAudioLabel.text = "Add Audio"
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCustomCollectionCell", for: indexPath) as! AudioCustomCollectionCell
                let audioData = customAudios[indexPath.item - 1]
                cell.imageView.image = audioData.image ?? getRandomDefaultImage()
                return cell
            }
        } else if collectionView == audioCharacterCollectionView {
            if isLoading {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
                cell.isUserInteractionEnabled = false
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AudioCharacterCollectionCell", for: indexPath) as! AudioCharacterCollectionCell
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
        if collectionView == audioCustomCollectionView {
            if indexPath.item == 0 {
                showAudioOptionsActionSheet(sourceView: collectionView.cellForItem(at: indexPath)!)
            } else {
                if let previousCharacterCell = selectedAudioCharacterCell {
                    audioCharacterCollectionView.deselectItem(at: previousCharacterCell, animated: true)
                    selectedAudioCharacterCell = nil
                }
                
                selectedAudioCustomCell = indexPath
                let audioData = customAudios[indexPath.item - 1]
                selectedAudioIndex = indexPath.item - 1
                
                print("=== Audio Custom Collection Cell Clicked ===")
                print("Audio File URL:", audioData.url)
                print("=====================================")
                
                if let player = audioPlayer, player.isPlaying {
                    player.stop()
                    timer?.invalidate()
                }
                audioImageView.image = audioData.image
                setupAudioPlayer(with: audioData.url)
                audioPlayer?.play()
                isPlaying = true
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                updateFavoriteButtonImage()
                setupTimer()
                self.favouriteButton.isHidden = true
                self.playPauseButton.isHidden = false
                self.songMinit.isHidden = false
                self.songName.isHidden = false
                self.blureEffect.isHidden = false
                self.songProgress.isHidden = false
            }
        } else if collectionView == audioCharacterCollectionView {
            if let previousCustomCell = selectedAudioCustomCell {
                audioCustomCollectionView.deselectItem(at: previousCustomCell, animated: true)
                selectedAudioCustomCell = nil
            }
            
            selectedAudioCharacterCell = indexPath
            let character = viewModel.characters[indexPath.item]
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "AudioCharacterAllVC") as! AudioCharacterAllVC
            vc.characterId = character.characterID
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 155 : 115
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 165 : 125
        
        if collectionView == audioCustomCollectionView {
            if indexPath.item == 0 {
                return CGSize(width: width, height: height)
            }
            return CGSize(width: width, height: height)
        } else if collectionView == audioCharacterCollectionView {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    private func showAudioOptionsActionSheet(sourceView: UIView) {
        let titleString = NSAttributedString(string: "Select Audio", attributes: [
            NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)
        ])
        
        let alertController = UIAlertController(title: "", message: nil, preferredStyle: .actionSheet)
        alertController.setValue(titleString, forKey: "attributedTitle")
        
        let recorderAction = UIAlertAction(title: "Recorder", style: .default) { [weak self] _ in
            // Handle recorder action
        }
        
        let mediaPlayerAction = UIAlertAction(title: "Media player", style: .default) { [weak self] _ in
            self?.openMediaPicker()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alertController.addAction(recorderAction)
        alertController.addAction(mediaPlayerAction)
        alertController.addAction(cancelAction)
        
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sourceView
            popoverController.sourceRect = sourceView.bounds
        }
        
        present(alertController, animated: true)
    }
}

extension AudioVC {
    private func saveAudios() {
        let audioData = customAudios.map { audio -> CustomAudio in
            let fileName = audio.url.lastPathComponent
            let imageFileName = audio.image?.accessibilityIdentifier ?? defaultImages[0]
            return CustomAudio(fileName: fileName, imageFileName: imageFileName)
        }
        
        if let encoded = try? JSONEncoder().encode(audioData) {
            UserDefaults.standard.set(encoded, forKey: "is_UserSelectedAudios")
        }
    }
    
    private func loadSavedAudios() {
        guard let data = UserDefaults.standard.data(forKey: "is_UserSelectedAudios"),
              let savedAudios = try? JSONDecoder().decode([CustomAudio].self, from: data) else {
            return
        }
        
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        customAudios = savedAudios.compactMap { savedAudio in
            let audioUrl = documentsDirectory.appendingPathComponent(savedAudio.fileName)
            if FileManager.default.fileExists(atPath: audioUrl.path) {
                let image = UIImage(named: savedAudio.imageFileName)
                image?.accessibilityIdentifier = savedAudio.imageFileName
                return (url: audioUrl, image: image)
            } else {
                print("File not found: \(audioUrl.path)")
                return nil
            }
        }
        
        DispatchQueue.main.async {
            self.audioCustomCollectionView.reloadData()
        }
    }
    
    private func setupSlider() {
        songProgress.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
    }
    
    @objc private func sliderValueChanged(_ slider: UISlider) {
        audioPlayer?.currentTime = TimeInterval(slider.value)
        updateSongDuration()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func openMediaPicker() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.audio"], in: .import)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    private func setupAudioPlayer(with url: URL) {
        do {
            if let player = audioPlayer, player.isPlaying {
                player.stop()
            }
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            songName.text = url.lastPathComponent
            songProgress.maximumValue = Float(audioPlayer?.duration ?? 0)
            songProgress.value = 0
            audioPlayer?.play()
            isPlaying = true
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            
            updateSongDuration()
            setupTimer()
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }
    
    private func setupTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateSongProgress()
        }
    }
    
    private func updateSongProgress() {
        guard let player = audioPlayer else { return }
        songProgress.value = Float(player.currentTime)
        updateSongDuration()
    }
    
    private func updateSongDuration() {
        _ = Int(audioPlayer?.currentTime ?? 0)
        let duration = Int(audioPlayer?.duration ?? 0)
        songMinit.text = "\(timeString(from: duration))"
    }
    
    private func timeString(from timeInterval: Int) -> String {
        let minutes = timeInterval / 60
        let seconds = timeInterval % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func updateFavoriteButtonImage() {
        let imageName = currentAudioIsFavorite ? "Heart_Fill" : "Heart"
        favouriteButton.setImage(UIImage(named: imageName), for: .normal)
    }
    
    private func setupAudioPlayerFromURL(_ url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self,
                  let audioData = data,
                  error == nil else {
                DispatchQueue.main.async {
                    self?.hideLottieLoader()
                }
                print("Error downloading audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self.audioPlayer?.stop()
                    self.timer?.invalidate()
                    
                    self.audioPlayer = try AVAudioPlayer(data: audioData)
                    self.audioPlayer?.delegate = self
                    self.audioPlayer?.prepareToPlay()
                    
                    self.songProgress.maximumValue = Float(self.audioPlayer?.duration ?? 0)
                    self.songProgress.value = 0
                    self.updateSongDuration()
                    
                    self.audioPlayer?.play()
                    self.isPlaying = true
                    self.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    self.setupTimer()
                    
                    self.hideLottieLoader()
                } catch {
                    self.hideLottieLoader()
                    print("Error setting up audio player: \(error)")
                }
            }
        }.resume()
    }
    
    func playSelectedAudio(_ audioData: CharacterAllData) {
        print("=== Selected Audio from Preview ===")
        print("Audio Name:", audioData.name)
        print("Audio File:", audioData.file ?? "No File")
        print("Audio Image URL:", audioData.image)
        print("Audio Item ID:", audioData.itemID)
        print("Audio favourite:", audioData.isFavorite)
        print("Audio premium:", audioData.premium)
        print("=====================================")
        
        self.selectedAudioData = audioData
        
        showLottieLoader()
        if let url = URL(string: audioData.image) {
            audioImageView.sd_setImage(with: url, placeholderImage: UIImage(named: "placeholder")) { [weak self] _, _, _, _ in
                self?.hideLottieLoader()
                self?.playPauseButton.isHidden = false
                self?.songMinit.isHidden = false
                self?.songName.isHidden = false
                self?.blureEffect.isHidden = false
                self?.songProgress.isHidden = false
            }
        }
        songName.text = audioData.name
        currentAudioIsFavorite = audioData.isFavorite
        updateFavoriteButtonImage()
        if let audioUrl = URL(string: audioData.file!) {
            showLottieLoader()
            setupAudioPlayerFromURL(audioUrl)
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension AudioVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let selectedURL = urls.first else { return }
        
        self.showLottieLoader()
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let destinationURL = documentsDirectory.appendingPathComponent(selectedURL.lastPathComponent)
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: selectedURL, to: destinationURL)
                let randomImage = self.getRandomDefaultImage()
                
                self.customAudios.insert((url: destinationURL, image: randomImage), at: 0)
                
                DispatchQueue.main.async {
                    self.audioCustomCollectionView.reloadData()
                    self.hideLottieLoader()
                    self.favouriteButton.isHidden = true
                    self.playPauseButton.isHidden = false
                    self.songMinit.isHidden = false
                    self.songName.isHidden = false
                    self.blureEffect.isHidden = false
                    self.songProgress.isHidden = false
                    let indexPath = IndexPath(item: 1, section: 0)
                    self.audioCustomCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                    self.collectionView(self.audioCustomCollectionView, didSelectItemAt: indexPath)
                }
            } catch {
                print("Error copying file: \(error)")
                self.hideLottieLoader()
                self.favouriteButton.isHidden = true
            }
        }
    }
    
    //MARK: - getRandomDefaultImage
    private func getRandomDefaultImage() -> UIImage? {
        let randomIndex = Int.random(in: 0..<defaultImages.count)
        let imageName = defaultImages[randomIndex]
        
        let image = UIImage(named: imageName)
        image?.accessibilityIdentifier = imageName
        
        return image
    }
}

//MARK: - AVAudioPlayerDelegate
extension AudioVC: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
            self.playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            self.timer?.invalidate()
            self.songProgress.value = Float(player.duration)
            self.songProgress.value = 0
            self.updateSongDuration()
        }
    }
}
