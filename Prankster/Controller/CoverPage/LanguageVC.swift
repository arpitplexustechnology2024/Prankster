//
//  SearchVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import UIKit
import Alamofire

@available(iOS 15.0, *)
class LanguageVC: UIViewController {
    
    @IBOutlet weak var nativeSmallAds: UIView!
    @IBOutlet weak var adHeightConstaints: NSLayoutConstraint!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewHeightConstraints: NSLayoutConstraint!
    
    @IBOutlet weak var hindiLanguage: UIView!
    @IBOutlet weak var englishLanguage: UIView!
    @IBOutlet weak var marathiLanguage: UIView!
    @IBOutlet weak var gujaratiLanguage: UIView!
    @IBOutlet weak var tamilLanguage: UIView!
    @IBOutlet weak var punjabiLanguage: UIView!
    
    @IBOutlet weak var hindiRadio: UIButton!
    @IBOutlet weak var englishRadio: UIButton!
    @IBOutlet weak var marathiRadio: UIButton!
    @IBOutlet weak var gujaratiRadio: UIButton!
    @IBOutlet weak var tamilRadio: UIButton!
    @IBOutlet weak var punjabiRadio: UIButton!
    
    @IBOutlet var radioConstraints: [NSLayoutConstraint]!
    @IBOutlet var imageWidthConstraints: [NSLayoutConstraint]!
    @IBOutlet var languageLabel: [UILabel]!
    
    var coverImageUrl: String?
    var coverimageName: String?
    var coverImageFile: Data?
    
    private var selectedLanguageId: Int?
    var buttonType: HomeVC.ButtonType?
    
    private var nativeSmallIphoneAdUtility: NativeSmallIphoneAdUtility?
    private var nativeSmallIpadAdUtility: NativeSmallIpadAdUtility?
    private let adsViewModel = AdsViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSwipeGesture()
        setupUI()
        setupAds()
        selectLanguage(for: hindiRadio)
        
        print("CoverImage URL :- \(coverImageUrl ?? "")")
        print("CoverImage File :- \(coverImageFile ?? Data())")
    }
    
    private func setupUI() {
        let languageViews = [hindiLanguage, englishLanguage, marathiLanguage, gujaratiLanguage, tamilLanguage, punjabiLanguage]
        
        for (_, view) in languageViews.enumerated() {
            view?.layer.cornerRadius = 10
            view?.layer.borderWidth = 1
            view?.layer.borderColor = UIColor(hex: "#636363").cgColor
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(languageViewTapped(_:)))
            view?.addGestureRecognizer(tapGesture)
            view?.isUserInteractionEnabled = true
        }
        
        selectedLanguageId = 1
        hindiRadio?.setImage(UIImage(named: "RadioFill"), for: .normal)
        hindiLanguage?.layer.borderColor = UIColor(hex: "#FBCE22").cgColor
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            for button in radioConstraints {
                button.constant = 40
            }
            for label in languageLabel {
                label.font = UIFont(name: "Avenir-Medium", size: 30)
            }
            for image in imageWidthConstraints {
                image.constant = 68.5
            }
            self.stackViewHeightConstraints.constant = 650
        } else {
            for button in radioConstraints {
                button.constant = 20
            }
            for label in languageLabel {
                label.font = UIFont(name: "Avenir-Medium", size: 20)
            }
            for image in imageWidthConstraints {
                image.constant = 35.33
            }
            self.stackViewHeightConstraints.constant = 450
        }
    }
    
    @objc private func languageViewTapped(_ sender: UITapGestureRecognizer) {
        guard let selectedView = sender.view else { return }
        
        let languageViews = [hindiLanguage, englishLanguage, marathiLanguage, gujaratiLanguage, tamilLanguage, punjabiLanguage]
        let radioButtons = [hindiRadio, englishRadio, marathiRadio, gujaratiRadio, tamilRadio, punjabiRadio]
        
        for (index, view) in languageViews.enumerated() {
            if view == selectedView {
                selectLanguage(for: radioButtons[index])
            }
        }
    }
    
    private func selectLanguage(for sender: UIButton?) {
        let languageViews = [hindiLanguage, englishLanguage, marathiLanguage, gujaratiLanguage, tamilLanguage, punjabiLanguage]
        let radioButtons = [hindiRadio, englishRadio, marathiRadio, gujaratiRadio, tamilRadio, punjabiRadio]
        let languages = [1, 2, 3, 4, 5, 6]
        
        for (index, button) in radioButtons.enumerated() {
            if button == sender {
                button?.setImage(UIImage(named: "RadioFill"), for: .normal)
                languageViews[index]?.layer.borderColor = UIColor(hex: "#FBCE22").cgColor
                selectedLanguageId = languages[index]
                print("Selected Language: \(languages[index])")
            } else {
                button?.setImage(UIImage(named: "Radio"), for: .normal)
                languageViews[index]?.layer.borderColor = UIColor(hex: "#636363").cgColor
            }
        }
    }
    
    private func setupAds() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            adHeightConstaints.constant = 150
        } else {
            adHeightConstaints.constant = 120
        }
        
        if isConnectedToInternet(), !PremiumManager.shared.isContentUnlocked(itemID: -1) {
            if let nativeAdID = adsViewModel.getAdID(type: .nativebig) {
                print("Native Ad ID: \(nativeAdID)")
                if UIDevice.current.userInterfaceIdiom == .pad {
                    nativeSmallIpadAdUtility = NativeSmallIpadAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                } else {
                    nativeSmallIphoneAdUtility = NativeSmallIphoneAdUtility(adUnitID: nativeAdID, rootViewController: self, nativeAdPlaceholder: nativeSmallAds)
                }
            } else {
                nativeSmallAds.isHidden = true
            }
        } else {
            nativeSmallAds.isHidden = true
        }
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
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
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        switch buttonType {
        case .audio:
            if let VC = self.storyboard?.instantiateViewController(withIdentifier: "AudioPrankVC") as? AudioPrankVC {
                VC.languageid = selectedLanguageId ?? 1
                VC.selectedCoverImageURL = self.coverImageUrl
                VC.selectedCoverImageName = self.coverimageName
                VC.selectedCoverImageFile = self.coverImageFile
                self.navigationController?.pushViewController(VC, animated: true)
            }
        case .video:
            if let VC = self.storyboard?.instantiateViewController(withIdentifier: "VideoPrankVC") as? VideoPrankVC {
                VC.languageid = selectedLanguageId ?? 1
                VC.selectedCoverImageURL = self.coverImageUrl
                VC.selectedCoverImageName = self.coverimageName
                VC.selectedCoverImageFile = self.coverImageFile
                self.navigationController?.pushViewController(VC, animated: true)
            }
        case .image:
            if let VC = self.storyboard?.instantiateViewController(withIdentifier: "ImagePrankVC") as? ImagePrankVC {
                VC.languageid = selectedLanguageId ?? 1
                VC.selectedCoverImageURL = self.coverImageUrl
                VC.selectedCoverImageName = self.coverimageName
                VC.selectedCoverImageFile = self.coverImageFile
                self.navigationController?.pushViewController(VC, animated: true)
            }
        case .none:
            break
        }
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func languageSelected(_ sender: UIButton) {
        selectLanguage(for: sender)
    }
}
