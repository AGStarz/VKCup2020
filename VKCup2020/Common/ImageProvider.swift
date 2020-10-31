//
//  ImageProvider.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

protocol ImageProvider {
    func image(completion: @escaping (Result<UIImage, Error>) -> Void) -> Cancellable
}

struct RemoteImageProvider: ImageProvider {
    
    enum NetworkError: Error {
        case requestFailed
        case parseImageFailed
    }
    
    let url: URL
    
    func image(completion: @escaping (Result<UIImage, Error>) -> Void) -> Cancellable {
        let task = URLSession.shared.dataTask(with: url) { (data, _, _) in
            let queue = DispatchQueue.main
            
            guard let data = data else {
                return queue.perform(block: completion, param: .failure(NetworkError.requestFailed))
            }
            
            guard let image = UIImage(data: data) else {
                return queue.perform(block: completion, param: .failure(NetworkError.parseImageFailed))
            }
            
            return queue.perform(block: completion, param: .success(image))
        }
        task.resume()
        return task
    }
}

struct PlaceholderImageProvider: ImageProvider {
    
    let type: Int
    
    func image(completion: @escaping (Result<UIImage, Error>) -> Void) -> Cancellable {
        let image = ImageProviderFactory.imageResource(for: type)
        completion(.success(image))
        return AnyCancellable()
    }
}

enum ImageProviderFactory {
    
    static func imageResource(for type: Int) -> UIImage {
        switch type {
        case 1:
            return #imageLiteral(resourceName: "text")
        case 2:
            return #imageLiteral(resourceName: "archive")
        case 3:
            return #imageLiteral(resourceName: "image")
        case 4:
            return #imageLiteral(resourceName: "image")
        case 5:
            return #imageLiteral(resourceName: "music")
        case 6:
            return #imageLiteral(resourceName: "video")
        case 7:
            return #imageLiteral(resourceName: "ebook")
        default:
            return #imageLiteral(resourceName: "other")
        }
    }
    
    static func imageProvider(for document: Document) -> ImageProvider {
        guard let url = document.preview.flatMap({ (preview) -> URL? in
            PreviewFactory.screenRelated(from: preview)
        }) else {
            return PlaceholderImageProvider(type: document.type)
        }
        
        return RemoteImageProvider(url: url)
    }
}
