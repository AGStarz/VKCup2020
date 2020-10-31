//
//  DispatchQueue+Perform.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

extension DispatchQueue {
    
    func perform<T>(block: @escaping (T) -> Void, param: T) {
        async {
            block(param)
        }
    }
}
