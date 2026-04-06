//
//  SSOAppDemoApp.swift
//  SSOAppDemo
//
//  Created by Nguyen Quyet on 12/3/26.
//

import SwiftUI
import MySSOSDK

@main
struct SSOAppDemoApp: App {
    
    @StateObject private var appRouter = AppRouter()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("App received URL: \(url.absoluteString)")
                    _ = SDKSSOManager.shared.handleRedirect(url: url)
                }
                .environmentObject(appRouter)
        }
    }
}
