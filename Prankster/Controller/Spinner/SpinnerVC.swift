//
//  SpinnerVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 02/12/24.
//

import UIKit
import SwiftFortuneWheel
import SDWebImage
import Alamofire
import StoreKit
import UserNotifications

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
    @IBOutlet weak var spinnerWidghConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerGeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerbuttonWidghConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerbuttonHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var collectionview: UICollectionView!
    @IBOutlet weak var spinerDesginHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinsecoundLabelHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var topHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerCountLabel: UILabel!
    @IBOutlet weak var bottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var showDataHeightConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var wheelControl: SwiftFortuneWheel! {
        didSet {
            let wheelSize = CGSize(width: 300, height: 300)
            wheelControl.configuration = .gradientColorsConfiguration(wheelSize: wheelSize)
            wheelControl.spinImage = "darkBlueCenterImage"
            wheelControl.isSpinEnabled = true
            wheelControl.impactFeedbackOn = true
            wheelControl.edgeCollisionDetectionOn = true
        }
    }
    
    let notificationMessages = [
        (title: "Spin the Wheel! 🎡", body: "Unlock Premium Pranks with every spin!"),
        (title: "Ready to Spin? 🎯", body: "Spin and grab your Premium Pranks now! ⏰"),
        (title: "Knock Knock! who's there?", body: "Your true friend Prankster!"),
        (title: "Spin & Get Rewarded! 🎁", body: "Win Premium Pranks every time you spin! 🔥"),
    ]
    
    // MARK: - Properties
    var prizes: [Spinner] = []
    var finalValue: String = ""
    private let spinKey = "remainingSpins"
    var spinnerResponseData: [SpinnerData] = []
    private var spinViewModel: SpinnerViewModel!
    private let timerKey = "nextSpinAvailableTime"
    private let rewardAdUtility = RewardAdUtility()
    private var adsViewModel: AdsViewModel!
    var bannerAdUtility = BannerAdUtility()
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
    
    init(adViewModule: AdsViewModel) {
        self.adsViewModel = adViewModule
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.adsViewModel = AdsViewModel(apiService: AdsAPIManger.shared)
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViewModel()
        self.setupInitialSpins()
        self.loadSavedSpinnerData()
        self.requestNotificationPermission()
        
        self.collectionview.delegate = self
        self.collectionview.dataSource = self
        
        prizes = [
            Spinner(image: "Audio1", value: "1"),
            Spinner(image: "ImageSpin", value: "3"),
            Spinner(image: "Gift", value: String(Int.random(in: 1...3))),
            Spinner(image: "VideoSpin", value: "2"),
        ]
        
        updateSlices()
        setupSwipeGesture()
        
        wheelControl.onSpinButtonTap = { [weak self] in
            guard let self = self, !self.isSpinning else { return }
            
            if self.isConnectedToInternet() {
                switch self.currentSpinButtonState {
                case .spin:
                    if self.remainingSpins > 0 {
                        self.proceedWithSpinning()
                    }
                case .watchAd:
                    self.rewardAdUtility.showRewardedAd()
                case .waitingForReset:
                    self.showTimeCountBottomSheet()
                }
            } else {
                let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                snackbar.show(in: self.view, duration: 3.0)
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            bottomConstraints.constant = 100
        } else {
            bottomConstraints.constant = 75
        }
        
        if isConnectedToInternet() {
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                bottomConstraints.constant = 16
            } else {
                if let bannerAdID = adsViewModel.getAdID(type: .banner) {
                    print("Banner Ad ID: \(bannerAdID)")
                    bannerAdUtility.setupBannerAd(in: self, adUnitID: bannerAdID)
                } else {
                    print("No Banner Ad ID found")
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        bottomConstraints.constant = 16
                    } else {
                        bottomConstraints.constant = 16
                    }
                }
                
                if let rewardAdID = adsViewModel.getAdID(type: .reward) {
                    print("Reward Ad ID: \(rewardAdID)")
                    rewardAdUtility.loadRewardedAd(adUnitID: rewardAdID, rootViewController: self)
                } else {
                    print("No Reward Ad ID found")
                }
                
            }
        }
        
        let wheelSize = CGSize(width: 300, height: 300)
        wheelControl.configuration = .gradientColorsConfiguration(wheelSize: wheelSize)
        updateSpinLabel()
        startTimerLabelUpdate()
        rewardAdUtility.onRewardEarned = { [weak self] in
            self?.proceedWithSpinning()
        }
        updateTimerLabel()
        
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            spinnerCountLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            spinnerbuttonWidghConstraints.constant = 230
            spinnerbuttonHeightConstraints.constant = 110
            spinsecoundLabelHeightConstraints.constant = 40
            spinerDesginHeightConstraints.constant = -40
            showDataHeightConstraints.constant = 130
            switch screenHeight {
            case 1334:
                topHeightConstraints.constant = 25
                spinnerWidghConstraints.constant = 280
                spinnerGeightConstraints.constant = 280
            case 1920, 1792:
                topHeightConstraints.constant = 50
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2340:
                topHeightConstraints.constant = 50
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2532, 2556:
                topHeightConstraints.constant = 50
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2622:
                topHeightConstraints.constant = 70
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2688:
                topHeightConstraints.constant = 70
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2796:
                topHeightConstraints.constant = 70
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2869:
                topHeightConstraints.constant = 70
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            default:
                topHeightConstraints.constant = 40
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            }
        } else {
            spinnerCountLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            topHeightConstraints.constant = 160
            spinsecoundLabelHeightConstraints.constant = 60
            spinerDesginHeightConstraints.constant = -50
            spinnerGeightConstraints.constant = 400
            spinnerWidghConstraints.constant = 400
            spinnerbuttonWidghConstraints.constant = 300
            spinnerbuttonHeightConstraints.constant = 150
            showDataHeightConstraints.constant = 160
        }
    }
    
    private func showTimeCountBottomSheet() {
        guard let nextSpinTime = nextSpinAvailableTime else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let timeCountVC = storyboard.instantiateViewController(withIdentifier: "TimeCountVC") as? TimeCountVC else {
            return
        }
        
        timeCountVC.modalPresentationStyle = .custom
        timeCountVC.transitioningDelegate = self
        timeCountVC.nextSpinTime = nextSpinTime
        
        // Initial update of labels
        present(timeCountVC, animated: true) { [weak timeCountVC] in
            timeCountVC?.updateTimeLabels()
        }
    }
    
    // MARK: - Setup Methods
    private func setupViewModel() {
        spinViewModel = SpinnerViewModel()
        
        spinViewModel.onDataUpdate = { [weak self] response in
            guard let response = response else { return }
            DispatchQueue.main.async {
                self?.updateSpinnerData(with: response.data)
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerDataShowVC") as! SpinnerDataShowVC
                vc.coverImageURL = response.data.coverImage
                vc.prankName = response.data.name
                vc.prankDataURL = response.data.file
                vc.prankLink = response.data.link
                vc.prankShareURL = response.data.shareURL
                vc.prankType = response.data.type
                vc.prankImage = response.data.image
                vc.sharePrank = true
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                self?.present(vc, animated: true)
            }
        }
        
        spinViewModel.onError = { error in
            print("Error :- \(error)")
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
            }
        }
    }
    
    // MARK: - Spinner Data Management
    func updateSpinnerData(with response: SpinnerData) {
        spinnerResponseData.insert(response, at: 0)
        saveSpinnerData()
        collectionview.reloadData()
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
        
        prizes[2].value = String(Int.random(in: 1...3))
        
        let finalIdx = finishIndex
        wheelControl.startRotationAnimation(finishIndex: finalIdx, continuousRotationTime: 1) { [weak self] finished in
            if finished {
                self?.finalValue = self?.prizes[finalIdx].value ?? ""
                self?.isSpinning = false
                
                if let finalValue = self?.finalValue {
                    if self?.isConnectedToInternet() == true {
                        self?.spinViewModel.postSpinData(typeId: finalValue)
                    } else {
                        let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
                        snackbar.show(in: self?.view ?? UIView(), duration: 3.0)
                    }
                    self?.updateSpinLabel()
                    
                    // બીજો સ્પિન પૂરો થયા પછી રેટ અસ બતાવવા માટે
                    if self?.remainingSpins == 2 {
                        self?.rateUs()
                    }
                }
            }
        }
    }
    
    private func checkNotificationPermissionAndSchedule() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                self.scheduleSpinnerNotification()
            case .denied, .notDetermined, .provisional, .ephemeral:
                print("Notifications are not allowed by the user")
            @unknown default:
                print("Unknown notification authorization status")
            }
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    private func scheduleSpinnerNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        let randomMessage = notificationMessages.randomElement()!
        content.title = NSLocalizedString(randomMessage.title, comment: "")
        content.body = NSLocalizedString(randomMessage.body, comment: "")
        content.sound = UNNotificationSound.default
        
        // Original: 4 hours = 4 * 60 * 60
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: false)
        
        // Testing: 2 minutes = 2 * 60
        //  let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2 * 60, repeats: false)
        
        let request = UNNotificationRequest(identifier: "spinnerReset", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for spinnerReset.")
            }
        }
    }
    
    // MARK: - Timer Methods
    func startTimerForNextSpins() {
        // Original: 4 hours = 4 * 60 * 60
        nextSpinAvailableTime = Date().addingTimeInterval(4 * 60 * 60)
        
        // Testing: 2 minutes = 2 * 60
        // nextSpinAvailableTime = Date().addingTimeInterval(2 * 60)
        checkNotificationPermissionAndSchedule()
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
        
        if remainingSpins > 0 {
            if remainingSpins == 4 {
                currentSpinButtonState = .spin
            } else {
                currentSpinButtonState = .watchAd
            }
        }
    }
    
    func updateTimerLabel() {
        guard let nextSpinTime = nextSpinAvailableTime else {
            return
        }
        
        let remainingTime = nextSpinTime.timeIntervalSinceNow
        if remainingTime <= 0 {
            UserDefaults.standard.removeObject(forKey: "savedSpinnerData")
            spinnerResponseData.removeAll()
            collectionview.reloadData()
            
            remainingSpins = 4
            currentSpinButtonState = .spin
            nextSpinAvailableTime = nil
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            remainingSpins = 0
            currentSpinButtonState = .waitingForReset
            
            let hours = Int(remainingTime) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            spinnerCountLabel.text = String(format: "%02dh:%02dm left", hours, minutes)
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        guard !isSpinning else { return }
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setupSwipeGesture() {
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.edges = .left
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard !isSpinning else { return }
        if gesture.state == .recognized {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func rateUs() {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            DispatchQueue.main.async {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            print(" - - - - - - Rating view in not present - - - -")
        }
    }
}

extension SpinnerVC: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let customPresentationController = CustomePresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        customPresentationController.heightPercentage = 0.3
        return customPresentationController
    }
}

// MARK: - UICollectionView Delegate & DataSource
extension SpinnerVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionView Delegate & DataSource Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return spinnerResponseData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SpinnerCollectionViewCell", for: indexPath) as! SpinnerCollectionViewCell
        let spinData = spinnerResponseData[indexPath.item]
        
        cell.configure(with: spinData) { [weak self] selectedSpinData in
            guard let self = self, let spinData = selectedSpinData else { return }
            
            let isContentUnlocked = PremiumManager.shared.isContentUnlocked(itemID: -1)
            let hasInternet = isConnectedToInternet()
            let shouldOpenDirectly = (isContentUnlocked || adsViewModel.getAdID(type: .reward) == nil || !hasInternet)
            
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerDataShowVC") as! SpinnerDataShowVC
                vc.coverImageURL = spinData.coverImage
                vc.prankName = spinData.name
                vc.prankDataURL = spinData.file
                vc.prankLink = spinData.link
                vc.prankShareURL = spinData.shareURL
                vc.prankType = spinData.type
                vc.prankImage = spinData.image
                vc.sharePrank = false
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                
                self.present(vc, animated: true)
            } else {
                rewardAdUtility.showRewardedAd()
                rewardAdUtility.onRewardEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerDataShowVC") as! SpinnerDataShowVC
                    vc.coverImageURL = spinData.coverImage
                    vc.prankName = spinData.name
                    vc.prankDataURL = spinData.file
                    vc.prankLink = spinData.link
                    vc.prankShareURL = spinData.shareURL
                    vc.prankType = spinData.type
                    vc.prankImage = spinData.image
                    vc.sharePrank = false
                    vc.modalTransitionStyle = .crossDissolve
                    vc.modalPresentationStyle = .overCurrentContext
                    
                    self?.present(vc, animated: true)
                }
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize: CGSize = UIDevice.current.userInterfaceIdiom == .pad
        ? CGSize(width: 145, height: 160)
        : CGSize(width: 115, height: 128)
        
        return cellSize
    }
}
