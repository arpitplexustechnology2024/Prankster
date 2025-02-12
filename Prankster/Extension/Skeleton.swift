//
//  Skeleton.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import  UIKit

class SkeletonShareLoadingView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let firstSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let secondSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let thirdSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .background
        
        addSubview(containerView)
        containerView.addSubview(firstSkeletonView)
        containerView.addSubview(secondSkeletonView)
        containerView.addSubview(thirdSkeletonView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            thirdSkeletonView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -30),
            thirdSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            thirdSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            thirdSkeletonView.heightAnchor.constraint(equalToConstant: 75),
            
            secondSkeletonView.bottomAnchor.constraint(equalTo: thirdSkeletonView.topAnchor, constant: -16),
            secondSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            secondSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            secondSkeletonView.heightAnchor.constraint(equalToConstant: 75),
            
            firstSkeletonView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            firstSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            firstSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            firstSkeletonView.bottomAnchor.constraint(equalTo: secondSkeletonView.topAnchor, constant: -16)
        ])
    }
    
    
    
    
    func startAnimating() {
        [firstSkeletonView, secondSkeletonView, thirdSkeletonView].forEach { $0.startShimmerAnimation() }
    }
    
    func stopAnimating() {
        [firstSkeletonView, secondSkeletonView, thirdSkeletonView].forEach { $0.stopShimmerAnimation() }
    }
}

class GradientSkeletonView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    private let gradientColorOne = UIColor(white: 0.14, alpha: 1.0).cgColor
    private let gradientColorTwo = UIColor(white: 0.22, alpha: 1.0).cgColor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShimmerEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShimmerEffect()
    }
    
    private func setupShimmerEffect() {
        backgroundColor = .clear
        
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorOne]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = layer.cornerRadius
    }
    
    func startShimmerAnimation() {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 1.0]
        animation.toValue = [0.0, 1.0, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmerAnimation")
    }
    
    func stopShimmerAnimation() {
        gradientLayer.removeAllAnimations()
    }
}

class SkeletonMoreappLoadingView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let firstSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let secondSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let thirdSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fourthSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let fivethSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let sixthSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .background
        
        addSubview(containerView)
        containerView.addSubview(firstSkeletonView)
        containerView.addSubview(secondSkeletonView)
        containerView.addSubview(thirdSkeletonView)
        containerView.addSubview(fourthSkeletonView)
        containerView.addSubview(fivethSkeletonView)
        containerView.addSubview(sixthSkeletonView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            firstSkeletonView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            firstSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            firstSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            firstSkeletonView.heightAnchor.constraint(equalToConstant: 100),
            
            secondSkeletonView.topAnchor.constraint(equalTo: firstSkeletonView.bottomAnchor, constant: 16),
            secondSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            secondSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            secondSkeletonView.heightAnchor.constraint(equalToConstant: 100),
            
            thirdSkeletonView.topAnchor.constraint(equalTo: secondSkeletonView.bottomAnchor, constant: 16),
            thirdSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            thirdSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            thirdSkeletonView.heightAnchor.constraint(equalToConstant: 100),
            
            fourthSkeletonView.topAnchor.constraint(equalTo: thirdSkeletonView.bottomAnchor, constant: 16),
            fourthSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            fourthSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            fourthSkeletonView.heightAnchor.constraint(equalToConstant: 100),
            
            fivethSkeletonView.topAnchor.constraint(equalTo: fourthSkeletonView.bottomAnchor, constant: 16),
            fivethSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            fivethSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            fivethSkeletonView.heightAnchor.constraint(equalToConstant: 100),
            
            sixthSkeletonView.topAnchor.constraint(equalTo: fivethSkeletonView.bottomAnchor, constant: 16),
            sixthSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            sixthSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            sixthSkeletonView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    func startAnimating() {
        [firstSkeletonView, secondSkeletonView, thirdSkeletonView, fourthSkeletonView, fivethSkeletonView, sixthSkeletonView].forEach { $0.startShimmerAnimation() }
    }
    
    func stopAnimating() {
        [firstSkeletonView, secondSkeletonView, thirdSkeletonView, fourthSkeletonView, fivethSkeletonView, sixthSkeletonView].forEach { $0.stopShimmerAnimation() }
    }
}


