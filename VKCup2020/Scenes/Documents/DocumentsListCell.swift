//
//  DocumentCell.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 16.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

enum DocumentCellViewModelState {
    case ready(Command)
    case renaming
    case removing
}

protocol DocumentCellViewModel {
    var title: String { get }
    var subtitle: String { get }
    var tags: [String] { get }
    var state: DocumentCellViewModelState { get }
    var imageProvider: ImageProvider { get }
    var select: () -> Void { get }
}

class DocumentsListCell: UICollectionViewCell {
    
    let margins = UIEdgeInsets(top: 4, left: 15, bottom: -4, right: -15)
    
    lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        let constraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor)
        constraint.priority = UILayoutPriority(999)
        constraint.isActive = true
        
        return imageView
    }()
    
    lazy var tagImageView: UIImageView = {
        let imageView = UIImageView(image: #imageLiteral(resourceName: "tag"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        if #available(iOS 13.0, *) {
            imageView.tintColor = UIColor.systemFill
        } else {
            imageView.tintColor = UIColor.lightGray
        }
        
        [
            imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 12)
        ]
        .forEach { (constraint) in
            constraint.priority = UILayoutPriority(999)
            constraint.isActive = true
        }
        
        return imageView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()
    
    lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        return label
    }()
    
    lazy var tagsLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        return label
    }()
    
    lazy var tagStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [tagImageView, tagsLabel])
        stackView.axis = .horizontal
        stackView.spacing = 4
        return stackView
    }()
    
    lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "more"), for: .normal)
        button.setTitle("", for: .normal)
        return button
    }()
    
    lazy var processingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = false
        indicator.isHidden = true
        return indicator
    }()
    
    lazy var actionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [actionButton, processingIndicator])
        stackView.axis = .vertical
        stackView.alignment = .trailing
        
        let constraint = processingIndicator.widthAnchor.constraint(equalTo: actionButton.widthAnchor)
        constraint.priority = UILayoutPriority(rawValue: 999)
        constraint.isActive = true
        
        return stackView
    }()
    
    lazy var descriptionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, tagStackView])
        stackView.spacing = 6
        stackView.axis = .vertical
        
        let finalStackView = UIStackView(arrangedSubviews: [stackView])
        finalStackView.alignment = .center
        finalStackView.axis = .horizontal
        
        return finalStackView
    }()
    
    lazy var rootStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconImageView, descriptionStackView, actionStackView])
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        return stackView
    }()
    
    private var previewProviderToken: Cancellable?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(rootStackView)
        rootStackView.wrap(in: contentView, with: margins)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        titleLabel.text = nil
        previewProviderToken?.cancel()
        
        super.prepareForReuse()
    }
    
    func set(viewModel: DocumentCellViewModel) {
        titleLabel.text = viewModel.title
        subtitleLabel.text = viewModel.subtitle
        
        tagsLabel.text = viewModel.tags.joined(separator: ", ")
        tagStackView.isHidden = viewModel.tags.isEmpty
        
        actionButton.removeTarget(nil, action: nil, for: .allEvents)
        switch viewModel.state {
        case .ready(let command):
            processingIndicator.isHidden = true
            actionButton.isHidden = false
            actionButton.addTarget(command.target, action: command.selector, for: .touchUpInside)
        default:
            actionButton.isHidden = true
            processingIndicator.isHidden = false
            processingIndicator.startAnimating()
        }
        
        previewProviderToken = viewModel.imageProvider.image { [weak self] (result) in
            guard let strongSelf = self else { return }
            
            switch result {
            case .success(let image):
                strongSelf.iconImageView.image = image
            case .failure:
                strongSelf.iconImageView.image = nil
            }
        }
    }
}
