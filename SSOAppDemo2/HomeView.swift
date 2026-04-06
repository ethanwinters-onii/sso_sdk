//
//  HomeView.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 3/4/26.
//

import SwiftUI
import MySSOSDK

struct HomeView: View {
    
    @EnvironmentObject var appRouter: AppRouter
    @StateObject var vm = HomeViewModel()
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        VStack(alignment: .center) {
            if vm.isLoading {
                ProgressView()
            } else {
                Text("Access Token: \(String(vm.accessToken.prefix(50)))...")
                    .font(.caption)
                
                Button("Refresh Token") {
                    refreshToken()
                }
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .buttonStyle(
                    BorderedProminentButtonStyle()
                )
            }
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "Unknown error")
        }
        .alert("Success", isPresented: Binding(
            get: { successMessage != nil },
            set: { if !$0 { successMessage = nil } }
        )) {
            Button("OK", role: .cancel) { successMessage = nil }
        } message: {
            Text(successMessage ?? "")
        }
        .navigationTitle("Home")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.automatic)
                .toolbar {
                    ToolbarItem (placement: .navigationBarLeading) {
                        Button {

                        } label: {
                            Image(systemName: "person.fill")
                        }

                    }
                    
                    ToolbarItem (placement: .navigationBarTrailing) {
                        Button {
                            endSession()
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.forward")
                        }

                    }
                    
                    ToolbarItem (placement: .keyboard) {
                        Image(systemName: "rectangle.portrait.and.arrow.forward")
                    }
                }
        
    }
    
}

extension HomeView {
    private func refreshToken() {
        SDKSSOManager.shared.refreshToken { result in
            switch result {
                case .success(let token):
                    vm.saveAndUpdateTokens(token)
                    guard let accessToken = token.accessToken else {
                        return
                    }
                    let tokenPreview = String(accessToken.prefix(50)) + "..."
                    successMessage = "New Access Token:\n\(tokenPreview)"
                case .failure(let error):
                    errorMessage = "Refresh failed\n\(error.localizedDescription)"
            }
        }
    }
    
    private func endSession() {
        guard let rootVC = UIApplication.shared.topViewController else {
            return
        }

        let logoutEndpoint = URL(string: Constants.logoutEndpoint)!
        let redirectURI = URL(string: Constants.postLogoutRedirectUrl)!

        SDKSSOManager.shared.endSession(
            idToken: vm.idToken,
            logoutEndpoint: logoutEndpoint,
            postLogoutRedirectURL: redirectURI,
            presentingViewController: rootVC
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let callbackURL):
                    appRouter.popToRoot()
                case .failure(let error):
                    errorMessage = "End session failed\n\(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    HomeView()
}
