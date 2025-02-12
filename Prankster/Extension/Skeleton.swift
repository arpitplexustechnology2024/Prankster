//
//  Skeleton.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

class SkeletonCollectionViewCell: UICollectionViewCell {
    
    private let skeletonBackgroundView = UIView()
    private let ImageView = UIView()
    private let labelImageView = UIView()
    private let label2ImageView = UIView()
    private let buttonImageView = UIView()
    private let gradientLayerImage = CAGradientLayer()
    private let gradientLayerLabel = CAGradientLayer()
    private let gradientLayerLabel2 = CAGradientLayer()
    private let gradientLayerButton = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeleton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeleton()
    }
    
    private func setupSkeleton() {
        
        skeletonBackgroundView.backgroundColor = UIColor.skeletonbg.withAlphaComponent(0.9)
        skeletonBackgroundView.layer.cornerRadius = 12
        skeletonBackgroundView.clipsToBounds = true
        
        skeletonBackgroundView.layer.shadowColor = UIColor.black.cgColor
        skeletonBackgroundView.layer.shadowOpacity = 0.2
        skeletonBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 2)
        skeletonBackgroundView.layer.shadowRadius = 4.0
        skeletonBackgroundView.layer.masksToBounds = false
        contentView.addSubview(skeletonBackgroundView)
        
        ImageView.backgroundColor = UIColor.skeletonsed1.withAlphaComponent(0.5)
        ImageView.clipsToBounds = true
        ImageView.layer.cornerRadius = 12
        contentView.addSubview(ImageView)
        
        labelImageView.backgroundColor = UIColor.skeletonsed1.withAlphaComponent(0.5)
        labelImageView.clipsToBounds = true
        labelImageView.layer.cornerRadius = 10
        contentView.addSubview(labelImageView)
        
        label2ImageView.backgroundColor = UIColor.skeletonsed1.withAlphaComponent(0.5)
        label2ImageView.clipsToBounds = true
        label2ImageView.layer.cornerRadius = 10
        contentView.addSubview(label2ImageView)
        
        buttonImageView.backgroundColor = UIColor.skeletonsed1.withAlphaComponent(0.5)
        buttonImageView.clipsToBounds = true
        buttonImageView.layer.cornerRadius = 12
        contentView.addSubview(buttonImageView)
        
        skeletonBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            skeletonBackgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            skeletonBackgroundView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            skeletonBackgroundView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            skeletonBackgroundView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        ImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            ImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            ImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            ImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            ImageView.widthAnchor.constraint(equalToConstant: 84)
        ])
        
        labelImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 30),
            labelImageView.leadingAnchor.constraint(equalTo: ImageView.trailingAnchor, constant: 8),
            labelImageView.trailingAnchor.constraint(equalTo: buttonImageView.leadingAnchor, constant: -8),
            labelImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        label2ImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label2ImageView.topAnchor.constraint(equalTo: labelImageView.bottomAnchor, constant: 2),
            label2ImageView.leadingAnchor.constraint(equalTo: ImageView.trailingAnchor, constant: 8),
            label2ImageView.trailingAnchor.constraint(equalTo: buttonImageView.leadingAnchor, constant: -8),
            label2ImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        buttonImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            buttonImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            buttonImageView.heightAnchor.constraint(equalToConstant: 50),
            buttonImageView.widthAnchor.constraint(equalToConstant: 50),
            buttonImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        
        setupGradient(for: ImageView, gradientLayer: gradientLayerImage)
        setupGradient(for: labelImageView, gradientLayer: gradientLayerLabel)
        setupGradient(for: label2ImageView, gradientLayer: gradientLayerLabel2)
        setupGradient(for: buttonImageView, gradientLayer: gradientLayerButton)
    }
    
    private func setupGradient(for view: UIView, gradientLayer: CAGradientLayer) {
        gradientLayer.colors = [
            UIColor.skeletonsed1.withAlphaComponent(0.5).cgColor,
            UIColor.skeletonsed2.withAlphaComponent(0.3).cgColor,
            UIColor.skeletonsed1.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = view.bounds
        gradientLayer.add(createShimmerAnimation(), forKey: "shimmer")
        view.layer.addSublayer(gradientLayer)
    }
    
    private func createShimmerAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 0.25]
        animation.toValue = [0.75, 1.0, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        return animation
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayerImage.frame = ImageView.bounds
        gradientLayerLabel.frame = labelImageView.bounds
        gradientLayerLabel2.frame = label2ImageView.bounds
        gradientLayerButton.frame = buttonImageView.bounds
        
        gradientLayerImage.add(createShimmerAnimation(), forKey: "shimmer")
        gradientLayerLabel.add(createShimmerAnimation(), forKey: "shimmer")
        gradientLayerLabel2.add(createShimmerAnimation(), forKey: "shimmer")
        gradientLayerButton.add(createShimmerAnimation(), forKey: "shimmer")
    }
}


class SkeletonBoxCollectionViewCell: UICollectionViewCell {
    
    private let largeImageView = UIView()
    private let gradientLayerLarge = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSkeleton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupSkeleton()
    }
    
    private func setupSkeleton() {
        
        largeImageView.backgroundColor = UIColor.skeletonsed1.withAlphaComponent(0.5)
        largeImageView.clipsToBounds = true
        largeImageView.layer.cornerRadius = 16
        contentView.addSubview(largeImageView)
        
        largeImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            largeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            largeImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            largeImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            largeImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        setupGradient(for: largeImageView, gradientLayer: gradientLayerLarge)
    }
    
    private func setupGradient(for view: UIView, gradientLayer: CAGradientLayer) {
        gradientLayer.colors = [
            UIColor.skeletonsed1.withAlphaComponent(0.5).cgColor,
            UIColor.skeletonsed2.withAlphaComponent(0.3).cgColor,
            UIColor.skeletonsed1.withAlphaComponent(0.5).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.frame = view.bounds
        gradientLayer.add(createShimmerAnimation(), forKey: "shimmer")
        view.layer.addSublayer(gradientLayer)
    }
    
    private func createShimmerAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 0.25]
        animation.toValue = [0.75, 1.0, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        return animation
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayerLarge.frame = largeImageView.bounds
    }
}

class ShimmerView: UIView {
    // MARK: - Properties
    private let gradientLayer = CAGradientLayer()
    private let gradientColorOne = UIColor.skeletonsed1.cgColor
    private let gradientColorTwo = UIColor.skeletonsed2.cgColor
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupShimmerEffect()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupShimmerEffect()
    }
    
    // MARK: - Setup Shimmer Effect
    private func setupShimmerEffect() {
        backgroundColor = .clear
        
        gradientLayer.colors = [gradientColorOne, gradientColorTwo, gradientColorOne]
        gradientLayer.cornerRadius = 8
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.addSublayer(gradientLayer)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 1.0]
        animation.toValue = [0.0, 1.0, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "shimmerAnimation")
    }
}

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
