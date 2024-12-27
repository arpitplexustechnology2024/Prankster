//
//  HomeVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

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
    @IBOutlet weak var premiumView: UIView!
    @IBOutlet weak var moreAppView: UIView!
    @IBOutlet weak var spinerButton: UIButton!
    @IBOutlet weak var scrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var audioHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var videoHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var premiumHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var moreAppHeightConstraint: NSLayoutConstraint!
    
    private var dropdownView: UIView?
    private var isDropdownVisible = false
    private let adsViewModel = AdsViewModel()
    
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
        self.loadAds()
        self.seupViewAction()
        self.requestNotificationPermission()
        self.navigationbarView.addBottomShadow()
    }
    
    func setupUI() {
        self.audioView.layer.cornerRadius = 15
        self.videoView.layer.cornerRadius = 15
        self.imageView.layer.cornerRadius = 15
        self.premiumView.layer.cornerRadius = 15
        self.moreAppView.layer.cornerRadius = 15
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            scrollViewHeightConstraint.constant = 810
            audioHeightConstraint.constant = 140
            videoHeightConstraint.constant = 140
            imageHeightConstraint.constant = 140
            premiumHeightConstraint.constant = 140
            moreAppHeightConstraint.constant = 140
        } else {
            scrollViewHeightConstraint.constant = 730
            audioHeightConstraint.constant = 120
            videoHeightConstraint.constant = 120
            imageHeightConstraint.constant = 120
            premiumHeightConstraint.constant = 120
            moreAppHeightConstraint.constant = 120
        }
        self.view.layoutIfNeeded()
    }
    
    func seupViewAction() {
        let tapGestureActions: [(UIView, Selector)] = [
            (audioView, #selector(btnAudioTapped)),
            (videoView, #selector(btnVideoTapped)),
            (imageView, #selector(btnImageTapped)),
            (premiumView, #selector(btnPremiumTapped)),
            (moreAppView, #selector(btnViewLinkTapped)),
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
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
            vc.viewType = .audio
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func btnVideoTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
            vc.viewType = .video
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func btnImageTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "CoverPageVC") as! CoverPageVC
            vc.viewType = .image
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @objc func btnPremiumTapped(_ sender: UIButton) {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PremiumVC") as! PremiumVC
        self.navigationController?.pushViewController(premiumVC, animated: true)
    }
    
    @objc func btnViewLinkTapped(_ sender: UITapGestureRecognizer) {
        if isDropdownVisible {
            hideDropdown()
        } else {
            let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "ViewLinkVC") as! ViewLinkVC
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    
    
    @IBAction func btnSpinnerTapped(_ sender: UIButton) {
        if isDropdownVisible {
            hideDropdown()
            return
        }
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "SpinnerVC") as! SpinnerVC
        self.navigationController?.pushViewController(vc, animated: true)
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
        dropdownView.backgroundColor = .comman
        dropdownView.layer.cornerRadius = 12
        dropdownView.layer.shadowColor = UIColor.icon.cgColor
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
        
        let shareButton = createOptionButton(
            title: "Share app",
            icon: "ShareApp",
            action: #selector(shareAppTapped)
        )
        
        stackView.addArrangedSubview(privacyButton)
        stackView.addArrangedSubview(createSeparator())
        stackView.addArrangedSubview(shareButton)
    }
    
    private func createOptionButton(title: String, icon: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .clear
        
        let imageView = UIImageView(image: UIImage(named: icon))
        imageView.tintColor = .black
        imageView.contentMode = .scaleAspectFit
        
        let label = UILabel()
        label.text = title
        label.textColor = .icon
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
        let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "PrivacyPolicyVC") as! PrivacyPolicyVC
        vc.modalPresentationStyle = .pageSheet
        self.present(vc, animated: true, completion: nil)
    }
    
    @objc private func shareAppTapped() {
        hideDropdown()
        let appURL = URL(string: "https://apps.apple.com/us/app/6739135275")!
        let activityVC = UIActivityViewController(activityItems: [appURL], applicationActivities: nil)
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        self.present(activityVC, animated: true, completion: nil)
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
        content.title = NSLocalizedString(randomMessage.title, comment: "")
        content.body = NSLocalizedString(randomMessage.body, comment: "")
        content.sound = UNNotificationSound.default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 10
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "5PMDailyReminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for 5:00 PM daily")
            }
        }
    }
    
    func loadAds() {
        adsViewModel.fetchAds { [weak self] success in
            if success {
                print("Ads loaded successfully")
                let (savedNames, savedIDs) = self?.adsViewModel.getSavedAds() ?? ([], [])
                print("Saved Ad Names: \(savedNames)")
                print("Saved Ad IDs: \(savedIDs)")
            } else {
                print("Failed to load ads")
                self?.adsViewModel.removeAdsFromUserDefaults()
            }
        }
    }
}

