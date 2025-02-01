//
//  ChipButton.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 24/01/25.
//

import UIKit

class CoverChipButton: UIButton {
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
    private var chips: [CoverChipButton] = []
    private var selectedChip: CoverChipButton?
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
        stackView.distribution = .fillProportionally
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.heightAnchor.constraint(equalTo: heightAnchor)
        ])
    }
    
    private func setupChips() {
        let titles = ["Add cover image 📸", "Rational cover image 😂"]
        
        for title in titles {
            let chip = CoverChipButton()
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
    
    @objc private func chipTapped(_ sender: CoverChipButton) {
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


import UIKit

class AudioChipButton: UIButton {
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

class AudioChipSelector: UIView {
    private var containerStackView: UIStackView!
    private var fixedChip: AudioChipButton!
    private var scrollView: UIScrollView!
    private var scrollableStackView: UIStackView!
    private var chips: [AudioChipButton] = []
    private var selectedChip: AudioChipButton?
    private var isSearchBarActive = false
    var onSelectionChanged: ((String) -> Void)?
    
    private var categoryIDs: [Int] = [0, 1, 2, 3, 4, 5, 6] // First is 0 for custom data
    var onCategorySelected: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupChips()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        setupChips()
    }
    
    private func setupLayout() {
        // Main horizontal stack view to hold fixed chip and scroll view
        containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 12
        containerStackView.alignment = .center
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        
        // Setup fixed chip
        fixedChip = AudioChipButton()
        fixedChip.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup scroll view for remaining chips
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup stack view inside scroll view
        scrollableStackView = UIStackView()
        scrollableStackView.axis = .horizontal
        scrollableStackView.spacing = 8
        scrollableStackView.alignment = .center
        scrollableStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views to hierarchy
        containerStackView.addArrangedSubview(fixedChip)
        containerStackView.addArrangedSubview(scrollView)
        scrollView.addSubview(scrollableStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container stack view constraints
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Scrollable stack view constraints
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    func selectDefaultChip() {
        // Select the first chip (Add Audio Prank)
        fixedChip.isChipSelected = true
        selectedChip = fixedChip
        
        // Notify about default selection
        onSelectionChanged?(fixedChip.titleLabel?.text ?? "")
        onCategorySelected?(0)
    }
    
    private func setupChips() {
        let titles = ["Add Audio Prank 🎧", "Tranding sound", "Nonveg sound", "Hot sound", "Funny sound", "Horro sound", "Celebrity sound"]
        
        // Setup fixed chip (custom data chip)
        fixedChip.setTitle(titles[0], for: .normal)
        fixedChip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        fixedChip.tag = 0  // Set tag for identifying category
        fixedChip.isChipSelected = true
        selectedChip = fixedChip
        
        // Setup scrollable chips with corresponding category IDs
        for (index, title) in titles.dropFirst().enumerated() {
            let chip = AudioChipButton()
            chip.setTitle(title, for: .normal)
            chip.tag = categoryIDs[index + 1]  // Set tag as category ID
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            scrollableStackView.addArrangedSubview(chip)
            chips.append(chip)
        }
    }
    
    @objc private func chipTapped(_ sender: AudioChipButton) {
        guard !isSearchBarActive else { return }
        
        selectedChip?.isChipSelected = false
        sender.isChipSelected = true
        selectedChip = sender
        
        let selectedType = sender.titleLabel?.text ?? ""
        onSelectionChanged?(selectedType)
        
        // Call new callback with category ID
        onCategorySelected?(sender.tag)
    }
    
    func setSearchBarActiveState(_ active: Bool) {
        isSearchBarActive = active
    }
}


import UIKit

class ImageChipButton: UIButton {
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

class ImageChipSelector: UIView {
    private var containerStackView: UIStackView!
    private var fixedChip: ImageChipButton!
    private var scrollView: UIScrollView!
    private var scrollableStackView: UIStackView!
    private var chips: [ImageChipButton] = []
    private var selectedChip: ImageChipButton?
    private var isSearchBarActive = false
    var onSelectionChanged: ((String) -> Void)?
    
    private var categoryIDs: [Int] = [0, 1, 2, 3, 4, 5, 6] // First is 0 for custom data
    var onCategorySelected: ((Int) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupChips()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        setupChips()
    }
    
    private func setupLayout() {
        // Main horizontal stack view to hold fixed chip and scroll view
        containerStackView = UIStackView()
        containerStackView.axis = .horizontal
        containerStackView.spacing = 12
        containerStackView.alignment = .center
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerStackView)
        
        // Setup fixed chip
        fixedChip = ImageChipButton()
        fixedChip.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup scroll view for remaining chips
        scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        // Setup stack view inside scroll view
        scrollableStackView = UIStackView()
        scrollableStackView.axis = .horizontal
        scrollableStackView.spacing = 8
        scrollableStackView.alignment = .center
        scrollableStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Add views to hierarchy
        containerStackView.addArrangedSubview(fixedChip)
        containerStackView.addArrangedSubview(scrollView)
        scrollView.addSubview(scrollableStackView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Container stack view constraints
            containerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 5),
            containerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerStackView.topAnchor.constraint(equalTo: topAnchor),
            containerStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Scrollable stack view constraints
            scrollableStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            scrollableStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            scrollableStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            scrollableStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            scrollableStackView.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    func selectDefaultChip() {
        // Select the first chip (Add Audio Prank)
        fixedChip.isChipSelected = true
        selectedChip = fixedChip
        
        // Notify about default selection
        onSelectionChanged?(fixedChip.titleLabel?.text ?? "")
        onCategorySelected?(0)
    }
    
    private func setupChips() {
        let titles = ["Add image Prank 🏞️", "Tranding image", "Nonveg image", "Hot image", "Funny image", "Horro image", "Celebrity image"]
        
        // Setup fixed chip (custom data chip)
        fixedChip.setTitle(titles[0], for: .normal)
        fixedChip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
        fixedChip.tag = 0  // Set tag for identifying category
        fixedChip.isChipSelected = true
        selectedChip = fixedChip
        
        // Setup scrollable chips with corresponding category IDs
        for (index, title) in titles.dropFirst().enumerated() {
            let chip = ImageChipButton()
            chip.setTitle(title, for: .normal)
            chip.tag = categoryIDs[index + 1]  // Set tag as category ID
            chip.addTarget(self, action: #selector(chipTapped(_:)), for: .touchUpInside)
            scrollableStackView.addArrangedSubview(chip)
            chips.append(chip)
        }
    }
    
    @objc private func chipTapped(_ sender: ImageChipButton) {
        guard !isSearchBarActive else { return }
        
        selectedChip?.isChipSelected = false
        sender.isChipSelected = true
        selectedChip = sender
        
        let selectedType = sender.titleLabel?.text ?? ""
        onSelectionChanged?(selectedType)
        
        // Call new callback with category ID
        onCategorySelected?(sender.tag)
    }
    
    func setSearchBarActiveState(_ active: Bool) {
        isSearchBarActive = active
    }
}
