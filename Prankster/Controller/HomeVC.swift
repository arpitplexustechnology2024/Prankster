//
//  HomeVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit
import SafariServices
import Alamofire

enum CoverViewType {
    case audio
    case video
    case image
}

class HomeVC: UIViewController, UIDocumentInteractionControllerDelegate {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var audioView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var imageView: UIView!
    @IBOutlet weak var nativeSmallAd: UIView!
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var spinnerView: UIView!
    @IBOutlet weak var recentView: UIView!
    @IBOutlet weak var spinerButton: UIButton!
    @IBOutlet weak var audiotitleLabel: UILabel!
    @IBOutlet weak var audiodescriptionLabel: UILabel!
    @IBOutlet weak var videotitleLabel: UILabel!
    @IBOutlet weak var videodescriptionLabel: UILabel!
    @IBOutlet weak var imagetitleLabel: UILabel!
    @IBOutlet weak var imagedescriptionLabel: UILabel!
    @IBOutlet weak var premiumtitleLabel: UILabel!
    @IBOutlet weak var premiumdescriptionLabel: UILabel!
    @IBOutlet weak var viewtitleLabel: UILabel!
    @IBOutlet weak var viewdescriptionLabel: UILabel!
    @IBOutlet weak var spinnertitleLabel: UILabel!
    @IBOutlet weak var spinnerdescriptionLabel: UILabel!
    
    @IBOutlet weak var audioImageHeightsConstraints: NSLayoutConstraint!
    @IBOutlet weak var videoImageHeightsConstraints: NSLayoutConstraint!
    @IBOutlet weak var imageImageHeightsConstraints: NSLayoutConstraint!
    @IBOutlet weak var premiumImageHeightsConstraints: NSLayoutConstraint!
    @IBOutlet weak var viewImageHeightsConstraints: NSLayoutConstraint!
    @IBOutlet weak var spinnerImageHeightsConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var premiumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var recentHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var spinnerHeightConstraint: NSLayoutConstraint!
    
    private var dropdownView: UIView?
    private var isDropdownVisible = false
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    let interstitialAdUtility = InterstitialAdUtility()
    let shouldOpenDirectly = PremiumManager.shared.isContentUnlocked(itemID: -1)
    
    let notificationMessages = [
        (title: "Sex Prank", body: "Create sex prank & share it & capture funny moments."),
        (title: "फाट साउंड प्रैंक", body: "आपका फ्रेंड क्लास मैं है उसके साथ फनी फाट साउंड प्रैंक करो"),
        (title: "GF prank...👧🏻", body: "Prank with your girlfriend if you are daring.😂"),
        (title: "Viral prank 🚨", body: "Your prank video has gone viral, and now people are eagerly waiting for your next one 👀"),
        (title: "चड्डी का कलर 👙", body: "कोनसे कलर की चड्डी पहनी है! #Prankster😜"),
        (title: "Crush waiting...", body: "Your crush has just viewed your profile picture. This prank do with your friend!")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.seupViewAction()
        self.requestNotificationPermission()
    }
    
