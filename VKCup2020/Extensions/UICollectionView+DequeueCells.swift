//
//  UICollectionView+DequeueCells.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 16.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

extension UICollectionView {
    
    func dequeueReusableCell<T: UICollectionViewCell>(at indexPath: IndexPath) -> T {
        let identifier = String(describing: T.self)
        guard let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as? T else { fatalError() }
        return cell
    }
    
    func dequeueReusableView<T: UICollectionReusableView>(at indexPath: IndexPath,
                                                            kind: String = UICollectionView.elementKindSectionHeader) -> T {
        let identifier = String(describing: T.self)
        guard let view = dequeueReusableSupplementaryView(ofKind: kind,
                                                          withReuseIdentifier: identifier,
                                                          for: indexPath) as? T else { fatalError() }
        return view
    }
    
    func register<T: UICollectionViewCell>(cellClass: T.Type) {
        let identifier = String(describing: T.self)
        register(T.self, forCellWithReuseIdentifier: identifier)
    }
    
    func register<T: UICollectionReusableView>(reusableView: T.Type,
                                               kind: String = UICollectionView.elementKindSectionHeader) {
        let identifier = String(describing: T.self)
        register(T.self,
                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                 withReuseIdentifier: identifier)
    }
}
