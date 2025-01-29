//
//  SearchVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 28/01/25.
//

import UIKit

class SearchVC: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchMainView: UIView!
    @IBOutlet weak var searchBar: UITextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var searchMainViewHeightConstarints: NSLayoutConstraint!
    @IBOutlet weak var popularLabel: UILabel!
    @IBOutlet weak var suggetionTableView: UITableView!
    
    @IBOutlet weak var searchBarView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        // Initial setup: Hide certain elements
        popularLabel.isHidden = true
        suggetionTableView.isHidden = true
        cancelButton.isHidden = true
        searchMainView.isHidden = true
        searchMainViewHeightConstarints.constant = 0
        
        // Set the corner radius initially
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        
        // Set TableView delegate and datasource
        suggetionTableView.delegate = self
        suggetionTableView.dataSource = self
        
        // Register the custom UITableViewCell class or Nib (if using a custom one)
        suggetionTableView.register(UITableViewCell.self, forCellReuseIdentifier: "SuggestionCell")
        
        // Add target for searchBar tap
        searchBar.addTarget(self, action: #selector(searchBarTapped(_:)), for: .editingDidBegin)
    }
    
    // Action when cancel button is tapped
    @IBAction func btncancelSearchTapped(_ sender: UIButton) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggetionTableView.isHidden = true
        cancelButton.isHidden = true
        
        // Restore corner radius when cancel is tapped
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()  // Animate the layout changes
        }
    }
    
    // Action when the user taps the search bar
    @objc func searchBarTapped(_ sender: UITextField) {
        // Show the hidden UI elements
        searchMainView.isHidden = false
        popularLabel.isHidden = false
        suggetionTableView.isHidden = false
        cancelButton.isHidden = false
        
        searchMainViewHeightConstarints.constant = 250
        
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        searchMainView.layer.cornerRadius = 10
        searchMainView.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        
        // Animate the changes
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
}

extension SearchVC: UITableViewDelegate, UITableViewDataSource {
    
    // TableView DataSource methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10  // You need 10 cells
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Dequeue cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "SuggestionCell", for: indexPath)
        
        // Set the text and image
        cell.textLabel?.text = "Item \(indexPath.row + 1)"  // Example text, adjust as needed
        
        // Set text color to white
        cell.textLabel?.textColor = .white
        
        // Set the background color of the cell to clear
        cell.backgroundColor = .clear
        
        cell.selectionStyle = .none
        
        // Set image to arrow, with white color (tint)
        if let arrowImage = UIImage(systemName: "arrow.right.circle.fill") {
            cell.imageView?.image = arrowImage.withTintColor(.white, renderingMode: .alwaysOriginal)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        if let selectedText = selectedCell?.textLabel?.text {
            searchBar.text = selectedText
        }
        
        searchBar.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggetionTableView.isHidden = true
        // cancelButton.isHidden = true
        
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        searchMainViewHeightConstarints.constant = 0
        searchMainView.isHidden = true
        popularLabel.isHidden = true
        suggetionTableView.isHidden = true
        // cancelButton.isHidden = true
        
        searchMainView.layer.cornerRadius = 10
        searchBarView.layer.cornerRadius = 10
        searchBarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        return true
    }
}
