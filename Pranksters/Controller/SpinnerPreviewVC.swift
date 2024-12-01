//
//  SpinnerPreviewVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 30/11/24.
//

import UIKit
import Alamofire
import AVFAudio
import AVFoundation

class SpinnerPreviewVC: UIViewController {
    
    @IBOutlet weak var congratulations: UIImageView!
    @IBOutlet weak var prankImageView: UIImageView!
    @IBOutlet weak var playPauseImageView: UIImageView!
    @IBOutlet weak var unlockLabel: UILabel!
    
    var coverImage: String?
    var file: String?
    var type: String?
    var name: String?
    var link: String?
    private var audioPlayer: AVAudioPlayer?
    private var videoPlayer: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var isPlaying = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.prankImageView.layer.cornerRadius = 18
        if let coverImageUrl = self.coverImage {
            self.loadImage(from: coverImageUrl, into: self.prankImageView)
        }
        
        self.playPauseImageView.image = UIImage(named: "PlayButton")
        self.playPauseImageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.prankImageView.isUserInteractionEnabled = true
        self.prankImageView.addGestureRecognizer(tapGesture)
        
        let playPauseTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.togglePlayPause))
        self.playPauseImageView.isUserInteractionEnabled = true
        self.playPauseImageView.addGestureRecognizer(playPauseTapGesture)
    }
    
    private func loadImage(from urlString: String, into imageView: UIImageView) {
        AF.request(urlString).response { response in
            switch response.result {
            case .success(let data):
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                }
            case .failure(let error):
                print("Image download error: \(error)")
                DispatchQueue.main.async {
                    imageView.image = UIImage(named: "placeholder")
                }
            }
        }
    }
    
    private func loadMediaFile(urlString: String, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -2, userInfo: nil)))
                return
            }
            
            completion(.success(data))
        }.resume()
    }
    
    private func setupAudioPlayer(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            audioPlayer?.delegate = self
            
            DispatchQueue.main.async {
                self.prankImageView.image = UIImage(named: "audioPrankImage")
                self.playPauseImageView.isHidden = true
            }
        } catch {
            print("Error setting up audio player: \(error)")
            isPlaying = false
        }
    }
    
    private func setupVideoPlayer(data: Data) {
        do {
            let temporaryDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let temporaryFileURL = temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
            
            try data.write(to: temporaryFileURL)
            
            videoPlayer = AVPlayer(url: temporaryFileURL)
            playerLayer = AVPlayerLayer(player: videoPlayer)
            playerLayer?.videoGravity = .resizeAspectFill
            playerLayer?.frame = prankImageView.bounds
            
            if let playerLayer = playerLayer {
                prankImageView.layer.addSublayer(playerLayer)
            }
            
            videoPlayer?.play()
            
            DispatchQueue.main.async {
                self.playPauseImageView.isHidden = true
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(self.videoDidFinishPlaying),
                    name: .AVPlayerItemDidPlayToEndTime,
                    object: self.videoPlayer?.currentItem
                )
            }
        } catch {
            print("Error setting up video player: \(error)")
            isPlaying = false
        }
    }
    
    @objc private func togglePlayPause() {
        isPlaying.toggle()
        
        guard let prankDataUrl = file else { return }
        
        if type == "audio" {
            if isPlaying {
                loadMediaFile(urlString: prankDataUrl) { [weak self] result in
                    switch result {
                    case .success(let audioData):
                        DispatchQueue.main.async {
                            self?.setupAudioPlayer(data: audioData)
                        }
                    case .failure(let error):
                        print("Audio loading error: \(error)")
                        self?.isPlaying = false
                    }
                }
            } else {
                audioPlayer?.pause()
                prankImageView.image = UIImage(named: "audioPrankImage")
                playPauseImageView.image = UIImage(named: "PlayButton")
                playPauseImageView.isHidden = false
            }
        } else if type == "video" {
            if isPlaying {
                loadMediaFile(urlString: prankDataUrl) { [weak self] result in
                    switch result {
                    case .success(let videoData):
                        DispatchQueue.main.async {
                            self?.setupVideoPlayer(data: videoData)
                        }
                    case .failure(let error):
                        print("Video loading error: \(error)")
                        self?.isPlaying = false
                    }
                }
            } else {
                videoPlayer?.pause()
                playPauseImageView.image = UIImage(named: "PlayButton")
                playPauseImageView.isHidden = false
            }
        } else {
            if isPlaying {
                loadImage(from: prankDataUrl, into: prankImageView)
                playPauseImageView.isHidden = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [self] in
                    if let coverImageUrl = self.coverImage {
                        self.loadImage(from: coverImageUrl, into: self.prankImageView)
                    }
                    playPauseImageView.image = UIImage(named: "PlayButton")
                    playPauseImageView.isHidden = false
                    isPlaying = false
                }
            }
        }
    }
    
    @objc private func videoDidFinishPlaying() {
        DispatchQueue.main.async {
            self.videoPlayer?.seek(to: .zero)
            self.videoPlayer?.pause()
            self.isPlaying = false
            if let coverImageUrl = self.coverImage {
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
            }
            self.playerLayer?.removeFromSuperlayer()
            self.playerLayer = nil
            self.videoPlayer = nil
            self.playPauseImageView.image = UIImage(named: "PlayButton")
            self.playPauseImageView.isHidden = false
            NotificationCenter.default.removeObserver(
                self,
                name: .AVPlayerItemDidPlayToEndTime,
                object: nil
            )
        }
    }
    
    @IBAction func btnDoneTapped(_ sender: UIButton) {
        self.dismiss(animated: true)
    }

    @IBAction func btnShareTapped(_ sender: UIButton) {
        // Implement share functionality if needed
    }
}

extension SpinnerPreviewVC: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlaying = false
            if let coverImageUrl = self.coverImage {
                self.loadImage(from: coverImageUrl, into: self.prankImageView)
            }
            self.playPauseImageView.image = UIImage(named: "PlayButton")
            self.playPauseImageView.isHidden = false
            self.audioPlayer = nil
        }
    }
}
