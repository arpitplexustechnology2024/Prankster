//
//  ViewController.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 05/02/25.
//

import UIKit
import Lottie

class ViewController: UIViewController {
    
    let animationView = LottieAnimationView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animationView.frame = CGRect(x: 50, y: 100, width: 300, height: 300)
        animationView.contentMode = .scaleAspectFit
        view.addSubview(animationView)
        
        loadLottieAnimation()
    }
    
    func loadLottieAnimation() {
        guard let url = URL(string: "https://pslink.world/api/public/images/cover.json") else { return }
        
        // JSON Data Download
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                DispatchQueue.main.async {
                    do {
                        let animation = try LottieAnimation.from(data: data)
                        self.animationView.animation = animation
                        self.animationView.loopMode = .loop
                        self.animationView.play()
                    } catch {
                        print("❌ Lottie JSON Parse Error:", error.localizedDescription)
                    }
                }
            }
        }.resume()
    }
}

