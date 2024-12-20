//
//  ImageCategoryVC.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 19/12/24.
//

import UIKit

class ImageCategoryVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var imageCharacterAllCollectionView: UICollectionView!
    @IBOutlet weak var searchbar: UISearchBar!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }

}
