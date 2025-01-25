//
//  ChipButton.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 24/01/25.
//

import UIKit

class ChipButton: UIButton {
    var isChipSelected: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupButton()
    }
    
    private func setupButton() {
        layer.cornerRadius = 8
        titleLabel?.font = UIFont(name: "Avenir-Medium", size: 14)
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isChipSelected {
            backgroundColor = .white
            setTitleColor(UIColor.black, for: .normal)
        } else {
            backgroundColor = #colorLiteral(red: 0.1529411765, green: 0.1529411765, blue: 0.1529411765, alpha: 1)
            setTitleColor(UIColor.white, for: .normal)
        }
    }
}

// MARK: - ChipSelectorView Class
class ChipSelectorView: UIView {
    private var stackView: UIStackView!
    private var chips: [ChipButton] = []
    private var selectedChip: ChipButton?
    private var selectedChipTitle: String = "Add cover image 📸"
    var onSelectionChanged: ((String) -> Void)?
    private var isSearchBarActive = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
        setupChips()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
        setupChips()
    }
    
    private func setupStackView() {
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
    
    private func setupChips() {
        let titles = ["Add cover image 📸", "Realistic cover image 😂"]
        
        for title in titles {
            let chip = ChipButton()
            chip.setTitle(title, for: .normal)
            chip.titleLabel?.numberOfLines = 2
            chip.titleLabel?.textAlignment = .center
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            stackView.addArrangedSubview(chip)
            chips.append(chip)
            
            if title == "Add cover image 📸" {
                chip.isChipSelected = true
                selectedChip = chip
                onSelectionChanged?(title)
            }
        }
    }
    
    func getSelectedChipTitle() -> String {
        return selectedChip?.titleLabel?.text ?? ""
    }
    
    @objc private func chipTapped(_ sender: ChipButton) {
        guard !isSearchBarActive else { return }
        
        selectedChip?.isChipSelected = false
        sender.isChipSelected = true
        selectedChip = sender
        
        let selectedType = sender.titleLabel?.text ?? ""
        onSelectionChanged?(selectedType)
    }
    
    func setSearchBarActiveState(_ active: Bool) {
        isSearchBarActive = active
    }
}
