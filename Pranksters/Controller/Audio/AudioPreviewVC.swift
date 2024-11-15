//
//  AudioPreviewVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 18/10/24.
//


import UIKit
import Shuffle_iOS
import AVFoundation

class AudioPreviewVC: UIViewController, SwipeCardStackDataSource, SwipeCardStackDelegate, AVAudioPlayerDelegate {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var allSwipedImageView: UIImageView!
    
    private let cardStack = SwipeCardStack()
    var audioData: [CharacterAllData] = []
    var initialIndex: Int = 0
    private var currentCardIndex: Int = 0
    private var visibleCards: [AudioCardPreview] = []
    private let favoriteViewModel = FavoriteViewModel()
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        rearrangeAudioData()
        setupCardStack()
        setupBlurEffect()
        setupAudioSession()
        allSwipedImageView.isHidden = true
        allSwipedImageView.alpha = 0
        self.selectButton.layer.cornerRadius = 13
    }
    
    private func rearrangeAudioData() {
        var rearrangedData: [CharacterAllData] = []
        rearrangedData.append(contentsOf: audioData[initialIndex...])
        if initialIndex > 0 {
            rearrangedData.append(contentsOf: audioData[..<initialIndex])
        }
        audioData = rearrangedData
        currentCardIndex = 0
    }
    
    private func setupCardStack() {
        cardStack.dataSource = self
        cardStack.delegate = self
        
        containerView.addSubview(cardStack)
        cardStack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cardStack.widthAnchor.constraint(equalTo: containerView.widthAnchor),
            cardStack.heightAnchor.constraint(equalTo: containerView.heightAnchor),
            cardStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            cardStack.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    private func setupBlurEffect() {
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(blurEffectView, at: 0)
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Audio Control Methods
    func setupAudioPlayer(for audioFile: String) {
        guard let url = URL(string: audioFile) else { return }
        
        stopAndResetAudio()
        
        URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let data = data, error == nil else {
                print("Failed to download audio: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            DispatchQueue.main.async {
                do {
                    self?.audioPlayer = try AVAudioPlayer(data: data)
                    self?.audioPlayer?.delegate = self
                    self?.audioPlayer?.prepareToPlay()
                    
                    // Make sure to update UI for the current visible card
                    if let currentCard = self?.visibleCards.first {
                        self?.updateDurationLabel(currentCard)
                        currentCard.updateSliderValue(0)
                        currentCard.updatePlayButtonImage(isPlaying: false)
                    }
                } catch {
                    print("Failed to initialize audio player: \(error)")
                }
            }
        }.resume()
    }
    
    private func updateDurationLabel(_ card: AudioCardPreview) {
        guard let duration = audioPlayer?.duration else { return }
        card.updateDurationLabel(text: timeString(from: Int(duration)))
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.isPlaying = false
                self.stopTimer()
                
                if let currentCard = self.visibleCards.first {
                    currentCard.updatePlayButtonImage(isPlaying: false)
                    currentCard.updateSliderValue(0)
                    if let duration = self.audioPlayer?.duration {
                        currentCard.updateDurationLabel(text: self.timeString(from: Int(duration)))
                    }
                }
            }
        }
    }
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  let player = self.audioPlayer,
                  let currentCard = self.visibleCards.first else {
                self?.stopTimer()
                return
            }
            
            let progress = Float(player.currentTime / player.duration)
            currentCard.updateSliderValue(progress)
            currentCard.updateDurationLabel(text: self.timeString(from: Int(player.currentTime)))
        }
    }
    
    private func timeString(from timeInterval: Int) -> String {
        let minutes = timeInterval / 60
        let seconds = timeInterval % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func playPauseAudio(_ card: AudioCardPreview) {
        if isPlaying {
            audioPlayer?.pause()
            card.updatePlayButtonImage(isPlaying: false)
            stopTimer()
        } else {
            audioPlayer?.play()
            card.updatePlayButtonImage(isPlaying: true)
            startTimer()
        }
        isPlaying = !isPlaying
    }
    
    func seekAudio(to value: Float) {
        guard let player = audioPlayer else { return }
        let time = Double(value) * player.duration
        player.currentTime = time
        
        if let currentCard = visibleCards.first {
            if !isPlaying {
                currentCard.updateDurationLabel(text: timeString(from: Int(time)))
            }
        }
    }
    
    // MARK: - SwipeCardStackDataSource
    func numberOfCards(in cardStack: SwipeCardStack) -> Int {
        return audioData.count
    }
    
    func cardStack(_ cardStack: SwipeCardStack, cardForIndexAt index: Int) -> SwipeCard {
        let card = AudioCardPreview()
        let audioPageData = audioData[index]
        
        let cardModel = AudioCardModel(file: audioPageData.file!,
                                       name: audioPageData.name,
                                       image: audioPageData.image,
                                       isFavorited: audioPageData.isFavorite,
                                       itemId: audioPageData.itemID,
                                       categoryId: 1,
                                       Premium: audioPageData.premium)
        card.configure(withModel: cardModel)
        
        if index == currentCardIndex {
            visibleCards.removeAll()
        }
        
        visibleCards.append(card)
        
        if index == currentCardIndex {
            setupAudioPlayer(for: audioPageData.file!)
        }
        
        card.onPlayButtonTapped = { [weak self] in
            self?.playPauseAudio(card)
        }
        
        card.onSliderValueChanged = { [weak self] value in
            self?.seekAudio(to: value)
        }
        
        card.swipeDirections = [.left, .right]
        
        card.onFavoriteButtonTapped = { [weak self] itemId, isFavorite, categoryId in
            self?.handleFavoriteButtonTapped(itemId: itemId, isFavorite: isFavorite, categoryId: categoryId)
        }
        
        return card
    }
    
    // MARK: - SwipeCardStackDelegate
    func didSwipeAllCards(_ cardStack: SwipeCardStack) {
        stopAndResetAudio()
        print("All cards swiped")
        allSwipedImageView.isHidden = false
        selectButton.isHidden = true
        
        UIView.animate(withDuration: 0.5, animations: {
            self.allSwipedImageView.alpha = 1.0
            self.selectButton.alpha = 0
        }) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.5, animations: {
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }
    }
    
    func cardStack(_ cardStack: SwipeCardStack, didSwipeCardAt index: Int, with direction: SwipeDirection) {
        stopAndResetAudio()
        
        if !visibleCards.isEmpty {
            visibleCards.removeFirst()
        }
        
        currentCardIndex = index + 1
        updateSelectButtonState()
        
        if currentCardIndex < audioData.count {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.setupAudioPlayer(for: self?.audioData[self?.currentCardIndex ?? 0].file ?? "")
            }
        }
    }
    
    private func stopAndResetAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        stopTimer()
        
        if let currentCard = visibleCards.first {
            currentCard.updatePlayButtonImage(isPlaying: false)
            currentCard.updateSliderValue(0)
            currentCard.updateDurationLabel(text: "00:00")
        }
    }
    
    private func updateSelectButtonState() {
        selectButton.isEnabled = currentCardIndex < audioData.count
    }
    
    private func handleFavoriteButtonTapped(itemId: Int, isFavorite: Bool, categoryId: Int) {
        favoriteViewModel.setFavorite(itemId: itemId, isFavorite: isFavorite, categoryId: categoryId) { [weak self] success, message in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if success {
                    if let index = self.audioData.firstIndex(where: { $0.itemID == itemId }) {
                        self.audioData[index].isFavorite = isFavorite
                        
                        if let visibleCard = self.visibleCards.first(where: { $0.model?.itemId == itemId }) {
                            let updatedModel = AudioCardModel(
                                file: self.audioData[index].file!,
                                name: self.audioData[index].name,
                                image: self.audioData[index].image,
                                isFavorited: isFavorite,
                                itemId: itemId,
                                categoryId: categoryId,
                                Premium: self.audioData[index].premium
                            )
                            visibleCard.configure(withModel: updatedModel)
                        }
                    }
                    print(message ?? "Favorite status updated successfully")
                } else {
                    print("Failed to update favorite status: \(message ?? "Unknown error")")
                    self.revertFavoriteStatus(for: itemId)
                }
            }
        }
    }
    
    private func revertFavoriteStatus(for itemId: Int) {
        if let index = audioData.firstIndex(where: { $0.itemID == itemId }) {
            let currentStatus = audioData[index].isFavorite
            audioData[index].isFavorite = !currentStatus
            
            if let cardToUpdate = visibleCards.first(where: { $0.model?.itemId == itemId }) {
                let updatedModel = AudioCardModel(
                    file: audioData[index].file!,
                    name: audioData[index].name,
                    image: audioData[index].image,
                    isFavorited: !currentStatus,
                    itemId: itemId,
                    categoryId: 1,
                    Premium: audioData[index].premium
                )
                cardToUpdate.configure(withModel: updatedModel)
            }
        }
    }
    
    @IBAction func btnSelectTapped(_ sender: UIButton) {
        guard currentCardIndex < audioData.count else { return }
        let selectedAudio = audioData[currentCardIndex]
        
        if selectedAudio.premium {
            presentPremiumViewController()
        } else {
            audioPlayer?.stop()
            timer?.invalidate()
            
            if let navigationController = self.presentingViewController as? UINavigationController {
                self.dismiss(animated: false) {
                    if let audioVC = navigationController.viewControllers.first(where: { $0 is AudioVC }) as? AudioVC {
                        navigationController.popToViewController(audioVC, animated: true)
                        audioVC.playSelectedAudio(selectedAudio)
                    } else {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        if let audioVC = storyboard.instantiateViewController(withIdentifier: "AudioVC") as? AudioVC {
                            audioVC.initialAudioData = selectedAudio
                            navigationController.pushViewController(audioVC, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    private func presentPremiumViewController() {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumVC") as! PremiumVC
        present(premiumVC, animated: true, completion: nil)
    }
    
    deinit {
        stopAndResetAudio()
    }
}
