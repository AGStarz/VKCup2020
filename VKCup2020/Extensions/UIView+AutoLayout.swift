//
//  UIView+AutoLayout.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 16.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

extension UIView {
    
    var layoutGuide: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }
    
    func safeWrap(in view: UIView, with insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.layoutGuide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.layoutGuide.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: view.layoutGuide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.layoutGuide.bottomAnchor, constant: insets.bottom)
        ])
    }
    
    func wrap(in view: UIView, with insets: UIEdgeInsets = .zero) {
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: insets.bottom)
        ])
    }
}
