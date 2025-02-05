//
//  AudioPopupVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 30/01/25.
//


import UIKit
import MediaPlayer
import AVFoundation

class AudioPopupVC: UIViewController {
    
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var recorderButton: UIButton!
    @IBOutlet weak var mediaPlayerButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    typealias ButtonCallback = () -> Void
    var recorderCallback: ButtonCallback?
    var mediaplayerCallback: ButtonCallback?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.layer.cornerRadius = 12
        self.cancelButton.layer.borderWidth = 1
        self.cancelButton.layer.borderColor = UIColor.lightGray.cgColor
        self.bgView.layer.cornerRadius = 16
    }
    
    @IBAction func btnRecorderTapped(_ sender: UIButton) {
        requestMicrophonePermission()
    }
    
    @IBAction func btnmediaPlayerTapped(_ sender: UIButton) {
        self.openMediaPlayer()
    }
    
    private func requestMicrophonePermission() {
        switch AVAudioSession.sharedInstance().recordPermission {
            
        case .granted:
            dismiss(animated: true) {
                self.recorderCallback?()
            }
            
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.dismiss(animated: true) {
                            self?.recorderCallback?()
                        }
                    } else {
                        self?.showMicrophonePermissionSnackbar()
                    }
                }
            }
            
        case .denied:
            showMicrophonePermissionSnackbar()
            
        @unknown default:
            break
        }
    }
    
    private func openMediaPlayer() {
        switch MPMediaLibrary.authorizationStatus() {
            
        case .authorized:
            dismiss(animated: true) {
                self.mediaplayerCallback?()
            }
            
        case .notDetermined:
            MPMediaLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.dismiss(animated: true) {
                            self?.mediaplayerCallback?()
                        }
                    } else {
                        self?.showMediaLibraryPermissionSnackbar()
                    }
                }
            }
        case .denied, .restricted:
            showMediaLibraryPermissionSnackbar()
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Show permission snackbars
    private func showMicrophonePermissionSnackbar() {
        let localizedMessage = "We need access to your microphone to record audio."
        let settingsText = "Settings"
        
        let snackbar = Snackbar(message: localizedMessage, backgroundColor: .snackbar)
        snackbar.setAction(title: settingsText) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        snackbar.show(in: self.view, duration: 5.0)
    }
    
    private func showMediaLibraryPermissionSnackbar() {
        let localizedMessage = "We need access to your media library to set the audio file."
        let settingsText = "Settings"
        
        let snackbar = Snackbar(message: localizedMessage, backgroundColor: .snackbar)
        snackbar.setAction(title: settingsText) {
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)")
                })
            }
        }
        snackbar.show(in: self.view, duration: 5.0)
    }
    
    @IBAction func btncanceltapped(_ sender: UIButton) {
        dismiss(animated: true)
    }
}
