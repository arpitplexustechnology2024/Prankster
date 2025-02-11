//
//  TimeCountVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 10/02/25.
//

import UIKit

class TimeCountVC: UIViewController {
    
    @IBOutlet var countViews: [UIView]!
    
    @IBOutlet weak var hourFirstCount: UILabel!
    @IBOutlet weak var hourSecoundCount: UILabel!
    
    @IBOutlet weak var minitFirstCount: UILabel!
    @IBOutlet weak var minitSecoundCount: UILabel!
    
    @IBOutlet weak var secFirstCount: UILabel!
    @IBOutlet weak var secSecoundCount: UILabel!
    
    var timer: Timer?
    var nextSpinTime: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for views in countViews {
            views.layer.cornerRadius = 10
        }
        startTimer()
    }
    
    func updateTimeLabels() {
        guard let nextSpinTime = nextSpinTime else { return }
        
        let remainingTime = nextSpinTime.timeIntervalSinceNow
        if remainingTime <= 0 {
            timer?.invalidate()
            self.dismiss(animated: true)
            return
        }
        
        let hours = Int(remainingTime) / 3600
        let minutes = (Int(remainingTime) % 3600) / 60
        let seconds = Int(remainingTime) % 60
        
        let hoursStr = String(format: "%02d", hours)
        let minutesStr = String(format: "%02d", minutes)
        let secondsStr = String(format: "%02d", seconds)
        
        hourFirstCount?.text = String(hoursStr.prefix(1))
        hourSecoundCount?.text = String(hoursStr.suffix(1))
        
        minitFirstCount?.text = String(minutesStr.prefix(1))
        minitSecoundCount?.text = String(minutesStr.suffix(1))
        
        secFirstCount?.text = String(secondsStr.prefix(1))
        secSecoundCount?.text = String(secondsStr.suffix(1))
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimeLabels()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}
