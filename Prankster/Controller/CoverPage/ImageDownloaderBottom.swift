//
//  ImageDownloaderBottom.swift
//  Prankster
//
//  Created by Arpit iOS Dev. on 21/08/24.
//

import UIKit

class ImageDownloaderBottom: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    private var gifSlider: [DownloadGIFModel] = []
    private var currentPage = 0 {
        didSet {
            updateCurrentPage()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        view.layer.cornerRadius = 28
        view.layer.masksToBounds = true
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    private func setupUI() {
        gifSlider = [
            DownloadGIFModel(image: UIImage(named: "DownloadImage01")),
            DownloadGIFModel(image: UIImage(named: "DownloadImage02"))
        ]
        
        pageControl.numberOfPages = gifSlider.count
    }
    
    private func updateCurrentPage() {
        pageControl.currentPage = currentPage
    }
    
    private func moveToNext() {
        if currentPage < gifSlider.count - 1 {
            currentPage += 1
        } else {
            currentPage = 0
        }
        let indexPath = IndexPath(item: currentPage, section: 0)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
}

//MARK: - UICollectionView DataSource
extension ImageDownloaderBottom: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return gifSlider.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DownloadImageCell", for: indexPath) as! DownloadImageCell
        cell.setupCell(gifSlider[indexPath.row])
        return cell
    }
}

//MARK: - UICollectionView Delegates
extension ImageDownloaderBottom: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let width = scrollView.frame.width
        currentPage = Int(scrollView.contentOffset.x / width)
    }
}

//MARK: - UICollectionView Delegate FlowLayout
extension ImageDownloaderBottom: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}
