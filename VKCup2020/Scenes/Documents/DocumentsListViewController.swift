//
//  DocumentsListViewController.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 15.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

protocol DocumentsListViewModel {
    var documents: [DocumentCellViewModel] { get }
    var updates: [UpdateType] { get }
}

class DocumentsListViewController: UIViewController {
    
    lazy var collectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSize(width: UIScreen.main.bounds.width,
                                               height: 88)
        collectionViewLayout.headerReferenceSize = CGSize(width: UIScreen.main.bounds.width,
                                                          height: 200)
        collectionViewLayout.sectionHeadersPinToVisibleBounds = true
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(cellClass: DocumentsListCell.self)
        collectionView.register(reusableView: DocumentsListHeaderView.self)
        
        return collectionView
    }()
    
    lazy var presenter: DocumentsListPresenter = VKDocumentsListPresenter(delegate: self,
                                                                          viewController: self)
    
    lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Поиск по названию документа"
        return searchController
    }()
    
    var viewModel: DocumentsListViewModel = Empty() {
        didSet {
            reloadCollectionViewIfNeeded()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Документы"
        navigationItem.searchController = searchController
        
        definesPresentationContext = true
        
        view.addSubview(collectionView)
        collectionView.safeWrap(in: view)
        
        presenter.fetchDocuments()
    }
}

extension DocumentsListViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        presenter.updateSearchQuery(string: searchController.searchBar.text)
    }
}

extension DocumentsListViewController {
    
    private var updates: [UpdateType] {
        return viewModel.updates
    }
    
    private var documents: [DocumentCellViewModel] {
        return viewModel.documents
    }
    
    private func reloadCollectionViewIfNeeded() {
        updates.forEach { (update) in
            switch update {
            case .insert(let indexPaths):
                collectionView.insertItems(at: indexPaths)
            case .reload(let indexPaths):
                for indexPath in indexPaths {
                    guard let cell = collectionView.cellForItem(at: indexPath) as? DocumentsListCell else { continue }
                    cell.set(viewModel: documents[indexPath.row])
                }
            case .remove(let indexPaths):
                collectionView.deleteItems(at: indexPaths)
            case .reloadData:
                collectionView.reloadData()
            }
        }
    }
}

extension DocumentsListViewController: VKDocumentsListPresenterDelegate {
    
    func documentsList(_ presenter: VKDocumentsListPresenter,
                       didUpdate list: DocumentsListViewModel) {
        viewModel = list
    }
    
    func documentsList(_ presenter: VKDocumentsListPresenter,
                       didUpdate authorization: DocumentsAuthorizationViewModel) {
        let imageView = UIImageView(image: authorization.photo)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.isUserInteractionEnabled = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.heightAnchor.constraint(equalToConstant: 32),
            imageView.widthAnchor.constraint(equalToConstant: 32)
        ])
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self,
                                                              action: #selector(didTapRightNavBarItem)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: imageView)
    }
    
    @objc func didTapRightNavBarItem() {
        presenter.logout()
    }
}

extension DocumentsListViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return documents.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: DocumentsListCell = collectionView.dequeueReusableCell(at: indexPath)
        cell.set(viewModel: documents[indexPath.row])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let headerView = collectionView.dequeueReusableView(at: indexPath) as DocumentsListHeaderView
        headerView.backgroundColor = collectionView.backgroundColor
        headerView.onSelectFilter = { [unowned self] type, selected in
            self.presenter.updateQuickFilter(type: type, enabled: selected)
        }
        return headerView
    }
}

extension DocumentsListViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        documents[indexPath.row].select()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let base = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader).first?.frame.height ?? 0
        let offset = min(scrollView.contentOffset.y, 0)
        
        collectionView.scrollIndicatorInsets.top = base - offset
    }
}

extension DocumentsListViewController {
    
    struct Empty: DocumentsListViewModel {
        let documents: [DocumentCellViewModel] = []
        let updates: [UpdateType] = []
    }
}

