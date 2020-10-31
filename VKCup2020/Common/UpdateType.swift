//
//  UpdateType.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 17.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

enum UpdateType {
    case reload([IndexPath])
    case insert([IndexPath])
    case remove([IndexPath])
    case reloadData
}
