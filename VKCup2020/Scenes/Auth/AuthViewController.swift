//
//  AuthViewController.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 26.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit
import VK_ios_sdk

protocol AuthManager: AnyObject {
    func logout()
}

class AuthViewController: UIViewController {
    
    lazy var vkSdk: VKSdk = {
        let instance: VKSdk = .initialize(withAppId: "7321279", apiVersion: "5.103")
        return instance
    }()
    
    lazy var determinatingAuthStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let indicator: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            indicator = UIActivityIndicatorView(style: .medium)
        } else {
            indicator = UIActivityIndicatorView()
        }
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        return view
    }()
    
    lazy var noAuthStateView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let vkLogo = UIImageView(image: #imageLiteral(resourceName: "vk_logo"))
        vkLogo.translatesAutoresizingMaskIntoConstraints = false
        vkLogo.contentMode = .scaleAspectFit
        view.addSubview(vkLogo)
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        titleLabel.text = "Документы"
        titleLabel.numberOfLines = 0
        view.addSubview(titleLabel)
        
        let collectionViewLayout = UICollectionViewFlowLayout()
        let width = UIScreen.main.bounds.width / 3 - 20
        collectionViewLayout.itemSize = CGSize(width: width, height: width)
        
        let collectionView = UICollectionView(frame: .zero,
                                              collectionViewLayout: collectionViewLayout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.register(cellClass: ImageCollectionCell.self)
        view.addSubview(collectionView)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "несколькими касаниями группируйте список или ищете прямо по названию файла"
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.font = .preferredFont(forTextStyle: .title3)
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)
        
        let button = ButtonContainerView()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.onTap = auth
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            vkLogo.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                            constant: 15),
            vkLogo.topAnchor.constraint(equalTo: view.topAnchor,
                                        constant: 24),
            vkLogo.heightAnchor.constraint(equalToConstant: 40),
            vkLogo.widthAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: vkLogo.trailingAnchor,
                                                constant: 15),
            titleLabel.topAnchor.constraint(equalTo: view.topAnchor,
                                            constant: 24),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor,
                                                 constant: -8),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                constant: 64),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                    constant: 15),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                     constant: -15),
            collectionView.heightAnchor.constraint(equalToConstant: width * 2 + 10),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor,
                                                   constant: 15),
            subtitleLabel.topAnchor.constraint(equalTo: collectionView.bottomAnchor,
                                               constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor,
                                                    constant: -15),
            
            button.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        return view
    }()
    
    var state: AuthState = .determinating {
        didSet {
            update()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        vkSdk.register(self)
        vkSdk.uiDelegate = self
        
        setup()
        update()
        
        VKSdk.wakeUpSession(["docs"]) { [weak self] (state, error) in
            guard let strongSelf = self else { return }
            DispatchQueue.main.perform(block: strongSelf.process, param: state)
        }
    }
    
    func process(state: VKAuthorizationState) {
        switch state {
        case .authorized:
            self.state = .authorized
        default:
            self.state = .none
        }
    }
    
    func setup() {
        [noAuthStateView, determinatingAuthStateView].forEach({
            view.addSubview($0)
            $0.safeWrap(in: view)
        })
    }
    
    func update() {
        [noAuthStateView, determinatingAuthStateView].forEach({
            $0.isHidden = true
        })
        
        switch state {
        case .determinating:
            determinatingAuthStateView.isHidden = false
        case .authorized:
            let controller = Assembly.makeDocumentsListController(authManager: self)
            let navController = UINavigationController(rootViewController: controller)
            navController.navigationBar.prefersLargeTitles = true
            navController.modalPresentationStyle = .overCurrentContext
            present(navController, animated: false, completion: nil)
        case .none:
            noAuthStateView.isHidden = false
        }
    }
    
    func auth() {
        state = .determinating
        
        VKSdk.authorize(["docs"])
    }
}

extension AuthViewController: VKSdkDelegate {
    
    func vkSdkAccessAuthorizationFinished(with result: VKAuthorizationResult!) {
        guard let token = result?.token, !token.isExpired() else {
            return DispatchQueue.main.perform(block: process, param: result.state)
        }
        DispatchQueue.main.perform(block: process, param: .authorized)
    }
    
    func vkSdkUserAuthorizationFailed() {
        DispatchQueue.main.perform(block: process, param: .unknown)
    }
    
    func vkSdkAuthorizationStateUpdated(with result: VKAuthorizationResult!) {
        vkSdkAccessAuthorizationFinished(with: result)
    }
}

extension AuthViewController: VKSdkUIDelegate {
    
    func vkSdkShouldPresent(_ controller: UIViewController!) {
        present(controller, animated: true, completion: nil)
    }
    
    func vkSdkNeedCaptchaEnter(_ captchaError: VKError!) { }
}

extension AuthViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return DocumentImageFactory.availableDocumentsImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(at: indexPath) as ImageCollectionCell
        cell.imageView.image = DocumentImageFactory.availableDocumentsImages[indexPath.row]
        return cell
    }
}

extension AuthViewController: AuthManager {
    
    func logout() {
        VKSdk.forceLogout()
        
        state = .none
    }
}

extension AuthViewController {
    
    enum DocumentImageFactory {
        
        static let availableDocumentsImages: [UIImage] = [#imageLiteral(resourceName: "video"), #imageLiteral(resourceName: "music"), #imageLiteral(resourceName: "image"), #imageLiteral(resourceName: "ebook"), #imageLiteral(resourceName: "archive"), #imageLiteral(resourceName: "text")]
    }
   
    enum AuthState {
        case determinating
        case authorized
        case none
    }
    
    enum Assembly {
        
        static func makeDocumentsListController(authManager: AuthManager) -> UIViewController {
            let viewController = DocumentsListViewController()
            let presenter = VKDocumentsListPresenter(delegate: viewController,
                                                     viewController: viewController)
            presenter.authManager = authManager
            viewController.presenter = presenter
            return viewController
        }
    }
}

final class ImageCollectionCell: UICollectionViewCell {
    
    let imageView: UIImageView = {
        let imageView = UIImageView(image: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        imageView.wrap(in: contentView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
