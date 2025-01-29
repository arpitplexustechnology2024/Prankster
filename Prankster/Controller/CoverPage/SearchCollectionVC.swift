//
//  SearchCollectionVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import UIKit

class SearchCollectionVC: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var suggestionCollectionView: UICollectionView!
    
    @IBOutlet weak var searchBarView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        
        // Initial setup: Hide certain elements
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        searchMainView.isHidden = true
        searchMainViewHeightConstarints.constant = 0
        
        // Set the corner radius initially
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        
        // Configure the collection view layout for horizontal scrolling
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal  // Horizontal scrolling
        layout.minimumInteritemSpacing = 10  // Space between items
        layout.minimumLineSpacing = 10      // Space between rows
        
        // Add padding to the left side of the collection view
        layout.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        
        suggestionCollectionView.setCollectionViewLayout(layout, animated: true)
        
        // Set CollectionView delegate and datasource
        suggestionCollectionView.delegate = self
        suggestionCollectionView.dataSource = self
        
        // Register the custom UICollectionViewCell class or Nib
        suggestionCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "SuggestionCell")
        
        // Add target for searchBar tap
        searchBar.addTarget(self, action: #selector(searchBarTapped(_:)), for: .editingDidBegin)
    }

    @objc func searchBarTapped(_ sender: UITextField) {
        // Show the hidden UI elements
        searchMainView.isHidden = false
        popularLabel.isHidden = false
        suggestionCollectionView.isHidden = false
        cancelButton.isHidden = false
        
        searchMainViewHeightConstarints.constant = 90
        
        // Set corner radius for searchBarView (top corners)
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        // Set corner radius for searchMainView (bottom corners)
        searchMainView.layer.cornerRadius = 10
        searchMainView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        // Animate the changes
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }

    @IBAction func btncancelSearchTapped(_ sender: UIButton) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        cancelButton.isHidden = true
        
        // Restore corner radius when cancel is tapped
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

extension SearchCollectionVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    // CollectionView DataSource methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10  // Adjust the number of items as per your data
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        // Dequeue cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SuggestionCell", for: indexPath)
        
        // Set text (remove image)
        let label = UILabel(frame: cell.contentView.bounds)
        label.text = "Item \(indexPath.row + 1)"
        label.textColor = .black // Set text color
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16)
        
        // Add label to cell content view
        cell.contentView.subviews.forEach { $0.removeFromSuperview() } // Remove old content
        cell.contentView.addSubview(label)
        
        // Customize cell appearance
        cell.backgroundColor = .lightGray  // Set light gray background
        cell.layer.cornerRadius = 10  // Set corner radius
        
        return cell
    }

    // Handle the selection of a cell
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Handle the selection, similar to your table view didSelectRowAt method
        let selectedItem = "Item \(indexPath.row + 1)"
        searchBar.text = selectedItem
        
        searchBar.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        
        // Reset corner radius when a suggestion is selected
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    // Implement delegate method to dynamically adjust item size based on text
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Calculate the width of the item based on its content
        let labelText = "Item \(indexPath.row + 1)"
        
        // Calculate the width based on the text
        let labelWidth = labelText.size(withAttributes: [.font: UIFont.systemFont(ofSize: 16)]).width + 20  // Padding
        
        // Return the item size based on calculated width and fixed height
        return CGSize(width: labelWidth, height: 40)  // Height is fixed at 44
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggestionCollectionView.isHidden = true
        // cancelButton.isHidden = true
        
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return true
    }
}
