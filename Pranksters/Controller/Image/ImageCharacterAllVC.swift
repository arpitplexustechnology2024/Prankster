//
//  ImageCharacterAllVC.swift
//  Pranksters
//
//  Created by Arpit iOS Dev. on 18/10/24.
//

import UIKit
import Alamofire

class ImageCharacterAllVC: UIViewController {
    
    @IBOutlet weak var navigationbarView: UIView!
    @IBOutlet weak var imageCharacterAllCollectionView: UICollectionView!
    private var viewModel: CharacterAllViewModel!
    private var noDataView: NoDataView!
    private var noInternetView: NoInternetView!
    
    var characterId: Int = 0
    private let categoryId: Int = 3
    var isLoading = true
    
    init(viewModel: CharacterAllViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.viewModel = CharacterAllViewModel(apiService: CharacterAllAPIService.shared)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewModel()
        showSkeletonLoader()
        setupNoDataView()
        setupNoInternetView()
        setupCollectionView()
        checkInternetAndFetchData()
        navigationbarView.addBottomShadow()
        self.imageCharacterAllCollectionView.register(SkeletonBoxCollectionViewCell.self, forCellWithReuseIdentifier: "SkeletonCell")
    }
    
    func checkInternetAndFetchData() {
        if isConnectedToInternet() {
            viewModel.fetchAudioData(categoryId: 3, characterId: characterId)
            self.noInternetView?.isHidden = true
        } else {
            self.showNoInternetView()
            self.hideSkeletonLoader()
        }
    }
    
    private func setupCollectionView() {
        imageCharacterAllCollectionView.delegate = self
        imageCharacterAllCollectionView.dataSource = self
        if let layout = imageCharacterAllCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.minimumInteritemSpacing = 16
            layout.minimumLineSpacing = 16
            layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        }
    }
    
    private func setupViewModel() {
        viewModel.reloadData = { [weak self] in
            DispatchQueue.main.async {
                self?.hideSkeletonLoader()
                if self?.viewModel.audioData.isEmpty ?? true {
                    self?.showNoDataView()
                } else {
                    self?.hideNoDataView()
                    self?.imageCharacterAllCollectionView.reloadData()
                }
                self?.imageCharacterAllCollectionView.reloadData()
            }
        }
        
        viewModel.onError = { [weak self] error in
            self?.hideSkeletonLoader()
            self?.showNoDataView()
            print("Error: \(error)")
        }
    }
    
    func showSkeletonLoader() {
        isLoading = true
        imageCharacterAllCollectionView.reloadData()
    }
    
    func hideSkeletonLoader() {
        isLoading = false
        imageCharacterAllCollectionView.reloadData()
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
    
    func setupNoInternetView() {
        noInternetView = NoInternetView()
        noInternetView.retryButton.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        noInternetView.isHidden = true
        self.view.addSubview(noInternetView)
        
        noInternetView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            noInternetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            noInternetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            noInternetView.topAnchor.constraint(equalTo: navigationbarView.bottomAnchor, constant: 30),
            noInternetView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc func retryButtonTapped() {
        if isConnectedToInternet() {
            noInternetView.isHidden = true
            noDataView.isHidden = true
            checkInternetAndFetchData()
        } else {
            let snackbar = CustomSnackbar(message: "Please turn on internet connection!", backgroundColor: .snackbar)
            snackbar.show(in: self.view, duration: 3.0)
        }
    }
    
    func showNoInternetView() {
        self.noInternetView.isHidden = false
    }
    
    func showNoDataView() {
        noDataView.isHidden = false
    }
    
    func hideNoDataView() {
        noDataView.isHidden = true
    }
    
    private func isConnectedToInternet() -> Bool {
        let networkManager = NetworkReachabilityManager()
        return networkManager?.isReachable ?? false
    }
    
    @IBAction func btnBackTapped(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - CollectionView Delegate & DataSource
extension ImageCharacterAllVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isLoading ? 8 : viewModel.audioData.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if isLoading {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SkeletonCell", for: indexPath) as! SkeletonBoxCollectionViewCell
            cell.isUserInteractionEnabled = false
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCharacterAllCollectionViewCell", for: indexPath) as! ImageCharacterAllCollectionViewCell
            let audioData = viewModel.audioData[indexPath.item]
            cell.configure(with: audioData)
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let paddingSpace = layout.sectionInset.left + layout.sectionInset.right + layout.minimumInteritemSpacing * (UIDevice.current.userInterfaceIdiom == .pad ? 2 : 1)
        let availableWidth = collectionView.frame.width - paddingSpace
        let widthPerItem = availableWidth / (UIDevice.current.userInterfaceIdiom == .pad ? 3 : 2)
        let heightPerItem: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 287 : 187
        return CGSize(width: widthPerItem, height: heightPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let coverPageData = viewModel.audioData[indexPath.row]
        if coverPageData.premium && !PremiumManager.shared.isContentUnlocked(itemID: coverPageData.itemID) {
            showPremiumOptions(for: coverPageData, at: indexPath)
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(identifier: "ImagePreviewVC") as! ImagePreviewVC
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overCurrentContext
            vc.imageData = Array(viewModel.audioData[indexPath.row...])
            vc.initialIndex = 0
            self.present(vc, animated: true)
        }
    }
    
    private func presentPremiumViewController() {
        let premiumVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PremiumVC") as! PremiumVC
        present(premiumVC, animated: true, completion: nil)
    }
    
    private func showPremiumOptions(for content: CharacterAllData, at indexPath: IndexPath) {
        let alert = UIAlertController(
            title: "Unlock Premium Content",
            message: "Choose how you'd like to unlock this content",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Watch Ad for One-Time Access", style: .default) { [weak self] _ in
            
            PremiumManager.shared.temporarilyUnlockContent(itemID: content.itemID)
            self?.imageCharacterAllCollectionView.reloadData()
            if let strongSelf = self {
                let snackbar = CustomSnackbar(message: "Content unlocked for this session!", backgroundColor: .snackbar)
                snackbar.show(in: strongSelf.view, duration: 3.0)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Get Premium for Unlimited Access", style: .default) { [weak self] _ in
            self?.presentPremiumViewController()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
