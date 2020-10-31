//
//  Cancellable.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

protocol Cancellable {
    func cancel()
}

struct AnyCancellable: Cancellable {
    func cancel() { }
}

extension URLSessionDataTask: Cancellable {  }
