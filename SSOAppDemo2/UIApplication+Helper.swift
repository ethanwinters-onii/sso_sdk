//
//  UIApplication+Helper.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 3/4/26.
//

import UIKit

extension UIApplication {
    var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    var topViewController: UIViewController? {
        guard let root = activeKeyWindow?.rootViewController else {
            return nil
        }
        return Self.topViewController(from: root)
    }

    private static func topViewController(from vc: UIViewController) -> UIViewController {
        if let nav = vc as? UINavigationController {
            return topViewController(from: nav.visibleViewController ?? nav)
        }
        if let tab = vc as? UITabBarController {
            return topViewController(from: tab.selectedViewController ?? tab)
        }
        if let presented = vc.presentedViewController {
            return topViewController(from: presented)
        }
        return vc
    }
}
