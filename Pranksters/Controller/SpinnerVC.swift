//
//  SpinnerVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 30/11/24.
//

import UIKit
import SwiftFortuneWheel
import SDWebImage

// MARK: - Spinner Struct
struct Spinner {
    var image: String
    var value: String
}

// MARK: - Spin Button State Enum
enum SpinButtonState {
    case spin
    case watchAd
    case waitingForReset
}

class SpinnerVC: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var spinnerDataCollectionView: UICollectionView!
    @IBOutlet weak var bannerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var spinnerHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerWidthConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var spinnerCountLabel: UILabel!
    @IBOutlet weak var spinLabel: UILabel!
    @IBOutlet weak var spinnerbutton: UIButton!
    @IBOutlet weak var wheelControl: SwiftFortuneWheel! {
        didSet {
            wheelControl.configuration = .customColorsConfiguration
            wheelControl.spinImage = "darkBlueCenterImage"
            wheelControl.isSpinEnabled = false
            wheelControl.impactFeedbackOn = true
            wheelControl.edgeCollisionDetectionOn = true
        }
    }
    
    // MARK: - Properties
    private var spinViewModel: SpinnerViewModel!
    var prizes: [Spinner] = []
    var finalValue: String = ""
    var spinnerResponseData: [SpinnerData] = []
    private let rewardAdUtility = RewardAdUtility()
    
    private let spinKey = "remainingSpins"
    private let timerKey = "nextSpinAvailableTime"
    
    private var currentSpinButtonState: SpinButtonState = .spin
    
    var remainingSpins: Int {
        get {
            return UserDefaults.standard.integer(forKey: spinKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: spinKey)
            updateSpinLabel()
        }
    }
    
    var nextSpinAvailableTime: Date? {
        get {
            guard let timeInterval = UserDefaults.standard.object(forKey: timerKey) as? TimeInterval else {
                return nil
            }
            return Date(timeIntervalSince1970: timeInterval)
        }
        set {
            let timeInterval = newValue?.timeIntervalSince1970
            UserDefaults.standard.set(timeInterval, forKey: timerKey)
            updateTimerLabel()
        }
    }
    
    private var isSpinning = false
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        setupInitialSpins()
        loadSavedSpinnerData()
        
        prizes = [
            Spinner(image: "Audio1", value: "1"),
            Spinner(image: "NextLuck1", value: "4"),
            Spinner(image: "ImageSpin", value: "3"),
            Spinner(image: "Audio2", value: "1"),
            Spinner(image: "NextLuck2", value: "4"),
            Spinner(image: "VideoSpin", value: "2")
        ]
        
        updateSlices()
        wheelControl.configuration = .customColorsConfiguration
        updateSpinLabel()
        startTimerLabelUpdate()
        spinnerDataCollectionView.delegate = self
        spinnerDataCollectionView.dataSource = self
        // Configure reward ad utility
        rewardAdUtility.loadRewardedAd(adUnitID: "ca-app-pub-3940256099942544/1712485313", rootViewController: self)
        rewardAdUtility.onRewardEarned = { [weak self] in
            self?.proceedWithSpinning()
        }
    }
    
    // MARK: - Setup Methods
    private func setupViewModel() {
        spinViewModel = SpinnerViewModel()
        
        spinViewModel.onDataUpdate = { [weak self] response in
            guard let response = response else { return }
            DispatchQueue.main.async {
                self?.updateCollectionViewData(with: response.data)
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerPreviewVC") as! SpinnerPreviewVC
                vc.coverImage = response.data.coverImage
                vc.name = response.data.name
                vc.file = response.data.file
                vc.link = response.data.link
                vc.type = response.data.type
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                self?.present(vc, animated: true)
            }
        }
        
        spinViewModel.onError = { error in
            DispatchQueue.main.async {
                print("Error")
            }
        }
    }
    
    // MARK: - Data Persistence Methods
    func saveSpinnerData() {
        let encoder = JSONEncoder()
        if let encodedData = try? encoder.encode(spinnerResponseData) {
            UserDefaults.standard.set(encodedData, forKey: "savedSpinnerData")
        }
    }
    
    func loadSavedSpinnerData() {
        if let savedData = UserDefaults.standard.data(forKey: "savedSpinnerData") {
            let decoder = JSONDecoder()
            if let decodedData = try? decoder.decode([SpinnerData].self, from: savedData) {
                spinnerResponseData = decodedData
                spinnerDataCollectionView.reloadData()
            }
        }
    }
    
    // MARK: - Collection View Data Management
    func updateCollectionViewData(with response: SpinnerData) {
        spinnerResponseData.append(response)
        spinnerDataCollectionView.reloadData()
        saveSpinnerData()
    }
    
    // MARK: - Wheel Methods
    var finishIndex: Int {
        return Int.random(in: 0..<wheelControl.slices.count)
    }
    
    func updateSlices() {
        let slices: [Slice] = prizes.map({
            Slice(contents: [
                Slice.ContentType.assetImage(name: $0.image, preferences: .prizeImagePreferences)
            ])
        })
        
        wheelControl.slices = slices
    }
    
    func setupInitialSpins() {
        if remainingSpins == 0 {
            remainingSpins = 4
        }
    }
    
    // MARK: - Spin Processing Methods
    private func proceedWithSpinning() {
        guard remainingSpins > 0 else { return }
        
        isSpinning = true
        remainingSpins -= 1
        
        if remainingSpins == 0 {
            startTimerForNextSpins()
        }
        
        let finalIdx = finishIndex
        wheelControl.startRotationAnimation(finishIndex: finalIdx, continuousRotationTime: 1) { [weak self] finished in
            if finished {
                self?.finalValue = self?.prizes[finalIdx].value ?? ""
                self?.isSpinning = false
                
                if let finalValue = self?.finalValue {
                    self?.spinViewModel.postSpinData(typeId: finalValue)
                    
                    // Ensure the next button state is set correctly
                    self?.updateSpinLabel()
                }
            }
        }
    }
    
    private func updateSpinButtonState() {
        switch currentSpinButtonState {
        case .spin:
            spinLabel.text = "Spin"
            spinLabel.font = UIFont(name: "Avenir Heavy", size: 24)
            spinnerbutton.isEnabled = true
        case .watchAd:
            spinLabel.text = "🎥 Watch Ad"
            spinLabel.font = UIFont(name: "Avenir Heavy", size: 24)
            spinnerbutton.isEnabled = true
        case .waitingForReset:
            spinnerbutton.isEnabled = true
        }
    }
    
    // MARK: - Timer Methods
    func startTimerForNextSpins() {
        nextSpinAvailableTime = Date().addingTimeInterval(4 * 3600)
    }
    
    func startTimerLabelUpdate() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateTimerLabel()
        }
    }
    
    // MARK: - UI Update Methods
    func updateSpinLabel() {
        let remainingSpinsText = "\(remainingSpins) spins left."
        spinnerCountLabel.text = remainingSpinsText
        
        // New logic for spin and ad
        if remainingSpins > 0 {
            if remainingSpins == 4 {
                currentSpinButtonState = .spin
            } else {
                currentSpinButtonState = .watchAd
            }
            updateSpinButtonState()
        }
    }
    
    func updateTimerLabel() {
        guard let nextSpinTime = nextSpinAvailableTime else {
            return
        }
        
        let remainingTime = nextSpinTime.timeIntervalSinceNow
        if remainingTime <= 0 {
            remainingSpins = 4
            currentSpinButtonState = .spin
            updateSpinButtonState()
            spinLabel.text = "Spin"
            spinLabel.font = UIFont(name: "Avenir Heavy", size: 24)
            
            UserDefaults.standard.removeObject(forKey: "savedSpinnerData")
            
            spinnerResponseData.removeAll()
            spinnerDataCollectionView.reloadData()
        } else {
            remainingSpins = 0
            currentSpinButtonState = .waitingForReset
            let hours = Int(remainingTime) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            spinLabel.text = String(format: "Reset in \n%02dh:%02dm", hours, minutes)
            spinLabel.font = UIFont(name: "Avenir Heavy", size: 20)
            
            updateSpinButtonState()
        }
    }
    
    // MARK: - IBActions
    @IBAction func btnSpinnerTapped(_ sender: UIButton) {
        guard !isSpinning else { return }
        
        switch currentSpinButtonState {
        case .spin:
            if remainingSpins > 0 {
                proceedWithSpinning()
            }
        case .watchAd:
            rewardAdUtility.showRewardedAd()
        case .waitingForReset:
            break
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension SpinnerVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return spinnerResponseData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpinnerCollectionViewCell", for: indexPath) as! SpinnerCollectionViewCell
        
        let spinData = spinnerResponseData[indexPath.item]
        
        cell.configure(with: spinData) { [weak self] selectedSpinData in
            guard let self = self, let spinData = selectedSpinData else { return }
            
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerPreviewVC") as! SpinnerPreviewVC
            vc.coverImage = spinData.coverImage
            vc.name = spinData.name
            vc.file = spinData.file
            vc.link = spinData.link
            vc.type = spinData.type
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: true)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width - 32
        let height: CGFloat = 55
        
        return CGSize(width: width, height: height)
    }
}
