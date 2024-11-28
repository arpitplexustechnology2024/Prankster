//
//  ShareLinkVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 27/11/24.
//

import UIKit

class ShareLinkVC: UIViewController {
    
    
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var scrollViewView: UIView!
    
    var selectedURL: String?
    var selectedName: String?
    var selectedCoverURL: String?
    var selectedPranktype: String?
    private var viewModel = ShareLinkViewModel()
    
    let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.distribution = .fillProportionally
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        setupScrollView()
        addContentToStackView()
        hideKeyboardTappedAround()
        callCreatePrankAPI()
        if let imageURL = selectedURL, let coverImageURL = selectedCoverURL, let imageName = selectedName {
            print("=== Received Data in Next ViewController ===")
            print("Cover Image URL: \(coverImageURL)")
            print("URL: \(imageURL)")
            print("Name: \(imageName)")
            print("=========================================")
        }
        
    }
    
    func setup() {
        self.shareView.layer.cornerRadius = 15
    }
    
    func setupScrollView() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false
        
        scrollViewView.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: scrollViewView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: scrollViewView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: scrollViewView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: scrollViewView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
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
            label.textColor = .white
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
    
    @objc func viewTapped(_ gesture: UITapGestureRecognizer) {
        guard let tappedView = gesture.view else { return }
        
        let items = [
            "Copy link",
            "Message",
            "Story",
            "Message",
            "Story",
            "Message",
            "More"
        ]
        
        let tappedItem = items[tappedView.tag]
        
        let alert = UIAlertController(title: "View Tapped",
                                      message: "You tapped the \(tappedItem) view",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension ShareLinkVC {
    func callCreatePrankAPI() {
        // Verify all required parameters are available
        guard
            let coverImage = selectedCoverURL,
            let file = selectedURL,
            let name = selectedName,
            let type = selectedPranktype
        else {
            print("Missing required parameters for API call")
            return
        }
        
        viewModel.createPrank(
            coverImage: coverImage,
            type: type,
            name: name,
            file: file
        ) { [weak self] result in
            switch result {
            case .success(let response):
                print("Prank Created Successfully")
                print("Link: \(response.data.link)")
                print("ID: \(response.data.id)")
                print("coverImage: \(response.data.coverImage)")
                print("File: \(response.data.file)")
                print("Name: \(response.data.name)")
                
                // Optional: Handle successful response
                DispatchQueue.main.async {
                    // Update UI or perform additional actions
                }
                
            case .failure(let error):
                print("API Call Failed: \(error)")
                
                // Optional: Show error alert
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Error",
                        message: error.localizedDescription,
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
