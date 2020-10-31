//
//  UIAlertController+Actions.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func addActions(_ actions: [UIAlertAction]) {
        actions.forEach({ addAction($0) })
    }
}
