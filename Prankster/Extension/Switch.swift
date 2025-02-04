//
//  Switch.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 01/02/25.
//

import UIKit

class CustomSwitch: UIControl {

    private var isOn = false
    private let backgroundView = UIView()
    private let gradientLayer = CAGradientLayer()
    private let circleView = UIView()
    private let leftIconImageView = UIImageView()
    private let rightIconImageView = UIImageView()
    
    private let switchWidth: CGFloat = 137
    private let switchHeight: CGFloat = 60
    private let circleSize: CGFloat = 50
    private let circleImageSize: CGFloat = 40

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        self.frame = CGRect(x: 0, y: 0, width: switchWidth, height: switchHeight)
        self.layer.cornerRadius = switchHeight / 2
        self.clipsToBounds = true
        
        // Setup background color (replacing gradient)
        backgroundView.frame = self.bounds
        backgroundView.backgroundColor = UIColor(red: 62/255, green: 62/255, blue: 62/255, alpha: 1) // #3E3E3E
        backgroundView.layer.cornerRadius = switchHeight / 2
        addSubview(backgroundView)
        
        circleView.frame = CGRect(x: 5, y: 5, width: circleSize, height: circleSize)
        circleView.layer.cornerRadius = circleSize / 2
        circleView.backgroundColor = .white
        addSubview(circleView)
        
        leftIconImageView.frame = CGRect(x: 10, y: 10, width: circleImageSize, height: circleImageSize)
        leftIconImageView.image = UIImage(named: "instagramIcon")
        leftIconImageView.contentMode = .scaleAspectFit
        addSubview(leftIconImageView)
        
        rightIconImageView.frame = CGRect(x: switchWidth - circleImageSize - 9, y: 11, width: circleImageSize - 2, height: circleImageSize - 2)
        rightIconImageView.image = UIImage(named: "snapchatIcon")
        rightIconImageView.contentMode = .scaleAspectFit
        addSubview(rightIconImageView)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleSwitch))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func toggleSwitch() {
        isOn.toggle()
        let newCirclePosition = isOn ? switchWidth - circleSize - 5 : 5
        UIView.animate(withDuration: 0.3) {
            self.circleView.frame.origin.x = newCirclePosition
        }
        sendActions(for: .valueChanged)
    }
    
    func setOn(_ on: Bool, animated: Bool) {
        isOn = on
        let newCirclePosition = isOn ? switchWidth - circleSize - 5 : 5
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.circleView.frame.origin.x = newCirclePosition
            }
        } else {
            circleView.frame.origin.x = newCirclePosition
        }
    }
    
    var isSwitchOn: Bool {
        return isOn
    }
}
