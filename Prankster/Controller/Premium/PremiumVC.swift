//
//  PremiumVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 07/02/25.
//

import UIKit
import StoreKit
import SafariServices
import Alamofire

class PremiumVC: UIViewController, SKPaymentTransactionObserver, SKProductsRequestDelegate, UITextViewDelegate {
    
    @IBOutlet weak var pranksterImageHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    @IBOutlet weak var sliderView: UIView!
    private var collectionView: UICollectionView!
    private let images = ["Premium01", "Premium02", "Premium03", "Premium04"]
    private let imagesIcon = ["PremiumIcon01", "PremiumIcon02", "PremiumIcon03", "PremiumIcon04"]
    private let features = ["Access premium Prank Images, Audio & Videos", "Get ads-free", "Get ready \n funny pranks", "Unlimited spins"]
    private var itemSize: CGSize {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return CGSize(width: 160, height: 100)
        } else {
            return CGSize(width: 180, height: 115)
        }
    }
    
    private var displayLink: CADisplayLink?
    private var scrollSpeed: CGFloat = 0.8
    
    var premiumBack: Bool = false
    
    @IBOutlet weak var scrollViewHeightConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var sliderHeightConstarints: NSLayoutConstraint!
    
    @IBOutlet var doneImageConstraints: [NSLayoutConstraint]!
    @IBOutlet var labelLeftConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var bestOfferLabel: UILabel!
    @IBOutlet weak var weeklyLabel: UILabel!
    @IBOutlet weak var weeklyPriceLabel: UILabel!
    @IBOutlet weak var topRatedLabel: UILabel!
    @IBOutlet weak var monthlyLabel: UILabel!
    @IBOutlet weak var monthlyPriceLabel: UILabel!
    @IBOutlet weak var populareLabel: UILabel!
    @IBOutlet weak var yearlyLabel: UILabel!
    @IBOutlet weak var yearlyPriceLabel: UILabel!
    
    @IBOutlet weak var doneImage01: UIImageView!
    @IBOutlet weak var doneImage02: UIImageView!
    @IBOutlet weak var doneImage03: UIImageView!
    
    @IBOutlet weak var premiumWeeklyView: UIView!
    @IBOutlet weak var premiumMonthlyView: UIView!
    @IBOutlet weak var premiumYerlyView: UIView!
    
    @IBOutlet weak var termsofUseLabel: UITextView!
    
    @IBOutlet weak var weekStrikethrought: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: weekStrikethrought.text ?? "",
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.gray,
                    .font: UIFont.boldSystemFont(ofSize: weekStrikethrought.font.pointSize) // Bold માટે
                ]
            )
            weekStrikethrought.attributedText = attributedString
        }
    }
    
    @IBOutlet weak var monthlyStrikethrought: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: monthlyStrikethrought.text ?? "",
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.gray,
                    .font: UIFont.boldSystemFont(ofSize: monthlyStrikethrought.font.pointSize) // Bold માટે
                ]
            )
            monthlyStrikethrought.attributedText = attributedString
        }
    }
    
    @IBOutlet weak var yealyStrikethrounght: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: yealyStrikethrounght.text ?? "",
                attributes: [
                    .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                    .strikethroughColor: UIColor.gray,
                    .font: UIFont.boldSystemFont(ofSize: yealyStrikethrounght.font.pointSize) // Bold માટે
                ]
            )
            yealyStrikethrounght.attributedText = attributedString
        }
    }
    
    enum PremiumOption {
        case weekly
        case monthly
        case yearly
    }
    
    private var selectedPremiumOption: PremiumOption?
    
    private let weeklySubscriptionID = "com.prank.memes.wk"
    private let monthlySubscriptionID = "com.prank.memes.mth"
    private let yearlySubscriptionID = "com.prank.memes.yr"
    
    private var weeklySubscription: SKProduct?
    private var monthlySubscription: SKProduct?
    private var yearlySubscription: SKProduct?
    
    private var isRestoringPurchases = false
    
    private var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.setupUIConstraints()
        setupLoadingIndicator()
        fetchProductInfo()
        setupSwipeGesture()
        checkSubscriptionStatus()
        setupPremiumViewTapGestures()
        setupPrivacyPolicyLabel()
        termsofUseLabel.delegate = self
        SKPaymentQueue.default().add(self)
        
        setPurchasedOrDefaultPlan()
        
        setupCollectionView()
        setupContinuousScroll()
        
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 0
        layout.itemSize = itemSize
        
        collectionView = UICollectionView(frame: sliderView.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        sliderView.addSubview(collectionView)
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: sliderView.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: sliderView.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: sliderView.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: sliderView.bottomAnchor)
        ])
    }
    
    private func setupContinuousScroll() {
        
        displayLink = CADisplayLink(target: self, selector: #selector(updateScroll))
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateScroll() {
        guard let collectionView = collectionView else { return }
        
        let currentOffset = collectionView.contentOffset
        
        let newOffset = CGPoint(x: currentOffset.x + scrollSpeed, y: currentOffset.y)
        
        if newOffset.x >= collectionView.contentSize.width - collectionView.bounds.width {
            collectionView.contentOffset = CGPoint(x: 0, y: 0)
        } else {
            collectionView.contentOffset = newOffset
        }
    }
    
    private func setupLoadingIndicator() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.color = .black
        activityIndicator.hidesWhenStopped = true
        upgradeButton.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: upgradeButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: upgradeButton.centerYAnchor)
        ])
    }
    
    private func startLoading() {
        upgradeButton.setTitle("", for: .normal)
        upgradeButton.isEnabled = false
        activityIndicator.startAnimating()
    }
    
    private func stopLoading() {
        upgradeButton.setTitle("Upfrade to premium", for: .normal)
        upgradeButton.isEnabled = true
        activityIndicator.stopAnimating()
    }
    
    private func setPurchasedOrDefaultPlan() {
        if let purchasedPlanType = UserDefaults.standard.string(forKey: "purchasedPlanType") {
            switch purchasedPlanType {
            case weeklySubscriptionID:
                weeklyViewTapped()
            case monthlySubscriptionID:
                monthlyViewTapped()
            case yearlySubscriptionID:
                lifetimeViewTapped()
            default:
                monthlyViewTapped()
            }
        } else {
            monthlyViewTapped()
        }
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func checkSubscriptionStatus() {
        PremiumManager.shared.checkSubscriptionStatus()
    }
    
    private func setupPremiumViewTapGestures() {
        let weeklyTapGesture = UITapGestureRecognizer(target: self, action: #selector(weeklyViewTapped))
        premiumWeeklyView.addGestureRecognizer(weeklyTapGesture)
        
        let monthlyTapGesture = UITapGestureRecognizer(target: self, action: #selector(monthlyViewTapped))
        premiumMonthlyView.addGestureRecognizer(monthlyTapGesture)
        
        let lifetimeTapGesture = UITapGestureRecognizer(target: self, action: #selector(lifetimeViewTapped))
        premiumYerlyView.addGestureRecognizer(lifetimeTapGesture)
        
        doneImage01.image = UIImage(named: "PremiumRadio")
        doneImage02.image = UIImage(named: "PremiumRadio")
        doneImage03.image = UIImage(named: "PremiumRadio")
    }
    
    @objc private func weeklyViewTapped() {
        updateSelectedPremiumView(view: premiumWeeklyView, option: .weekly)
    }
    
    @objc private func monthlyViewTapped() {
        updateSelectedPremiumView(view: premiumMonthlyView, option: .monthly)
    }
    
    @objc private func lifetimeViewTapped() {
        updateSelectedPremiumView(view: premiumYerlyView, option: .yearly)
    }
    
    private func updateSelectedPremiumView(view: UIView, option: PremiumOption) {
        doneImage01.image = UIImage(named: "PremiumRadio")
        doneImage02.image = UIImage(named: "PremiumRadio")
        doneImage03.image = UIImage(named: "PremiumRadio")
        switch option {
        case .weekly:
            doneImage01.image = UIImage(named: "PremiumYes")
        case .monthly:
            doneImage02.image = UIImage(named: "PremiumYes")
        case .yearly:
            doneImage03.image = UIImage(named: "PremiumYes")
        }
        selectedPremiumOption = option
    }
    
    private func fetchProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let request = SKProductsRequest(productIdentifiers: Set([
                weeklySubscriptionID,
                monthlySubscriptionID,
                yearlySubscriptionID
            ]))
            request.delegate = self
            request.start()
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        
        for product in products {
            switch product.productIdentifier {
            case weeklySubscriptionID:
                weeklySubscription = product
                updatePriceLabel(weeklyPriceLabel, with: product)
            case monthlySubscriptionID:
                monthlySubscription = product
                updatePriceLabel(monthlyPriceLabel, with: product)
            case yearlySubscriptionID:
                yearlySubscription = product
                updatePriceLabel(yearlyPriceLabel, with: product)
            default:
                break
            }
        }
    }
    
    private func updatePriceLabel(_ label: UILabel, with product: SKProduct) {
        DispatchQueue.main.async {
            label.text = "\(self.formatPrice(product))/-"
        }
    }
    
    private func formatPrice(_ product: SKProduct) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = product.priceLocale
        return numberFormatter.string(from: product.price) ?? ""
    }
    
    @IBAction func btnPremiumTapped(_ sender: UIButton) {
        if PremiumManager.shared.isContentUnlocked(itemID: -1) {
            showPremiumSuccessAlert()
            return
        }
        
        guard let selectedOption = selectedPremiumOption else {
            let snackbar = CustomSnackbar(message: "Please select a plan", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        if !isConnectedToInternet() {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        startLoading()
        
        if SKPaymentQueue.canMakePayments() {
            let paymentRequest = SKMutablePayment()
            
            switch selectedOption {
            case .weekly:
                paymentRequest.productIdentifier = weeklySubscriptionID
            case .monthly:
                paymentRequest.productIdentifier = monthlySubscriptionID
            case .yearly:
                paymentRequest.productIdentifier = yearlySubscriptionID
            }
            
            SKPaymentQueue.default().add(paymentRequest)
        } else {
            stopLoading()
            print("User unable to make payments")
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    func isSubscriptionActive() -> Bool {
        return UserDefaults.standard.bool(forKey: "isSubscriptionActive")
    }
    
    @IBAction func btnRestoreTapped(_ sender: UIButton) {
        if !isConnectedToInternet() {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
            return
        }
        
        isRestoringPurchases = true
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                DispatchQueue.main.async {
                    self.stopLoading()
                }
                handleSuccessfulPurchase(transaction)
                showPremiumSuccessAlert()
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                DispatchQueue.main.async {
                    self.stopLoading()
                }
                print("Purchase or Restore Failed")
                SKPaymentQueue.default().finishTransaction(transaction)
                handleFailedPurchaseOrRestore(transaction: transaction)
                
            case .restored:
                DispatchQueue.main.async {
                    self.stopLoading()
                }
                handleRestored(transaction)
                showPremiumSuccessAlert()
                
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }
    
    private func handleSuccessfulPurchase(_ transaction: SKPaymentTransaction) {
        let calendar = Calendar.current
        var expirationDate: Date?
        
        UserDefaults.standard.set(transaction.payment.productIdentifier, forKey: "purchasedPlanType")
        
        switch transaction.payment.productIdentifier {
        case weeklySubscriptionID:
            expirationDate = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        case monthlySubscriptionID:
            expirationDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case yearlySubscriptionID:
            expirationDate = calendar.date(byAdding: .year, value: 1, to: Date())
        default:
            break
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
        
        if let expirationDate = expirationDate {
            PremiumManager.shared.setSubscription(expirationDate: expirationDate)
        }
        
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           let receiptData = try? Data(contentsOf: receiptURL) {
            _ = receiptData.base64EncodedString()
        }
    }
    
    private func handleRestored(_ transaction: SKPaymentTransaction) {
        let calendar = Calendar.current
        var expirationDate: Date?
        
        UserDefaults.standard.set(transaction.payment.productIdentifier, forKey: "purchasedPlanType")
        
        switch transaction.payment.productIdentifier {
        case weeklySubscriptionID:
            expirationDate = calendar.date(byAdding: .weekOfYear, value: 1, to: Date())
        case monthlySubscriptionID:
            expirationDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case yearlySubscriptionID:
            expirationDate = calendar.date(byAdding: .year, value: 1, to: Date())
        default:
            break
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("PremiumContentUnlocked"), object: nil)
        PremiumManager.shared.setSubscription(expirationDate: expirationDate!)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        isRestoringPurchases = false
        if queue.transactions.isEmpty {
            let snackbar = CustomSnackbar(message: "No active subscription.", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        isRestoringPurchases = false
        showFailureAlert()
    }
    
    private func handleFailedPurchaseOrRestore(transaction: SKPaymentTransaction) {
        if isRestoringPurchases {
            showFailureAlert()
        } else {
            showFailureAlert()
        }
    }
    
    // MARK: - Show Premium Successfully Alert
    private func showPremiumSuccessAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let customAlertVC = CustomAlertViewController()
            customAlertVC.modalPresentationStyle = .overFullScreen
            customAlertVC.modalTransitionStyle = .crossDissolve
            customAlertVC.message = NSLocalizedString("Congratulation...", comment: "")
            customAlertVC.link = NSLocalizedString("You're all set.", comment: "")
            customAlertVC.image = UIImage(named: "CopyLink")
            
            self.present(customAlertVC, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    customAlertVC.animateDismissal {
                        customAlertVC.dismiss(animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    private func showFailureAlert() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            let customAlertVC = AlertViewController()
            customAlertVC.modalPresentationStyle = .overFullScreen
            customAlertVC.modalTransitionStyle = .crossDissolve
            customAlertVC.message = NSLocalizedString("Failed!", comment: "")
            customAlertVC.link = NSLocalizedString("Request failed. Please try again after some time!", comment: "")
            customAlertVC.image = UIImage(named: "PurchaseFailed")
            
            self.present(customAlertVC, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    customAlertVC.animateDismissal {
                        customAlertVC.dismiss(animated: false, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        if premiumBack == false {
            self.dismiss(animated: true)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
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
    
    func setupPrivacyPolicyLabel() {
        let text = "Features can change at any time. Payment will be charged to your App Store account. Renews at the full price after the introductory offer period. Your subscription will auto-renew at your selected interval until you cancel in App Store settings. Amount of the charge may change with notice. Cancel anytime. By tapping \"App Store\", you are agreeing to the Prankster Subscription Terms & Privacy Policy and also the auto renewal."
        
        let attributedString = NSMutableAttributedString(string: text)
        
        let fullTextRange = NSRange(location: 0, length: text.count)
        attributedString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.6666666667, green: 0.6666666667, blue: 0.6666666667, alpha: 1), range: fullTextRange)
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Medium", size: 10)!, range: fullTextRange)
        
        let termsRange = (text as NSString).range(of: "Terms")
        attributedString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0, green: 0.5019607843, blue: 1, alpha: 1), range: termsRange)
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Heavy", size: 11)!, range: termsRange)
        attributedString.addAttribute(.link, value: "https://pslink.world/termsofuse", range: termsRange)
        
        let privacyPolicyRange = (text as NSString).range(of: "Privacy Policy")
        attributedString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0, green: 0.5019607843, blue: 1, alpha: 1), range: privacyPolicyRange)
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Heavy", size: 11)!, range: privacyPolicyRange)
        attributedString.addAttribute(.link, value: "https://pslink.world/privacy-policy", range: privacyPolicyRange)
        
        termsofUseLabel.attributedText = attributedString
        termsofUseLabel.isSelectable = true
        termsofUseLabel.isEditable = false
        termsofUseLabel.textAlignment = .center
    }
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in range: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.absoluteString == "https://pslink.world/termsofuse" {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
            vc.modalPresentationStyle = .pageSheet
            vc.linkURL = "https://pslink.world/termsofuse"
            self.present(vc, animated: true, completion: nil)
            return false
        }
        else if url.absoluteString == "https://pslink.world/privacy-policy" {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
            vc.modalPresentationStyle = .pageSheet
            vc.linkURL = "https://pslink.world/privacy-policy"
            self.present(vc, animated: true, completion: nil)
            return false
        }
        return true
    }
}

extension PremiumVC {
    
    private func setupUI() {
        self.premiumWeeklyView.layer.cornerRadius = 18
        self.premiumWeeklyView.layer.borderWidth = 2
        self.premiumWeeklyView.layer.borderColor = UIColor.premiumBoader.cgColor
        
        self.premiumMonthlyView.layer.cornerRadius = 18
        self.premiumMonthlyView.layer.borderWidth = 2
        self.premiumMonthlyView.layer.borderColor = UIColor.premiumBoader.cgColor
        
        self.premiumYerlyView.layer.cornerRadius = 18
        self.premiumYerlyView.layer.borderWidth = 2
        self.premiumYerlyView.layer.borderColor = UIColor.premiumBoader.cgColor
        
        self.upgradeButton.layer.cornerRadius = 13
    }
    
    private func setupUIConstraints() {
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            doneImageConstraints.forEach { $0.constant = 20 }
            labelLeftConstraints.forEach { $0.constant = 42 }
            scrollViewHeightConstraints.constant = 258
            sliderHeightConstarints.constant = 100
            self.bestOfferLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
            self.topRatedLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
            self.populareLabel.font = UIFont(name: "Avenir-Heavy", size: 17)
            
            self.weeklyLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.monthlyLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.yearlyLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            
            self.weekStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 12)
            self.monthlyStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 12)
            self.yealyStrikethrounght.font = UIFont(name: "Avenir-Heavy", size: 12)
            
            self.weeklyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.monthlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.yearlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 20)
            switch screenHeight {
            case 1334, 1920, 2340, 1792:
                self.pranksterImageHeightConstraints.constant = 160
            case 2532, 2556, 2436, 2622:
                self.pranksterImageHeightConstraints.constant = 180
            case 2688, 2886, 2796, 2778, 2868, 2869:
                self.pranksterImageHeightConstraints.constant = 220
            default:
                self.pranksterImageHeightConstraints.constant = 160
            }
        } else {
            
            doneImageConstraints.forEach { $0.constant = 30 }
            labelLeftConstraints.forEach { $0.constant = 52 }
            self.pranksterImageHeightConstraints.constant = 350
            scrollViewHeightConstraints.constant = 358
            sliderHeightConstarints.constant = 125
            self.bestOfferLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            self.topRatedLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            self.populareLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            
            self.weeklyLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            self.monthlyLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            self.yearlyLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            
            self.weekStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.monthlyStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.yealyStrikethrounght.font = UIFont(name: "Avenir-Heavy", size: 22)
            
            self.weeklyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            self.monthlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
            self.yearlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 30)
        }
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource
extension PremiumVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int.max
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! ImageCell
        let imageIndex = indexPath.item % images.count
        cell.imageView.image = UIImage(named: images[imageIndex])
        cell.imageFeatursView.image = UIImage(named: imagesIcon[imageIndex])
        cell.featursLabel.text = features[imageIndex]
        return cell
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        displayLink?.isPaused = true
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        displayLink?.isPaused = false
    }
}


// MARK: - ImageCell
class ImageCell: UICollectionViewCell {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 6
        return iv
    }()
    
    let imageFeatursView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
    let featursLabel: UILabel = {
        let lb = UILabel()
        lb.numberOfLines = 0
        lb.textAlignment = .center
        lb.textColor = UIColor.white
        lb.font = UIFont(name: "Avenir-Black", size: 13)
        lb.clipsToBounds = true
        return lb
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupImageView() {
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        imageView.addSubview(imageFeatursView)
        imageFeatursView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageFeatursView.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            imageFeatursView.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            imageFeatursView.widthAnchor.constraint(equalToConstant: 50),
            imageFeatursView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        imageView.addSubview(featursLabel)
        featursLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            featursLabel.topAnchor.constraint(equalTo: imageFeatursView.bottomAnchor),
            featursLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 2),
            featursLabel.trailingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: -2),
            featursLabel.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -4)
        ])
    }
}
