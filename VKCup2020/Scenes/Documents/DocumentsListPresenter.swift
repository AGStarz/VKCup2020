//
//  DocumentsListPresenter.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 16.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

protocol DocumentsAuthorizationViewModel {
    var photo: UIImage { get }
}

protocol DocumentsListPresenter {
    func fetchDocuments()
    
    func updateQuickFilter(type: Int, enabled: Bool)
    
    func updateSearchQuery(string: String?)
    
    func logout()
}

protocol VKDocumentsListPresenterDelegate: AnyObject {
    func documentsList(_ presenter: VKDocumentsListPresenter,
                       didUpdate list: DocumentsListViewModel)
	func documentsList(_ presenter: VKDocumentsListPresenter,
					   didUpdate authorization: DocumentsAuthorizationViewModel)
}

class VKDocumentsListPresenter {
    
    typealias VKNetworkClient = DocumentsListLoader & UserProfileLoader & DuplicateFileLoader
    
    unowned let delegate: VKDocumentsListPresenterDelegate
    
    unowned let viewController: UIViewController
    
    let loader: VKNetworkClient
    
    var documents: [Document] = []
    
    var quickFilters: Set<Int> = []
    
    var searchQuery: String?
    
    weak var authManager: AuthManager?
    
    var filteredDocuments: [Document] {
        var docs: [Document] = []
        
        if quickFilters.isEmpty {
            docs.append(contentsOf: documents)
        } else {
            docs = documents.filter({ quickFilters.contains($0.type) })
        }
        
        if let searchQuery = searchQuery, !searchQuery.isEmpty {
            docs = docs.filter({ $0.title.lowercased().contains(searchQuery.lowercased()) })
        }
        
        return docs
    }
    
    init(delegate: VKDocumentsListPresenterDelegate,
         viewController: UIViewController,
         loader: VKNetworkClient = NetworkClient()) {
        self.delegate = delegate
        self.loader = loader
        self.viewController = viewController
    }
}

// MARK: - Business rules

private extension VKDocumentsListPresenter {
    
    func updateItem(with state: DocumentCellViewModelState?, at index: Int) {
        let viewModels = DocumentViewModelFactory.viewModels(
            for: filteredDocuments,
            with: state.flatMap({ [index: $0] }) ?? [:],
            select: select,
            onShow: onShow,
            onRename: onRename,
            onRemove: onRemove,
            onClone: onClone
        )
        let indexPath = IndexPath(item: index, section: 0)
        notifyDelegate(documents: viewModels, updates: [.reload([indexPath])])
    }
    
    func insertItem(at index: Int, with state: DocumentCellViewModelState) {
        let viewModels = DocumentViewModelFactory.viewModels(
            for: filteredDocuments,
            with: [index: state],
            select: select,
            onShow: onShow,
            onRename: onRename,
            onRemove: onRemove,
            onClone: onClone
        )
        let indexPath = IndexPath(item: index, section: 0)
        notifyDelegate(documents: viewModels, updates: [.insert([indexPath])])
    }
    
    func removeItem(at index: Int, document: Document) {
        documents = documents.filter({ $0.id != document.id })
        
        reloadFilteredDocuments()
    }
    
    func renameItem(at index: Int, with result: Result<Document, Error>) {
        switch result {
        case .success(let document):
            let target = documents.firstIndex(where: { $0.id == document.id }) ?? index
            documents[target] = document
        default:
            print("Rename failed")
        }
        
        reloadFilteredDocuments()
    }
    
    func notifyDelegate(documents: [DocumentCellViewModel], updates: [UpdateType]) {
        let viewModel = VKDocumentsListViewModel(documents: documents, updates: updates)
        delegate.documentsList(self, didUpdate: viewModel)
    }
    
    func rename(from documents: [Document], at index: Int) {
        updateItem(with: .renaming, at: index)
        
        let alert = AlertFactory.renameAlert(
            filename: documents[index].title,
            onRename: { (filename) in
                self.loader.rename(document: documents[index], to: filename) { (result) in
                    self.renameItem(at: index, with: result)
                }
            },
            onCancel: {
                self.updateItem(with: nil, at: index)
            }
        )
        viewController.present(alert, animated: true, completion: nil)
    }
    
