//
//  ShareLinkPopup.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 01/12/24.
//

import UIKit

class ShareLinkPopup: UIViewController {
    
    @IBOutlet weak var shareLinkPopup: UIView!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var shareView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.shareLinkPopup.layer.cornerRadius = 18
        self.imageView.layer.cornerRadius = 18
        self.setupScrollView()
        self.addContentToStackView()
    }
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 0
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - setupScrollView
    func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        shareView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: shareView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: shareView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: shareView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: shareView.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    // MARK: - addContentToStackView
    func addContentToStackView() {
        let items = [
            (icon: UIImage(named: "copylink"), title: "Copy link"),
            (icon: UIImage(named: "instagram"), title: "Message"),
            (icon: UIImage(named: "instagram"), title: "Story"),
            (icon: UIImage(named: "snapchat"), title: "Message"),
            (icon: UIImage(named: "snapchat"), title: "Story"),
            (icon: UIImage(named: "whatsapp"), title: "Message"),
            (icon: UIImage(named: "moreShare"), title: "More")
        ]
        
        for (index, item) in items.enumerated() {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.tag = index
            
            let verticalStackView = UIStackView()
            verticalStackView.axis = .vertical
            verticalStackView.alignment = .center
            verticalStackView.spacing = 5
            verticalStackView.translatesAutoresizingMaskIntoConstraints = false
            
            let imageView = UIImageView(image: item.icon)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = .white
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = item.title
            label.textColor = .black
            label.font = UIFont.systemFont(ofSize: 12)
            label.translatesAutoresizingMaskIntoConstraints = false
            verticalStackView.addArrangedSubview(imageView)
            verticalStackView.addArrangedSubview(label)
            containerView.addSubview(verticalStackView)
            
            NSLayoutConstraint.activate([
                imageView.widthAnchor.constraint(equalToConstant: 50),
                imageView.heightAnchor.constraint(equalToConstant: 50)
            ])
            NSLayoutConstraint.activate([
                verticalStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                verticalStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
            ])
            
            containerView.widthAnchor.constraint(equalToConstant: 78).isActive = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped(_:)))
            containerView.addGestureRecognizer(tapGesture)
            containerView.isUserInteractionEnabled = true
            
            
            stackView.addArrangedSubview(containerView)
        }
    }
    
    // MARK: - viewTapped
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        
        switch tappedView.tag {
        case 0: break // Copy link

        case 1: break  // Instagram Message
            
        case 2: break  // Instagram Story
  
        case 3: break  // Snapchat Message
            
        case 4: break   // Snapchat Story

        case 5: break // WhatsApp Message

        case 6: break // More

        default:
            break
        }
    }
    
    @IBAction func btnShareLinkTapped(_ sender: UIButton) {
        
    }
}
