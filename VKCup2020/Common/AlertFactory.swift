//
//  AlertFactory.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

enum AlertFactory {
    
    static func authAlert(onLogout: @escaping () -> Void) -> UIViewController {
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Разлогиниться", style: .destructive) { _ in onLogout() },
            UIAlertAction(title: "Отмена", style: .cancel) { _ in }
        ]
        alert.addActions(actions)
        return alert
    }
    
    static func menuAlert(onRename: @escaping () -> Void,
                          onRemove: @escaping () -> Void,
                          onClone: @escaping () -> Void) -> UIViewController {
        let alert = UIAlertController(title: nil,
                                      message: nil,
                                      preferredStyle: .actionSheet)
        let actions = [
            UIAlertAction(title: "Создать копию файла", style: .default) { _ in onClone() },
            UIAlertAction(title: "Переименовать", style: .default) { _ in onRename() },
            UIAlertAction(title: "Удалить документ", style: .destructive) { _ in onRemove() },
            UIAlertAction(title: "Отменить", style: .cancel) { _ in }
        ]
        alert.addActions(actions)
        return alert
    }
    
    static func cloneAlert(filename: String,
                           onClone: @escaping (String) -> Void,
                           onCancel: @escaping () -> Void) -> UIViewController {
        let cloningAlert = UIAlertController(title: "Придумайте имя новому файлу",
                                              message: nil,
                                              preferredStyle: .alert)
        cloningAlert.addTextField { $0.text = filename }
        
        let actions = [
            UIAlertAction(title: "Сделать копию", style: .default) { _ in
                guard let text = cloningAlert.textFields?.first?.text,
                    !text.isEmpty else { return }
                onClone(text)
            },
            UIAlertAction(title: "Отмена", style: .cancel) { _ in onCancel() }
        ]
        cloningAlert.addActions(actions)
        
        return cloningAlert
    }
    
    static func renameAlert(filename: String,
                            onRename: @escaping (String) -> Void,
                            onCancel: @escaping () -> Void) -> UIViewController {
        let renamingAlert = UIAlertController(title: "Задайте новое имя файла",
                                              message: nil,
                                              preferredStyle: .alert)
        renamingAlert.addTextField { $0.text = filename }
        
        let actions = [
            UIAlertAction(title: "Переименовать", style: .default) { _ in
                guard let text = renamingAlert.textFields?.first?.text,
                    !text.isEmpty else { return }
                onRename(text)
            },
            UIAlertAction(title: "Отмена", style: .cancel) { _ in onCancel() }
        ]
        renamingAlert.addActions(actions)
        
        return renamingAlert
    }
}
