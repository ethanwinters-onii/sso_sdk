//
//  SSOAppDemo2App.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 2/4/26.
//

import SwiftUI

@main
struct SSOAppDemo2App: App {
    
    @StateObject private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appRouter)
        }
    }
}
