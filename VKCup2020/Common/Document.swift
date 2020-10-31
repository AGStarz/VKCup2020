//
//  Document.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 22.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

protocol Document {
    var id: Int { get }
    var ownerId: Int { get }
    var date: Int { get } // unix
    var ext: String { get }
    var size: Int { get } // bytes
    var title: String { get }
    var type: Int { get }
    var url: URL { get }
    var tags: [String] { get }
    var preview: [Preview: URL]? { get }
}
