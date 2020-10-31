//
//  ButtonContainerView.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 28.10.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

final class ButtonContainerView: UIView {
    
    private let margins = UIEdgeInsets(top: 8, left: 15, bottom: -8, right: -15)
    
    private let button: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(named: "VK")
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 8
        button.setTitle("Войти через ВКонтакте", for: .normal)
        return button
    }()
    
    var onTap: (() -> Void)?
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: 72)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(button)
        button.wrap(in: self, with: margins)
        
        button.addTarget(self, action: #selector(click), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func click() {
        onTap?()
    }
}
