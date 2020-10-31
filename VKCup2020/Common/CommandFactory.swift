//
//  CommandFactory.swift
//  VKCup2020
//
//  Created by Vasily Agafonov on 23.02.2020.
//  Copyright © 2020 vagafonov. All rights reserved.
//

import UIKit

enum CommandFactory {
    
    static func showMenu(onShow: @escaping (UIViewController) -> Void,
                         onRename: @escaping () -> Void,
                         onRemove: @escaping () -> Void,
                         onClone: @escaping () -> Void) -> Command {
        return ShowMenu {
            let alert = AlertFactory.menuAlert(onRename: onRename,
                                               onRemove: onRemove,
                                               onClone: onClone)
            onShow(alert)
        }
    }
    
    static func showLogout(onShow: @escaping (UIViewController) -> Void,
                           onLogout: @escaping () -> Void) -> Command {
        return ShowMenu {
            let alert = AlertFactory.authAlert(onLogout: onLogout)
            onShow(alert)
        }
    }
    
    class ShowMenu: Command {
        
        let onShow: () -> Void
        
        var selector: Selector {
            return #selector(perform)
        }
        
        var target: Any? {
            return self
        }
        
        init(onShow: @escaping () -> Void) {
            self.onShow = onShow
        }
        
        @objc
        func perform() {
            onShow()
        }
    }
}
