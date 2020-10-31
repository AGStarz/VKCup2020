//
//  DocumentViewModelFactory.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

enum DocumentViewModelFactory {
    
    static let describeUtils = DescribeUtils()
    
    static func viewModels(for documents: [Document],
                           renaming: (Int, String),
                           with state: [Int: DocumentCellViewModelState] = [:],
                           select: @escaping (Document) -> Void,
                           onShow: @escaping (UIViewController) -> Void,
                           onRename: @escaping ([Document], Int) -> Void,
                           onRemove: @escaping ([Document], Int) -> Void,
                           onClone: @escaping (Document) -> Void) -> [VKDocumentCellViewModel] {
        var models = viewModels(for: documents, with: state, select: select, onShow: onShow, onRename: onRename, onRemove: onRemove, onClone: onClone)
        models[renaming.0] = models[renaming.0].renamed(with: renaming.1)
        return models
    }
    
    static func viewModels(for documents: [Document],
                           removed: Int,
                           with state: [Int: DocumentCellViewModelState] = [:],
                           select: @escaping (Document) -> Void,
                           onShow: @escaping (UIViewController) -> Void,
                           onRename: @escaping ([Document], Int) -> Void,
                           onRemove: @escaping ([Document], Int) -> Void,
                           onClone: @escaping (Document) -> Void) -> [VKDocumentCellViewModel] {
        var models = viewModels(for: documents, with: state, select: select, onShow: onShow, onRename: onRename, onRemove: onRemove, onClone: onClone)
        models.remove(at: removed)
        return models
    }
    
    static func viewModels(for documents: [Document],
                           with state: [Int: DocumentCellViewModelState] = [:],
                           select: @escaping (Document) -> Void,
                           onShow: @escaping (UIViewController) -> Void,
                           onRename: @escaping ([Document], Int) -> Void,
                           onRemove: @escaping ([Document], Int) -> Void,
                           onClone: @escaping (Document) -> Void) -> [VKDocumentCellViewModel] {
        return documents.enumerated().map { (eDocument) -> VKDocumentCellViewModel in
            let document = eDocument.element
            let index = eDocument.offset
            
            let command = CommandFactory.showMenu(
                onShow: { (alert) in
                    onShow(alert)
                },
                onRename: {
                    onRename(documents, index)
                },
                onRemove: {
                    onRemove(documents, index)
                },
                onClone: {
                    onClone(document)
                }
            )
            
            let subtitle = [
                DocumentViewModelFactory.describeUtils.describe(ext:  document.ext),
                DocumentViewModelFactory.describeUtils.describe(size: document.size),
                DocumentViewModelFactory.describeUtils.describe(unix: document.date)
            ].joined(separator: " · ")
            
            let documentViewModel = VKDocumentCellViewModel(
                title: document.title,
                subtitle: subtitle,
                tags: document.tags,
                state: state[index, default: .ready(command)],
                imageProvider: ImageProviderFactory.imageProvider(for: document),
                select: { select(document) }
            )
            
            return documentViewModel
        }
    }
    
    struct VKDocumentCellViewModel: DocumentCellViewModel {
        let title: String
        let subtitle: String
        let tags: [String]
        var state: DocumentCellViewModelState
        let imageProvider: ImageProvider
        let select: () -> Void
        
        func renamed(with title: String) -> VKDocumentCellViewModel {
            return VKDocumentCellViewModel(title: title,
                                           subtitle: subtitle,
                                           tags: tags,
                                           state: state,
                                           imageProvider: imageProvider,
                                           select: select)
        }
    }
}
