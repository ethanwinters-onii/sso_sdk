//
//  HomeViewModel.swift
//  SSOAppDemo2
//
//  Created by Nguyen Quyet on 3/4/26.
//

import SwiftUI
import Combine
import MySSOSDK

class HomeViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var accessToken: String = ""
    @Published var idToken: String = ""
    @Published var refreshToken: String = ""
    
    init() {
        getTokens()
    }
    
    func getTokens() {
        isLoading = true
        SDKSSOManager.shared.getTokens { result in
            switch result {
            case .success(let token):
                if let token = token as? [String:String] {
                    self.accessToken = token["accessToken"] ?? ""
                    self.idToken = token["idToken"] ?? ""
                    self.refreshToken = token["refreshToken"] ?? ""
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        self.isLoading = false
    }
    
    func saveAndUpdateTokens(_ token: SSOToken) {
        self.accessToken = token.accessToken ?? ""
        self.idToken = token.idToken ?? ""
        self.refreshToken = token.refreshToken ?? ""
    }
}
