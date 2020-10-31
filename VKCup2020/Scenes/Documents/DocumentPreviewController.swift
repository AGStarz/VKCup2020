//
//  DocumentPreviewController.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit
import QuickLook

class DocumentPreviewController: QLPreviewController {
    
    let document: Document
    
    var state: State = .loading
    
    lazy var task = URLSession.shared.downloadTask(with: document.url,
                                                   completionHandler: process)
    
    init(document: Document) {
        self.document = document
        
        super.init(nibName: nil, bundle: nil)
        
        delegate = self
        dataSource = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        task.resume()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        task.cancel()
    }
    
    private func process(url: URL?, response: URLResponse?, error: Error?) {
        guard let url = url, let documentsUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
        
        let filename = FilenameFactory.accurateFilename(for: document)
        let destinationUrl = documentsUrl.appendingPathComponent(filename)
        
        try? FileManager.default.removeItem(at: destinationUrl)
        try? FileManager.default.moveItem(at: url, to: destinationUrl)
        
        DispatchQueue.main.async { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.state = .loaded(destinationUrl)
            strongSelf.reloadData()
        }
    }
}

extension DocumentPreviewController: QLPreviewControllerDataSource {
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return state.numberOfItems
    }
    
    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        return state.previewItem
    }
}

extension DocumentPreviewController: QLPreviewControllerDelegate {
    
    @available(iOS 13.0, *)
    func previewController(_ controller: QLPreviewController,
                           editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .disabled
    }
}

extension DocumentPreviewController {
    
    enum State {
        case loading
        case loaded(URL)
        
        var numberOfItems: Int {
            switch self {
            case .loading:
                return 0
            case .loaded:
                return 1
            }
        }
        
        var previewItem: QLPreviewItem {
            class Item: NSObject, QLPreviewItem {
                var previewItemURL: URL?
            }
            let item = Item()
            switch self {
            case .loaded(let url):
                item.previewItemURL = url.standardizedFileURL
            default:
                item.previewItemURL = nil
            }
            return item
        }
    }
}

enum FilenameFactory {
    static func accurateFilename(for document: Document) -> String {
        let actual = document.title
        
        guard actual.contains(document.ext) else {
            return actual + "." + document.ext
        }
        
        return actual
    }
    
    static func defaultFilenameForCloneOperation(of document: Document) -> String {
        let actual = document.title
        let ext = document.ext
        
        guard actual.contains(ext) else {
            return actual + " (1)." + ext
        }
        
        let noExt = String(actual.dropLast(ext.count + 1))
        
        return noExt + " (1)." + ext
    }
}
