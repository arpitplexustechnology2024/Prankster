//
//  PremiumVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import StoreKit
import Alamofire
import SafariServices

class PremiumVC: UIViewController, SKPaymentTransactionObserver, SKProductsRequestDelegate, UITextViewDelegate {
    
    @IBOutlet weak var premiumImage: UIImageView!
    @IBOutlet weak var premiumButton: UIButton!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var bestofferView: UIView!
    @IBOutlet weak var topratedView: UIView!
    @IBOutlet weak var popularView: UIView!
    @IBOutlet weak var emojiStarckView: UIStackView!
    @IBOutlet weak var featurstext01: UILabel!
    @IBOutlet weak var featurstext02: UILabel!
    @IBOutlet weak var featurstext03: UILabel!
    @IBOutlet weak var featurstext04: UILabel!
    @IBOutlet weak var bestOfferLabel: UILabel!
    @IBOutlet weak var weeklyLabel: UILabel!
    @IBOutlet weak var weeklyPriceLabel: UILabel!
    @IBOutlet weak var topRatedLabel: UILabel!
    @IBOutlet weak var monthlyLabel: UILabel!
    @IBOutlet weak var monthlyPriceLabel: UILabel!
    @IBOutlet weak var populareLabel: UILabel!
    @IBOutlet weak var yearlyLabel: UILabel!
    @IBOutlet weak var yearlyPriceLabel: UILabel!
    @IBOutlet weak var premiumViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var bestOfferViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var bestOfferViewWidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var topRatedViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var topRatedViewWidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var popularViewHeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var populareViewWidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var PremiumViewScrollWidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs01HeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs01WidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs02HeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs02WidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs03HeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs03WidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs04HeightConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurs04WidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var premiymBottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var emojiBottomConstraints: NSLayoutConstraint!
    @IBOutlet weak var featurstext01Constraints: NSLayoutConstraint!
    @IBOutlet weak var featurstext02Constraints: NSLayoutConstraint!
    @IBOutlet weak var featurstext03Constraints: NSLayoutConstraint!
    @IBOutlet weak var featurstext04Constraints: NSLayoutConstraint!
    
    @IBOutlet weak var doneImage01: UIImageView!
    @IBOutlet weak var doneImage02: UIImageView!
    @IBOutlet weak var doneImage03: UIImageView!
    
    @IBOutlet weak var premiumWeeklyView: UIView!
    @IBOutlet weak var premiumMonthlyView: UIView!
    @IBOutlet weak var premiumLifeTimeView: UIView!
    
    @IBOutlet weak var termsofUseLabel: UITextView!
    
    @IBOutlet weak var weekStrikethrought: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: weekStrikethrought.text ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .strikethroughColor: UIColor.gray]
            )
            weekStrikethrought.attributedText = attributedString
        }
    }
    
    @IBOutlet weak var monthlyStrikethrought: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: monthlyStrikethrought.text ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .strikethroughColor: UIColor.gray]
            )
            monthlyStrikethrought.attributedText = attributedString
        }
    }
    
    @IBOutlet weak var ligetimeStrikethrounght: UILabel! {
        didSet {
            let attributedString = NSAttributedString(
                string: ligetimeStrikethrounght.text ?? "",
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue, .strikethroughColor: UIColor.gray]
            )
            ligetimeStrikethrounght.attributedText = attributedString
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchProductInfo()
        setupUI()
        setupSwipeGesture()
        checkSubscriptionStatus()
        setupPremiumViewTapGestures()
        setupPrivacyPolicyLabel()
        termsofUseLabel.delegate = self
        SKPaymentQueue.default().add(self)
        
        setPurchasedOrDefaultPlan()
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
        premiumLifeTimeView.addGestureRecognizer(lifetimeTapGesture)
        
        doneImage01.image = UIImage(named: "RadioCircle")
        doneImage02.image = UIImage(named: "RadioCircle")
        doneImage03.image = UIImage(named: "RadioCircle")
    }
    
    @objc private func weeklyViewTapped() {
        updateSelectedPremiumView(view: premiumWeeklyView, option: .weekly)
    }
    
    @objc private func monthlyViewTapped() {
        updateSelectedPremiumView(view: premiumMonthlyView, option: .monthly)
    }
    
    @objc private func lifetimeViewTapped() {
        updateSelectedPremiumView(view: premiumLifeTimeView, option: .yearly)
    }
    
    private func updateSelectedPremiumView(view: UIView, option: PremiumOption) {
        doneImage01.image = UIImage(named: "RadioCircle")
        doneImage02.image = UIImage(named: "RadioCircle")
        doneImage03.image = UIImage(named: "RadioCircle")
        switch option {
        case .weekly:
            doneImage01.image = UIImage(named: "Yespremium")
        case .monthly:
            doneImage02.image = UIImage(named: "Yespremium")
        case .yearly:
            doneImage03.image = UIImage(named: "Yespremium")
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
                handleSuccessfulPurchase(transaction)
                showPremiumSuccessAlert()
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case .failed:
                print("Purchase or Restore Failed")
                SKPaymentQueue.default().finishTransaction(transaction)
                handleFailedPurchaseOrRestore(transaction: transaction)
                
            case .restored:
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
        self.navigationController?.popViewController(animated: true)
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
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Medium", size: 11)!, range: fullTextRange)
        
        let termsRange = (text as NSString).range(of: "Terms")
        attributedString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0, green: 0.5019607843, blue: 1, alpha: 1), range: termsRange)
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Heavy", size: 12)!, range: termsRange)
        attributedString.addAttribute(.link, value: "https://pslink.world/termsofuse", range: termsRange)
        
        let privacyPolicyRange = (text as NSString).range(of: "Privacy Policy")
        attributedString.addAttribute(.foregroundColor, value: #colorLiteral(red: 0, green: 0.5019607843, blue: 1, alpha: 1), range: privacyPolicyRange)
        attributedString.addAttribute(.font, value: UIFont(name: "Avenir-Heavy", size: 12)!, range: privacyPolicyRange)
        attributedString.addAttribute(.link, value: "https://pslink.world/privacy-policy", range: privacyPolicyRange)
        
        termsofUseLabel.attributedText = attributedString
        termsofUseLabel.isSelectable = true
        termsofUseLabel.isEditable = false
        termsofUseLabel.textAlignment = .center
    }
    
    func textView(_ textView: UITextView, shouldInteractWith url: URL, in range: NSRange, interaction: UITextItemInteraction) -> Bool {
        if url.absoluteString == "https://pslink.world/termsofuse" || url.absoluteString == "https://pslink.world/privacy-policy" {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true, completion: nil)
            return false
        }
        return true
    }
}

