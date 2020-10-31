//
//  Preview.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 26.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

enum Preview: String {
    case m, s, x, y, z, o, i, d
}

enum PreviewFactory {
    
    static func screenRelated(from dictionary: [Preview: URL]) -> URL? {
        let scale = UIScreen.main.scale
        
        let smallest = dictionary[.m] ?? dictionary[.s]
        guard scale > 1 else {
            return smallest
        }
        
        let medium = dictionary[.d] ?? smallest
        guard scale > 2 else {
            return medium
        }
        
        return dictionary[.i] ?? medium
    }
}
