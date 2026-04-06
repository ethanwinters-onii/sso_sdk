//
//  AppRouter.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 3/4/26.
//

import SwiftUI
import Combine

// MARK: - Route
enum Route: Hashable {
    case home
}

// MARK: - Router
class AppRouter: ObservableObject {
    @Published var path = NavigationPath()

    func goToHome() {
        path.append(Route.home)
    }

    func goBack() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    func popToRoot() {
        path = NavigationPath()
    }
}