extension PremiumVC {
    func setupUI() {
        self.premiumButton.layer.cornerRadius = 13
        self.premiumWeeklyView.layer.cornerRadius = 10
        
        bestofferView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        bestofferView.layer.cornerRadius = 10
        bestofferView.clipsToBounds = true
        self.premiumMonthlyView.layer.cornerRadius = 10
        topratedView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        topratedView.layer.cornerRadius = 10
        topratedView.clipsToBounds = true
        self.premiumLifeTimeView.layer.cornerRadius = 10
        popularView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMaxYCorner]
        popularView.layer.cornerRadius = 10
        popularView.clipsToBounds = true
        
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            premiumImage.image = UIImage(named: "premiumUI-iPhone")
        } else if UIDevice.current.userInterfaceIdiom == .pad {
            premiumImage.image = UIImage(named: "premiumUI-iPad")
        }
        
        let screenHeight = UIScreen.main.nativeBounds.height
        if UIDevice.current.userInterfaceIdiom == .phone {
            
            self.premiumWeeklyView.addGradientBorder(colors: [UIColor(hex: "#01B4D8"),UIColor(hex: "#8FE0EF")],width: 3.0,cornerRadius: 10)
            bestofferView.setHorizontalGradientBackground( colorLeft: UIColor(hex: "#01B4D8"), colorRight: UIColor(hex: "#8FE0EF"))
            self.premiumMonthlyView.addGradientBorder(colors: [UIColor(hex: "#FC6D70"),UIColor(hex: "#FEA3A4")],width: 3.0,cornerRadius: 10)
            topratedView.setHorizontalGradientBackground( colorLeft: UIColor(hex: "#FC6D70"), colorRight: UIColor(hex: "#FEA3A4"))
            self.premiumLifeTimeView.addGradientBorder(colors: [UIColor(hex: "#B094E0"),UIColor(hex: "#CAA3FD")],width: 4.0,cornerRadius: 10)
            popularView.setHorizontalGradientBackground( colorLeft: UIColor(hex: "#B094E0"), colorRight: UIColor(hex: "#CAA3FD"))
            
            self.featurs01HeightConstraints.constant = 80
            self.featurs01WidthConstraints.constant = 60
            self.featurs02HeightConstraints.constant = 80
            self.featurs02WidthConstraints.constant = 60
            self.featurs03HeightConstraints.constant = 80
            self.featurs03WidthConstraints.constant = 60
            self.featurs04HeightConstraints.constant = 53
            self.featurs04WidthConstraints.constant = 60
            self.premiumViewHeightConstraints.constant = 100
            self.PremiumViewScrollWidthConstraints.constant = 500
            self.bestOfferViewHeightConstraints.constant = 30
            self.bestOfferViewWidthConstraints.constant = 87
            self.topRatedViewHeightConstraints.constant = 30
            self.topRatedViewWidthConstraints.constant = 87
            self.popularViewHeightConstraints.constant = 30
            self.populareViewWidthConstraints.constant = 87
            self.bestOfferLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.topRatedLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.populareLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.weeklyLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.monthlyLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.yearlyLabel.font = UIFont(name: "Avenir-Heavy", size: 14)
            self.weeklyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            self.monthlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            self.yearlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 23)
            self.weekStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 12)
            self.monthlyStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 12)
            self.ligetimeStrikethrounght.font = UIFont(name: "Avenir-Heavy", size: 12)
            self.featurstext01.font = UIFont(name: "Avenir-Heavy", size: 17)
            self.featurstext02.font = UIFont(name: "Avenir-Heavy", size: 17)
            self.featurstext03.font = UIFont(name: "Avenir-Heavy", size: 17)
            self.featurstext04.font = UIFont(name: "Avenir-Heavy", size: 17)
            switch screenHeight {
            case 1334, 1920, 2340, 1792:
                self.emojiStarckView.spacing = -10
                self.emojiBottomConstraints.constant = 10
                self.premiymBottomConstraints.constant = 10
                self.featurstext01Constraints.constant = 25
                self.featurstext02Constraints.constant = 47.33
                self.featurstext03Constraints.constant = 47.33
                self.featurstext04Constraints.constant = 37.33
            case 2532, 2556, 2436:
                self.emojiStarckView.spacing = -5
                self.emojiBottomConstraints.constant = 20
                self.premiymBottomConstraints.constant = 20
                self.featurstext01Constraints.constant = 35
                self.featurstext02Constraints.constant = 52.33
                self.featurstext03Constraints.constant = 52.33
                self.featurstext04Constraints.constant = 42.33
            case 2622:
                self.emojiStarckView.spacing = -5
                self.emojiBottomConstraints.constant = 30
                self.premiymBottomConstraints.constant = 20
                self.featurstext01Constraints.constant = 45
                self.featurstext02Constraints.constant = 52.33
                self.featurstext03Constraints.constant = 52.33
                self.featurstext04Constraints.constant = 42.33
            case 2688, 2886, 2796, 2778, 2868, 2869:
                self.emojiStarckView.spacing = -5
                self.emojiBottomConstraints.constant = 35
                self.premiymBottomConstraints.constant = 30
                self.featurstext01Constraints.constant = 50
                self.featurstext02Constraints.constant = 52.33
                self.featurstext03Constraints.constant = 52.33
                self.featurstext04Constraints.constant = 42.33
            default:
                self.emojiStarckView.spacing = -5
                self.emojiBottomConstraints.constant = 20
                self.premiymBottomConstraints.constant = 20
                self.featurstext01Constraints.constant = 35
                self.featurstext02Constraints.constant = 52.33
                self.featurstext03Constraints.constant = 52.33
                self.featurstext04Constraints.constant = 42.33
            }
        } else {
            
            premiumLifeTimeView.layer.borderWidth = 3.0
            premiumLifeTimeView.layer.borderColor = UIColor(hex: "#B094E0").cgColor
            popularView.layer.backgroundColor = UIColor(hex: "#B094E0").cgColor
            premiumMonthlyView.layer.borderWidth = 3.0
            premiumMonthlyView.layer.borderColor = UIColor(hex: "#FC6D70").cgColor
            topratedView.layer.backgroundColor = UIColor(hex: "#FC6D70").cgColor
            premiumWeeklyView.layer.borderWidth = 3.0
            premiumWeeklyView.layer.borderColor = UIColor(hex: "#01B4D8").cgColor
            bestofferView.layer.backgroundColor = UIColor(hex: "#01B4D8").cgColor
            
            self.emojiStarckView.spacing = -5
            self.emojiBottomConstraints.constant = 35
            self.premiymBottomConstraints.constant = 30
            self.featurstext01Constraints.constant = 55
            self.featurstext02Constraints.constant = 65.33
            self.featurstext03Constraints.constant = 65.33
            self.featurstext04Constraints.constant = 50.33
            self.featurs01HeightConstraints.constant = 110
            self.featurs01WidthConstraints.constant = 74
            self.featurs02HeightConstraints.constant = 110
            self.featurs02WidthConstraints.constant = 74
            self.featurs03HeightConstraints.constant = 110
            self.featurs03WidthConstraints.constant = 74
            self.featurs04HeightConstraints.constant = 74
            self.featurs04WidthConstraints.constant = 74
            self.PremiumViewScrollWidthConstraints.constant = 1000
            self.premiumViewHeightConstraints.constant = 170
            self.bestOfferViewHeightConstraints.constant = 50
            self.bestOfferViewWidthConstraints.constant = 155
            self.topRatedViewHeightConstraints.constant = 50
            self.topRatedViewWidthConstraints.constant = 155
            self.popularViewHeightConstraints.constant = 50
            self.populareViewWidthConstraints.constant = 155
            self.bestOfferLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.topRatedLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.populareLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.weeklyLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.monthlyLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.yearlyLabel.font = UIFont(name: "Avenir-Heavy", size: 22)
            self.weeklyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 41)
            self.monthlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 41)
            self.yearlyPriceLabel.font = UIFont(name: "Avenir-Heavy", size: 41)
            self.weekStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.monthlyStrikethrought.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.ligetimeStrikethrounght.font = UIFont(name: "Avenir-Heavy", size: 20)
            self.featurstext01.font = UIFont(name: "Avenir-Heavy", size: 28)
            self.featurstext02.font = UIFont(name: "Avenir-Heavy", size: 28)
            self.featurstext03.font = UIFont(name: "Avenir-Heavy", size: 28)
            self.featurstext04.font = UIFont(name: "Avenir-Heavy", size: 28)
        }
    }
}
