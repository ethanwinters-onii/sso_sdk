//
//  ContentView.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 2/4/26.
//

import SwiftUI
import MySSOSDK

struct ContentView: View {
    @State private var errorMessage: String?
    
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        NavigationStack(path: $router.path) {
            VStack(alignment: .center) {
                Text("Welcome to AppDemo 2")
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                
                Button("Sign In") {
                    login()
                }
                .frame(height: 55.0)
                .frame(maxWidth: .infinity)
                .buttonStyle(
                    BorderedButtonStyle()
                )
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 12))
            }
            .navigationDestination(for: Route.self) { value in
                if value == .home {
                    HomeView()
                }
            }
        }
        .alert("Sign In Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
    }
}

extension ContentView {
    private func login() {
        guard let rootVC = UIApplication.shared.topViewController else {
            errorMessage = "Cannot find active view controller"
            return
        }

        guard let discoveryURL = URL(string: Constants.discoveryUrl),
              let redirectURL = URL(string: Constants.redirectUrl) else {
            errorMessage = "Invalid SDK configuration URL"
            return
        }

        let config = SSOConfig(
            discoveryURL: discoveryURL,
            clientId: Constants.clientId,
            redirectURL: redirectURL,
            scopes: Constants.scopes,
            allowInsecureConnection: false,
            prefersEphemeralSession: true,
            accessGroup: Constants.accessGroup
        )
        
        SDKSSOManager.shared.authorize(
            config: config,
            presentingViewController: rootVC
        ) { authorizeResult in
            switch authorizeResult {
            case .success(let code):
              SDKSSOManager.shared.exchangeCode { tokenResult in
                switch tokenResult {
                case .success:
                    DispatchQueue.main.async {
                        router.goToHome()
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    DispatchQueue.main.async {
                        errorMessage = error.localizedDescription
                    }
                }
              }
            case .failure(let error):
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