    func setupUI() {
        self.audioView.layer.cornerRadius = 15
        self.videoView.layer.cornerRadius = 15
        self.imageView.layer.cornerRadius = 15
        self.premiumView.layer.cornerRadius = 15
        self.spinnerView.layer.cornerRadius = 15
        self.recentView.layer.cornerRadius = 15
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollViewHeightConstraint.constant = 1180
            audioHeightConstraint.constant = 150
            videoHeightConstraint.constant = 150
            imageHeightConstraint.constant = 150
            premiumHeightConstraint.constant = 150
            recentHeightConstraint.constant = 150
            spinnerHeightConstraint.constant = 150
            audioImageHeightsConstraints.constant = 100
            videoImageHeightsConstraints.constant = 100
            imageImageHeightsConstraints.constant = 100
            premiumImageHeightsConstraints.constant = 100
            viewImageHeightsConstraints.constant = 100
            spinnerImageHeightsConstraints.constant = 100
            audiotitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            audiodescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            videotitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            videodescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            imagetitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            imagedescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            premiumtitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            premiumdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            viewtitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            viewdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            spinnertitleLabel.font = UIFont(name: "Avenir-Black", size: 30.0)
            spinnerdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 20.0)
            if isConnectedToInternet() {
                if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                    nativeSmallAd.isHidden = true
                } else {
                    nativeSmallIpadAdUtility = NativeSmallIpadAdUtility(adUnitID: "ca-app-pub-3940256099942544/3986624511", rootViewController: self, nativeAdPlaceholder: nativeSmallAd)
                }
            } else {
                nativeSmallAd.isHidden = true
            }
        } else {
            scrollViewHeightConstraint.constant = 1000
            audioHeightConstraint.constant = 120
            videoHeightConstraint.constant = 120
            imageHeightConstraint.constant = 120
            premiumHeightConstraint.constant = 120
            recentHeightConstraint.constant = 120
            spinnerHeightConstraint.constant = 120
            audioImageHeightsConstraints.constant = 75
            videoImageHeightsConstraints.constant = 75
            imageImageHeightsConstraints.constant = 75
            premiumImageHeightsConstraints.constant = 75
            viewImageHeightsConstraints.constant = 75
            spinnerImageHeightsConstraints.constant = 75
            audiotitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            audiodescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            videotitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            videodescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            imagetitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            imagedescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            premiumtitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            premiumdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            viewtitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            viewdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            spinnertitleLabel.font = UIFont(name: "Avenir-Black", size: 25.0)
            spinnerdescriptionLabel.font = UIFont(name: "Avenir-Medium", size: 17.0)
            if isConnectedToInternet() {
                if PremiumManager.shared.isContentUnlocked(itemID: -1) {
                    nativeSmallAd.isHidden = true
                } else {
                    nativeSmallIphoneAdUtility = NativeSmallIphoneAdUtility(adUnitID: "ca-app-pub-3940256099942544/3986624511", rootViewController: self, nativeAdPlaceholder: nativeSmallAd)
                }
            } else {
                nativeSmallAd.isHidden = true
            }
        }
        self.view.layoutIfNeeded()
        
        if isConnectedToInternet() {
            if PremiumManager.shared.isContentUnlocked(itemID: -1) {
            } else {
                interstitialAdUtility.loadInterstitialAd(adUnitID: "ca-app-pub-7719542074975419/3492267881", rootViewController: self)
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
    
    func seupViewAction() {
        let tapGestureActions: [(UIView, Selector)] = [
            (audioView, #selector(btnAudioTapped)),
            (videoView, #selector(btnVideoTapped)),
            (imageView, #selector(btnImageTapped)),
            (premiumView, #selector(btnPremiumTapped)),
            (recentView, #selector(btnViewLinkTapped)),
            (spinnerView, #selector(btnSpinnerTapped)),
        ]
        
        tapGestureActions.forEach { view, action in
            view.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: action)
            tapGesture.cancelsTouchesInView = false
            view.addGestureRecognizer(tapGesture)
        }
    }
    
    @objc func btnAudioTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                vc.viewType = .audio
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                    vc.viewType = .audio
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func btnVideoTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                vc.viewType = .video
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                    vc.viewType = .video
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func btnImageTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                vc.viewType = .image
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
                    vc.viewType = .image
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func btnPremiumTapped(_ sender: UIButton) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PremiumVC") as! PremiumVC
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PremiumVC") as! PremiumVC
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func btnViewLinkTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ViewLinkVC") as! ViewLinkVC
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ViewLinkVC") as! ViewLinkVC
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @objc func btnSpinnerTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            if shouldOpenDirectly {
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SpinnerVC") as! SpinnerVC
                self.navigationController?.pushViewController(vc, animated: true)
            } else {
                interstitialAdUtility.showInterstitialAd()
                interstitialAdUtility.onInterstitialEarned = { [weak self] in
                    let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SpinnerVC") as! SpinnerVC
                    self?.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    @IBAction func btnMoreAppTapped(_ sender: UIButton) {
        if isDropdownVisible {
            hideDropdown()
            return
        }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MoreAppVC") as! MoreAppVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func btnDropDownTapped(_ sender: UIButton) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            showDropdown(sender)
        }
    }
}

// MARK: - Dropdown Implementation
extension HomeVC {
    private func showDropdown(_ sender: UIButton) {
        guard dropdownView == nil else { return }
        
        let dropdownView = UIView()
        dropdownView.backgroundColor = .background
        dropdownView.layer.cornerRadius = 12
        dropdownView.layer.shadowColor = UIColor.white.cgColor
        dropdownView.layer.shadowOffset = CGSize(width: 0, height: 2)
        dropdownView.layer.shadowRadius = 4
        dropdownView.layer.shadowOpacity = 0.1
        
        view.addSubview(dropdownView)
        self.dropdownView = dropdownView
        
        dropdownView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dropdownView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor, constant: 8),
            dropdownView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            dropdownView.widthAnchor.constraint(equalToConstant: 204),
        ])
        
        setupDropdownContent(in: dropdownView)
        
        dropdownView.alpha = 0
        dropdownView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            .translatedBy(x: 0, y: -10)
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.5,
                       options: .curveEaseOut,
                       animations: {
            dropdownView.alpha = 1
            dropdownView.transform = .identity
        })
        
        isDropdownVisible = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapOutside))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    private func hideDropdown() {
        guard let dropdownView = dropdownView else { return }
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: .curveEaseIn,
                       animations: {
            dropdownView.alpha = 0
            dropdownView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
                .translatedBy(x: 0, y: -10)
        }) { _ in
            dropdownView.removeFromSuperview()
            self.dropdownView = nil
        }
        
        isDropdownVisible = false
        
        if let tapGesture = view.gestureRecognizers?.first(where: { $0 is UITapGestureRecognizer }) {
            view.removeGestureRecognizer(tapGesture)
        }
    }
    
    private func setupDropdownContent(in dropdownView: UIView) {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        dropdownView.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: dropdownView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: dropdownView.bottomAnchor)
        ])
        
        let privacyButton = createOptionButton(
            title: "Privacy Policy",
            icon: "PrivacyPolicy",
            action: #selector(privacyPolicyTapped)
        )
        
        let termsButton = createOptionButton(
            title: "Terms of use",
            icon: "TermsOfUse",
            action: #selector(termsofuseTapped)
        )
        
        stackView.addArrangedSubview(privacyButton)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(termsButton)
    }
    
    private func createOptionButton(title: String, icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        
        let imageView = UIImageView(image: UIImage(named: icon))
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.textColor = .white
        label.numberOfLines = 0
        label.font = UIFont(name: "Avenir-Medium", size: 16)
        
        button.addSubview(imageView)
        button.addSubview(label)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 56),
            
            imageView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 16),
            imageView.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 20),
            imageView.heightAnchor.constraint(equalToConstant: 20),
            
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            label.centerYAnchor.constraint(equalTo: button.centerYAnchor)
        ])
        
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .systemGray5
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }
    
    @objc private func handleTapOutside(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if let dropdownView = dropdownView,
           !dropdownView.frame.contains(location) {
            hideDropdown()
        }
    }
    
    @objc private func privacyPolicyTapped() {
        hideDropdown()
        if let url = URL(string: "https://pslink.world/privacy-policy") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true, completion: nil)
        } else {
            print("Invalid URL")
        }
        //        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
        //        vc.modalPresentationStyle = .pageSheet
        //        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func termsofuseTapped() {
        hideDropdown()
        if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
            let safariVC = SFSafariViewController(url: url)
            present(safariVC, animated: true, completion: nil)
        } else {
            print("Invalid URL")
        }
    }
}

// MARK: - Local Notification
extension HomeVC {
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [self] granted, error in
            if granted {
                print("Notification permission granted")
                self.scheduleLocalNotification()
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleLocalNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let content = UNMutableNotificationContent()
        let randomMessage = notificationMessages.randomElement()!
        content.title = randomMessage.title
        content.body = randomMessage.body
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "5PMDailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for 10:00 AM daily")
            }
        }
    }
}