    func remove(from documents: [Document], at index: Int) {
        updateItem(with: .removing, at: index)
        
        let document = documents[index]
        loader.remove(document: document) { (result) in
            switch result {
            case .success(let deleted) where deleted:
                self.removeItem(at: index, document: document)
            default:
                self.updateItem(with: nil, at: index)
            }
        }
    }
    
    func clone(document: Document) {
        let alert = AlertFactory.cloneAlert(
            filename: FilenameFactory.defaultFilenameForCloneOperation(of: document),
            onClone: { name in
                self.documents.insert(DocumentsFactory.renamed(document: document,
                                                               with: name), at: 0)
                self.insertItem(at: 0, with: .renaming)
                
                self.loader.clone(document: document, to: name) { [weak self] result in
                    switch result {
                    case .success(let doc):
                        self?.documents[0] = doc
                    case.failure:
                        self?.documents.remove(at: 0)
                    }
                    
                    self?.reloadFilteredDocuments()
                }
            },
            onCancel: { }
        )
        viewController.present(alert, animated: true, completion: nil)
    }

    func process(documents: [Document]) {
        self.documents = documents
        
        let result = DocumentViewModelFactory.viewModels(
            for: documents,
            select: select,
            onShow: onShow,
            onRename: onRename,
            onRemove: onRemove,
            onClone: onClone
        )
        let insertions = (0..<documents.count)
            .map({ IndexPath(item: $0, section: 0) })
        notifyDelegate(documents: result, updates: [.insert(insertions)])
    }
    
    func reloadFilteredDocuments() {
        let result = DocumentViewModelFactory.viewModels(
            for: filteredDocuments,
            select: select,
            onShow: onShow,
            onRename: onRename,
            onRemove: onRemove,
            onClone: onClone
        )
        notifyDelegate(documents: result, updates: [.reloadData])
    }
}

// MARK: - Interactor

private extension VKDocumentsListPresenter {

    func select(document: Document) {
        let previewController = DocumentPreviewController(document: document)
        viewController.present(previewController, animated: true, completion: nil)
    }
    
    func onLogout() {
        authManager?.logout()
        
        viewController.navigationController?.dismiss(animated: true, completion: nil)
    }

    func onShow(alert: UIViewController) {
        viewController.present(alert, animated: true, completion: nil)
    }

    func onRename(documents: [Document], offset: Int) {
        rename(from: documents, at: offset)
    }

    func onRemove(documents: [Document], offset: Int) {
        remove(from: documents, at: offset)
    }
    
    func onClone(document: Document) {
        clone(document: document)
    }
}

// MARK: - DocumentsListPresenterProtocol

extension VKDocumentsListPresenter: DocumentsListPresenter {
    
    func fetchDocuments() {
        loader.fetch { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let documents):
                strongSelf.process(documents: documents)
            case .failure:
                strongSelf.process(documents: [])
            }
        }

		loader.fetchClientPhoto { [weak self] result in
			guard let strongSelf = self else { return }

			let image = try? result.get()
            let authorization = Authorization(photo: image ?? #imageLiteral(resourceName: "user"))
			strongSelf.delegate.documentsList(strongSelf, didUpdate: authorization)
		}
    }
    
    func updateSearchQuery(string: String?) {
        searchQuery = string
        
        reloadFilteredDocuments()
    }
    
    func updateQuickFilter(type: Int, enabled: Bool) {
        if enabled {
            quickFilters.insert(type)
        } else {
            quickFilters.remove(type)
        }
        
        reloadFilteredDocuments()
    }
    
    func logout() {
        let alert = AlertFactory.authAlert(onLogout: onLogout)
        viewController.present(alert, animated: true, completion: nil)
    }
}

// MARK: - Nested types

private extension VKDocumentsListPresenter {
    
    struct VKDocumentsListViewModel: DocumentsListViewModel {
        let documents: [DocumentCellViewModel]
        let updates: [UpdateType]
    }
    
    struct Authorization: DocumentsAuthorizationViewModel {
        let photo: UIImage
    }
}
