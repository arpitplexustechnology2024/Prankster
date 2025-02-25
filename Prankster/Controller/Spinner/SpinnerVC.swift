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
    
    @IBOutlet weak var topHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var bannerHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerWidghConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerGeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerbuttonWidghConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerbuttonHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinTextHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var rewardWidthConstraits: NSLayoutConstraint!
    
    @IBOutlet weak var rewardShowButton: UIButton!
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
  //  private let adsViewModel = AdsViewModel()
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
        self.setupViewModel()
        self.setupInitialSpins()
        self.loadSavedSpinnerData()
        self.requestNotificationPermission()
        
        prizes = [
            Spinner(image: "Audio1", value: "1"),
            Spinner(image: "NextLuck1", value: "4"),
            Spinner(image: "ImageSpin", value: "3"),
            Spinner(image: "Audio2", value: "1"),
            Spinner(image: "NextLuck2", value: "4"),
            Spinner(image: "VideoSpin", value: "2")
        ]
        
        updateSlices()
        setupSwipeGesture()
        wheelControl.configuration = .customColorsConfiguration
        updateSpinLabel()
        startTimerLabelUpdate()
        if isConnectedToInternet() {
//            if let rewardAdID = adsViewModel.getAdID(type: .reward) {
//                print("Reward Ad ID: \(rewardAdID)")
                rewardAdUtility.loadRewardedAd(adUnitID: "ca-app-pub-7719542074975419/4831306268", rootViewController: self)
//            } else {
//                print("No Reward Ad ID found")
//            }
        }
        rewardAdUtility.onRewardEarned = { [weak self] in
            self?.proceedWithSpinning()
        }
        updateTimerLabel()
        
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            spinnerbuttonWidghConstraints.constant = 230
            spinnerbuttonHeightConstraints.constant = 110
            bannerHeightConstraints.constant = 90
            spinTextHeightConstraints.constant = 56
            switch screenHeight {
            case 1334:
                topHeightConstraints.constant = 10
                spinnerWidghConstraints.constant = 275
                spinnerGeightConstraints.constant = 275
            case 1920, 1792:
                topHeightConstraints.constant = 30
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2340:
                topHeightConstraints.constant = 40
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2532, 2556:
                topHeightConstraints.constant = 50
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2622:
                topHeightConstraints.constant = 66
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2688:
                topHeightConstraints.constant = 75
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2796:
                topHeightConstraints.constant = 90
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            case 2869:
                topHeightConstraints.constant = 100
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            default:
                topHeightConstraints.constant = 60
                spinnerWidghConstraints.constant = 300
                spinnerGeightConstraints.constant = 300
            }
        } else {
            spinLabel.font = UIFont(name: "Avenir-Heavy", size: 34)
            spinTextHeightConstraints.constant = 80
            topHeightConstraints.constant = 150
            bannerHeightConstraints.constant = 150
            spinnerGeightConstraints.constant = 400
            spinnerWidghConstraints.constant = 400
            spinnerbuttonWidghConstraints.constant = 330
            spinnerbuttonHeightConstraints.constant = 150
        }
    }
    
    // MARK: - Setup Methods
    private func setupViewModel() {
        spinViewModel = SpinnerViewModel()
        
        spinViewModel.onDataUpdate = { [weak self] response in
            guard let response = response else { return }
            DispatchQueue.main.async {
                self?.rewardShowButton.isEnabled = true
                self?.updateSpinnerData(with: response.data)
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SpinnerPreviewVC") as! SpinnerPreviewVC
                vc.coverImage = response.data.coverImage
                vc.name = response.data.name
                vc.file = response.data.file
                vc.link = response.data.shareURL
                vc.type = response.data.type
                vc.image = response.data.image
                vc.modalTransitionStyle = .crossDissolve
                vc.modalPresentationStyle = .overCurrentContext
                self?.present(vc, animated: true)
            }
        }
        
        spinViewModel.onError = { error in
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "BetterLuckVC") as! BetterLuckVC
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            self.present(vc, animated: true)
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
                rewardShowButton.isEnabled = !spinnerResponseData.isEmpty
            }
        } else {
            rewardShowButton.isEnabled = false
        }
    }
    
    // MARK: - Spinner Data Management
    func updateSpinnerData(with response: SpinnerData) {
        spinnerResponseData.insert(response, at: 0)
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
        
        if remainingSpins == 2 {
            self.rateUs()
        }
        
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
                }
            }
        }
    }
    
    private func updateSpinButtonState() {
        switch currentSpinButtonState {
        case .spin:
            spinLabel.text = "Spin"
            spinLabel.font = UIFont(name: "Avenir-Heavy", size: 24)
            spinnerbutton.isEnabled = remainingSpins > 0
        case .watchAd:
            spinLabel.text = "🎥 Watch"
            spinLabel.font = UIFont(name: "Avenir-Heavy", size: 24)
            spinnerbutton.isEnabled = true
        case .waitingForReset:
            spinnerbutton.isEnabled = true
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
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 4 * 60 * 60, repeats: false)
        
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
        nextSpinAvailableTime = Date().addingTimeInterval(4 * 60 * 60)
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
            spinLabel.font = UIFont(name: "Avenir-Heavy", size: 24)
            UserDefaults.standard.removeObject(forKey: "savedSpinnerData")
            spinnerResponseData.removeAll()
            nextSpinAvailableTime = nil
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            remainingSpins = 0
            currentSpinButtonState = .waitingForReset
            
            let hours = Int(remainingTime) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            spinLabel.text = String(format: "New spin \n%02dh:%02dm", hours, minutes)
            spinLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            
            updateSpinButtonState()
        }
    }
    
    // MARK: - IBActions
    @IBAction func btnSpinnerTapped(_ sender: UIButton) {
        guard !isSpinning else { return }
        
        if isConnectedToInternet() {
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
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
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
    
    @IBAction func btnShowReward(_ sender: UIButton) {
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SpinnerDataVC") as! SpinnerDataVC
        vc.spinnerResponseData = self.spinnerResponseData
        vc.modalPresentationStyle = .custom
        vc.transitioningDelegate = self
        self.present(vc, animated: true)
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
        customPresentationController.heightPercentage = 0.4
        return customPresentationController
    }
}