class SkeletonDataLoadingView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let topSkeletonView: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Bottom 4 horizontal views
    private let bottomSkeletonView1: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomSkeletonView2: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomSkeletonView3: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomSkeletonView4: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .background
        
        addSubview(containerView)
        containerView.addSubview(topSkeletonView)
        containerView.addSubview(bottomSkeletonView1)
        containerView.addSubview(bottomSkeletonView2)
        containerView.addSubview(bottomSkeletonView3)
        containerView.addSubview(bottomSkeletonView4)
        
        let spacing: CGFloat = 16
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            topSkeletonView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            topSkeletonView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            topSkeletonView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            bottomSkeletonView1.heightAnchor.constraint(equalToConstant: 90),
            bottomSkeletonView2.heightAnchor.constraint(equalToConstant: 90),
            bottomSkeletonView3.heightAnchor.constraint(equalToConstant: 90),
            bottomSkeletonView4.heightAnchor.constraint(equalToConstant: 90),
            
            bottomSkeletonView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            bottomSkeletonView2.leadingAnchor.constraint(equalTo: bottomSkeletonView1.trailingAnchor, constant: 8),
            bottomSkeletonView3.leadingAnchor.constraint(equalTo: bottomSkeletonView2.trailingAnchor, constant: 8),
            bottomSkeletonView4.leadingAnchor.constraint(equalTo: bottomSkeletonView3.trailingAnchor, constant: 8),
            bottomSkeletonView4.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            
            bottomSkeletonView1.widthAnchor.constraint(equalTo: bottomSkeletonView2.widthAnchor),
            bottomSkeletonView2.widthAnchor.constraint(equalTo: bottomSkeletonView3.widthAnchor),
            bottomSkeletonView3.widthAnchor.constraint(equalTo: bottomSkeletonView4.widthAnchor),
            
            bottomSkeletonView1.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            bottomSkeletonView2.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            bottomSkeletonView3.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            bottomSkeletonView4.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),

            topSkeletonView.bottomAnchor.constraint(equalTo: bottomSkeletonView1.topAnchor, constant: -8)
        ])
    }
    
    func startAnimating() {
        [topSkeletonView, bottomSkeletonView1, bottomSkeletonView2, bottomSkeletonView3, bottomSkeletonView4].forEach { $0.startShimmerAnimation() }
    }
    
    func stopAnimating() {
        [topSkeletonView, bottomSkeletonView1, bottomSkeletonView2, bottomSkeletonView3, bottomSkeletonView4].forEach { $0.stopShimmerAnimation() }
    }
}

class SkeletonCoverLoadingView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .background
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Top pair of views
    private let topSkeletonView1: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let topSkeletonView2: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Middle pair of views
    private let middleSkeletonView1: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let middleSkeletonView2: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Bottom pair of views
    private let bottomSkeletonView1: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let bottomSkeletonView2: GradientSkeletonView = {
        let view = GradientSkeletonView()
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .background
        
        addSubview(containerView)
        containerView.addSubview(topSkeletonView1)
        containerView.addSubview(topSkeletonView2)
        containerView.addSubview(middleSkeletonView1)
        containerView.addSubview(middleSkeletonView2)
        containerView.addSubview(bottomSkeletonView1)
        containerView.addSubview(bottomSkeletonView2)
        
        let spacing: CGFloat = 16
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            topSkeletonView1.topAnchor.constraint(equalTo: containerView.topAnchor, constant: spacing),
            topSkeletonView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            topSkeletonView1.heightAnchor.constraint(equalToConstant: 180),
            
            topSkeletonView2.topAnchor.constraint(equalTo: containerView.topAnchor, constant: spacing),
            topSkeletonView2.leadingAnchor.constraint(equalTo: topSkeletonView1.trailingAnchor, constant: spacing),
            topSkeletonView2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            topSkeletonView2.heightAnchor.constraint(equalToConstant: 180),
            topSkeletonView2.widthAnchor.constraint(equalTo: topSkeletonView1.widthAnchor),
            
            middleSkeletonView1.topAnchor.constraint(equalTo: topSkeletonView1.bottomAnchor, constant: spacing),
            middleSkeletonView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            middleSkeletonView1.heightAnchor.constraint(equalToConstant: 180),
            
            middleSkeletonView2.topAnchor.constraint(equalTo: topSkeletonView2.bottomAnchor, constant: spacing),
            middleSkeletonView2.leadingAnchor.constraint(equalTo: middleSkeletonView1.trailingAnchor, constant: spacing),
            middleSkeletonView2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            middleSkeletonView2.heightAnchor.constraint(equalToConstant: 180),
            middleSkeletonView2.widthAnchor.constraint(equalTo: middleSkeletonView1.widthAnchor),
            
            bottomSkeletonView1.topAnchor.constraint(equalTo: middleSkeletonView1.bottomAnchor, constant: spacing),
            bottomSkeletonView1.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: spacing),
            bottomSkeletonView1.heightAnchor.constraint(equalToConstant: 180),
            
            bottomSkeletonView2.topAnchor.constraint(equalTo: middleSkeletonView2.bottomAnchor, constant: spacing),
            bottomSkeletonView2.leadingAnchor.constraint(equalTo: bottomSkeletonView1.trailingAnchor, constant: spacing),
            bottomSkeletonView2.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -spacing),
            bottomSkeletonView2.heightAnchor.constraint(equalToConstant: 180),
            bottomSkeletonView2.widthAnchor.constraint(equalTo: bottomSkeletonView1.widthAnchor),
        ])
    }
    
    func startAnimating() {
        [topSkeletonView1, topSkeletonView2,
         middleSkeletonView1, middleSkeletonView2,
         bottomSkeletonView1, bottomSkeletonView2].forEach { $0.startShimmerAnimation() }
    }
    
    func stopAnimating() {
        [topSkeletonView1, topSkeletonView2,
         middleSkeletonView1, middleSkeletonView2,
         bottomSkeletonView1, bottomSkeletonView2].forEach { $0.stopShimmerAnimation() }
    }
}
