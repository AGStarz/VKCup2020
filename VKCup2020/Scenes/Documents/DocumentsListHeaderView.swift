//
//  DocumentsListHeaderView.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 27.10.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

protocol FilterViewModel {
    var icon: UIImage? { get }
    var title: String? { get }
    var selected: Bool { get }
}

final class DocumentsListHeaderView: UICollectionReusableView {
    
    let label: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Коснитесь до интересующих типов файлов для быстрой фильтрации списка"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        return label
    }()
    
    lazy var filtersCollectionView: UICollectionView = {
        let collectionViewLayout = UICollectionViewFlowLayout()
        collectionViewLayout.itemSize = CGSize(width: 80, height: 120)
        collectionViewLayout.sectionInset = .init(top: 0, left: 8, bottom: 0, right: 8)
        collectionViewLayout.scrollDirection = .horizontal
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: collectionViewLayout)
        collectionView.allowsMultipleSelection = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(cellClass: HeaderFilterCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    lazy var filters = [Filter(id: 7, icon: #imageLiteral(resourceName: "ebook"), title: "Книги", selected: false),
                        Filter(id: 6, icon: #imageLiteral(resourceName: "video"), title: "Видео", selected: false),
                        Filter(id: 4, icon: #imageLiteral(resourceName: "image"), title: "Фото", selected: false),
                        Filter(id: 5, icon: #imageLiteral(resourceName: "music"), title: "Аудио", selected: false),
                        Filter(id: 1, icon: #imageLiteral(resourceName: "text"), title: "Текстовые", selected: false),
                        Filter(id: 2, icon: #imageLiteral(resourceName: "archive"), title: "Архивы", selected: false),
                        Filter(id: 8, icon: #imageLiteral(resourceName: "other"), title: "Другое", selected: false)]
    
    var onSelectFilter: ((Int, Bool) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(label)
        addSubview(filtersCollectionView)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 15),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                           constant: 24),
            filtersCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            filtersCollectionView.topAnchor.constraint(equalTo: label.bottomAnchor,
                                                       constant: 8),
            filtersCollectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            filtersCollectionView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                          constant: -15)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DocumentsListHeaderView: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(at: indexPath) as HeaderFilterCell
        cell.set(viewModel: filters[indexPath.row])
        return cell
    }
}

extension DocumentsListHeaderView: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        filters[indexPath.row].selected.toggle()
        
        onSelectFilter?(filters[indexPath.row].id, true)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didDeselectItemAt indexPath: IndexPath) {
        filters[indexPath.row].selected.toggle()
        
        onSelectFilter?(filters[indexPath.row].id, false)
    }
}

extension DocumentsListHeaderView {
    
    struct Filter: FilterViewModel {
        let id: Int
        let icon: UIImage?
        let title: String?
        var selected: Bool
    }
    
    final class HeaderFilterCell: UICollectionViewCell {
        
        lazy var iconImageView: UIImageView = {
            let imageView = UIImageView(image: nil)
            imageView.contentMode = .scaleAspectFit
            imageView.layer.cornerRadius = 8
            imageView.layer.masksToBounds = true
            imageView.layer.borderWidth = max(UIScreen.main.scale, UIScreen.main.nativeScale)
            imageView.layer.borderColor = UIColor.clear.cgColor
            imageView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                imageView.heightAnchor.constraint(equalToConstant: 80),
                imageView.widthAnchor.constraint(equalToConstant: 80)
            ])
            return imageView
        }()
        
        lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()
        
        override var isSelected: Bool {
            didSet {
                iconImageView.layer.borderColor = isSelected
                    ? UIColor(named: "VK")?.cgColor
                    : UIColor.clear.cgColor
            }
        }
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            contentView.addSubview(iconImageView)
            contentView.addSubview(titleLabel)
            
            NSLayoutConstraint.activate([
                iconImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                iconImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
                titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            ])
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func set(viewModel: FilterViewModel) {
            iconImageView.image = viewModel.icon
            titleLabel.text = viewModel.title
            isSelected = viewModel.selected
        }
    }
}
