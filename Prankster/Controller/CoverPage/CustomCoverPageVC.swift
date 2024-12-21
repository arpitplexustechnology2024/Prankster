//
//  CustomCoverPageVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 11/11/24.
//

import UIKit

class CustomCoverPageVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var customeCoverAllCollectionView: UICollectionView!
    @IBOutlet weak var customeCoverSlideCollectionview: UICollectionView!
    var allCustomCovers: [UIImage] = []
    
    private var noDataView: NoDataView!
    private var selectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNoDataView()
        self.setupSwipeGesture()
        self.setupCollectionView()
        self.updateNoDataViewVisibility()
        self.navigationbarView.addBottomShadow()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            if !self.allCustomCovers.isEmpty {
                let indexPath = IndexPath(item: 0, section: 0)
                self.customeCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.customeCoverSlideCollectionview.selectItem(at: indexPath, animated: false, scrollPosition: [])
                self.selectedIndex = 0
            }
        }
    }
    
    private func setupCollectionView() {
        self.customeCoverAllCollectionView.delegate = self
        self.customeCoverAllCollectionView.dataSource = self
        self.customeCoverAllCollectionView.isPagingEnabled = true
        self.customeCoverSlideCollectionview.delegate = self
        self.customeCoverSlideCollectionview.dataSource = self
    }
    
    private func setupNoDataView() {
        noDataView = NoDataView()
        noDataView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        noDataView.isHidden = true
        self.view.addSubview(noDataView)
        noDataView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noDataView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noDataView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noDataView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor, constant: 30),
            noDataView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func updateNoDataViewVisibility() {
        noDataView.isHidden = !allCustomCovers.isEmpty
        customeCoverAllCollectionView.isHidden = allCustomCovers.isEmpty
        customeCoverSlideCollectionview.isHidden = allCustomCovers.isEmpty
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    private func setupSwipeGesture() {
        let swipeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.edges = .left
        self.view.addGestureRecognizer(swipeGesture)
    }
    
    @objc private func handleSwipe(_ gesture: UIScreenEdgePanGestureRecognizer) {
        if gesture.state == .recognized {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension CustomCoverPageVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return allCustomCovers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == customeCoverAllCollectionView {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCoverAllCollectionViewCell", for: indexPath) as! CustomCoverAllCollectionViewCell
        cell.imageView.image = allCustomCovers[indexPath.item]
        cell.delegate = self
        return cell
        } else if collectionView == customeCoverSlideCollectionview {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CustomCoverSliderCollectionViewCell", for: indexPath) as! CustomCoverSliderCollectionViewCell
            cell.imageView.image = allCustomCovers[indexPath.item]
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        
        if collectionView == customeCoverAllCollectionView {
            customeCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
            customeCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            customeCoverAllCollectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
            customeCoverAllCollectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = 80
        let height: CGFloat = 104
        
        if collectionView == customeCoverAllCollectionView {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        } else if collectionView == customeCoverSlideCollectionview {
            return CGSize(width: width, height: height)
        }
        return CGSize(width: width, height: height)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == customeCoverAllCollectionView {
            let pageWidth = scrollView.bounds.width
            let currentPage = Int((scrollView.contentOffset.x + pageWidth/2) / pageWidth)
            
            if currentPage != selectedIndex {
                selectedIndex = currentPage
                
                let indexPath = IndexPath(item: currentPage, section: 0)
                customeCoverSlideCollectionview.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
                customeCoverSlideCollectionview.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            }
        }
    }
}

extension CustomCoverPageVC: CustomCoverAllCollectionViewCellDelegate {
    func didTapDoneButton(with image: UIImage) {
        if let navigationController = self.navigationController {
            if let coverPageVC = navigationController.viewControllers.first(where: { $0 is CoverPageVC }) as? CoverPageVC {
                let coverData = CoverPageData( coverURL: "", coverName: "", tagName: [""], coverPremium: false, itemID: 0)
                coverPageVC.updateSelectedImage(with: coverData, customImage: image)
                navigationController.popToViewController(coverPageVC, animated: true)
            }
        }
    }
}
