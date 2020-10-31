//
//  DocumentsFactory.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

enum DocumentsFactory {
    
    struct VKDocument: Document {
        let id: Int
        let ownerId: Int
        let date: Int
        let ext: String
        let size: Int
        let title: String
        let type: Int
        let url: URL
        let tags: [String]
        let preview: [Preview: URL]?
    }
    
    static func renamed(document: Document, with title: String) -> Document {
        return VKDocument(id: document.id,
                          ownerId: document.ownerId,
                          date: document.date,
                          ext: document.ext,
                          size: document.size,
                          title: title,
                          type: document.type,
                          url: document.url,
                          tags: document.tags,
                          preview: document.preview)
    }
    
    static func documents(from items: [[String: Any]]) -> [Document] {
        return items.compactMap { (item) -> Document? in
            guard let id = item["id"] as? Int,
                let ownerId = item["owner_id"] as? Int,
                let url = URL(string: (item["url"] as? String ?? "")),
                let size = item["size"] as? Int,
                let title = item["title"] as? String,
                let ext = item["ext"] as? String,
                let date = item["date"] as? Int,
                let type = item["type"] as? Int
            else {
                return nil
            }
            
            let previews = item["preview"].flatMap { (preview) -> [Preview: URL]? in
                guard let preview = preview as? [String: Any],
                    let photoPreview = preview["photo"] as? [String: Any],
                    let photoSizesPreview = photoPreview["sizes"] as? [[String: Any]]
                else {
                    return nil
                }
                
                var result: [Preview: URL] = [:]
                
                for photoSizePreview in photoSizesPreview {
                    guard let type = photoSizePreview["type"] as? String,
                        let previewCase = Preview(rawValue: type),
                        let stringUrl = photoSizePreview["src"] as? String,
                        let url = URL(string: stringUrl) else { continue }
                    result[previewCase] = url
                }
                
                return result
            }
            
            let tags = item["tags"] as? [String] ?? []
            
            return VKDocument(id: id,
                              ownerId: ownerId,
                              date: date,
                              ext: ext,
                              size: size,
                              title: title,
                              type: type,
                              url: url,
                              tags: tags,
                              preview: previews)
        }
    }
}
