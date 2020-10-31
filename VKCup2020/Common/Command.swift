//
//  Command.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 16.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import Foundation

protocol Command {
    var target: Any? { get }
    var selector: Selector { get }
}
