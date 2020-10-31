//
//  DocumentsListLoader.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import VK_ios_sdk

protocol DuplicateFileLoader {
    func clone(document: Document, to name: String, completion: @escaping (Result<Document, Error>) -> Void)
}

protocol UserProfileLoader {
	func fetchClientPhoto(completion: @escaping (Result<UIImage?, Never>) -> Void)
}

protocol DocumentsListLoader {
    func fetch(completion: @escaping (Result<[Document], Error>) -> Void)
    func remove(document: Document, completion: @escaping (Result<Bool, Error>) -> Void)
    func rename(document: Document, to name: String, completion: @escaping (Result<Document, Error>) -> Void)
}

class NetworkClient: DocumentsListLoader, UserProfileLoader, DuplicateFileLoader {

	func fetchClientPhoto(completion: @escaping (Result<UIImage?, Never>) -> Void) {
        let parameters: [AnyHashable: Any] = ["fields": "photo_50"]
        
		VKApi.request(withMethod: "users.get", andParameters: parameters)?.execute(
			resultBlock: { response in
				let json = (response?.json as? [[String: Any]])?.first
				let photoUrl = json?["photo_50"] as? String
				_ = photoUrl.flatMap(URL.init).flatMap(RemoteImageProvider.init)?.image { result in
					DispatchQueue.main.perform(block: completion, param: .success(try? result.get()))
				}
			},
			errorBlock: { _ in
				DispatchQueue.main.perform(block: completion, param: .success(nil))
			}
		)
	}
    
    func fetch(completion: @escaping (Result<[Document], Error>) -> Void) {
        guard let userId = VKSdk.accessToken().userId else {
            return
        }
        
        let parameters: [AnyHashable: Any] = [
            "count": 2000,
            "offset": 0,
            "type": 0,
            "return_tags": 1,
            "v": "5.103",
            "owner_id": userId
        ]
        
        VKApi.request(withMethod: "docs.get",
                      andParameters: parameters)?
            .execute(resultBlock: { (response) in
                guard let json = response?.json as? [String: Any],
                    let items = json["items"] as? [[String: Any]]
                else {
                    return
                }
                
                let result = DocumentsFactory.documents(from: items)
                DispatchQueue.main.perform(block: completion, param: .success(result))
            }, errorBlock: { (error) in
                DispatchQueue.main.perform(block: completion, param: .failure(error!))
            })
    }
    
    func remove(document: Document, completion: @escaping (Result<Bool, Error>) -> Void) {
        let parameters: [AnyHashable: Any] = [
            "owner_id": document.ownerId,
            "doc_id": document.id,
            "v": "5.103"
        ]
        
        VKApi.request(withMethod: "docs.delete",
                  andParameters: parameters)?
        .execute(resultBlock: { (response) in
            guard let status = response?.json as? Int else { return }
            
            DispatchQueue.main.perform(block: completion, param: .success(status == 1))
        }, errorBlock: { (error) in
            DispatchQueue.main.perform(block: completion, param: .failure(error!))
        })
    }
    
    func rename(document: Document, to name: String, completion: @escaping (Result<Document, Error>) -> Void) {
        let parameters: [AnyHashable: Any] = [
            "owner_id": document.ownerId,
            "doc_id": document.id,
            "title": name,
            "tags": document.tags,
            "v": "5.103"
        ]
        
        VKApi.request(withMethod: "docs.edit",
                      andParameters: parameters)?
            .execute(resultBlock: { (response) in
                guard let status = response?.json as? Int else { return }
                
                let document = status == 1
                    ? DocumentsFactory.renamed(document: document, with: name)
                    : document
                
                DispatchQueue.main.perform(block: completion, param: .success(document))
            }, errorBlock: { (error) in
                DispatchQueue.main.perform(block: completion, param: .failure(error!))
            })
    }
    
    func clone(document: Document, to name: String, completion: @escaping (Result<Document, Error>) -> Void) {
        let group = DispatchGroup()
        
        var uploadServerUrl: URL?
        var fileToUploadUrl: URL?
        
        group.enter()
        VKApi.request(withMethod: "docs.getUploadServer",
                      andParameters: ["v": "5.103"])?
            .execute(
                resultBlock: { response in
                    defer { group.leave() }
                    
                    guard let json = response?.json as? [String: Any] else { return }
                    
                    uploadServerUrl = (json["upload_url"] as? String).flatMap(URL.init)
                },
                errorBlock: { error in
                    group.leave()
                }
            )
        
        group.enter()
        URLSession.shared.downloadTask(with: document.url) { url, response, error in
            defer { group.leave() }
            
            guard let url = url, let documentsUrl = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) else { return }
            
            let filename = FilenameFactory.accurateFilename(for: document)
            let destinationUrl = documentsUrl.appendingPathComponent(filename)
            
            try? FileManager.default.removeItem(at: destinationUrl)
            try? FileManager.default.moveItem(at: url, to: destinationUrl)
            
            fileToUploadUrl = destinationUrl
        }.resume()
        
        group.notify(queue: .global(qos: .utility)) {
            guard let uploadServerUrl = uploadServerUrl,
                  let fileToUploadUrl = fileToUploadUrl else {
                return DispatchQueue.main.perform(block: completion,
                                                  param: .failure(NetworkError.common))
            }
            
            var request = URLRequest(url: uploadServerUrl)
            request.httpMethod = "POST"
            request.setValue("multipart/form-data;  boundary=<ios_task>",
                             forHTTPHeaderField: "Content-Type")
            request.httpBody = UploadDataFactory.httpBody(of: fileToUploadUrl, using: name)
            URLSession.shared.dataTask(with: request) { data, _, _ in
                guard let file = data.flatMap({ try? JSONDecoder().decode(UploadResponse.self, from: $0) })?.file else {
                    return DispatchQueue.main.perform(block: completion,
                                                      param: .failure(NetworkError.common))
                }
                
                VKApi.request(withMethod: "docs.save",
                              andParameters: ["file": file,
                                              "title": name,
                                              "return_tags": 1,
                                              "v": "5.103"])?
                    .execute(
                        resultBlock: { response in
                            guard let json = response?.json as? [String: Any],
                                  let doc = json["doc"] as? [String: Any],
                                  let resultDocument = DocumentsFactory.documents(from: [doc]).first else {
                                return DispatchQueue.main.perform(block: completion,
                                                                  param: .failure(NetworkError.common))
                            }
                            
                            DispatchQueue.main.perform(block: completion,
                                                       param: .success(resultDocument))
                        },
                        errorBlock: { error in
                            DispatchQueue.main.perform(block: completion,
                                                       param: .failure(NetworkError.common))
                        }
                    )
            }.resume()
        }
    }
    
    struct UploadResponse: Decodable {
        let file: String
    }
    
    enum UploadDataFactory {
        
        static func httpBody(of file: URL, using name: String) -> Data {
            var result = Data()
            if let meta = ("\r\n--<ios_task>\r\nContent-Disposition: form-data; name=\"file\"; filename=\"\(name)\"\r\nContent-Type: document/other\r\n\r\n").data(using: .utf8, allowLossyConversion: false) {
                result.append(meta)
            }
            if let content = try? Data(contentsOf: file) {
                result.append(content)
            }
            if let end = "\r\n--<ios_task>--\r".data(using: .utf8, allowLossyConversion: false) {
                result.append(end)
            }
            return result
        }
    }
    
    enum NetworkError: Error {
        case common
    }
}
