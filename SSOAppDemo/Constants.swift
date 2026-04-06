//
//  Constants.swift
//  SSOAppDemo
//
//  Created by Nguyen Quyet on 3/4/26.
//

import Foundation

struct Constants {
    static let clientId = "test_cicd"
    static let redirectUrl = "base.keycloak.plugin:/login-callback"
    static let discoveryUrl = "https://sso2.quochoi.vn/realms/test/.well-known/openid-configuration"
    static let logoutEndpoint = "https://sso2.quochoi.vn/realms/test/protocol/openid-connect/logout"
    static let postLogoutRedirectUrl = "base.keycloak.plugin:/logout-callback"
    static let scopes: [String] = ["openid", "email", "profile", "offline_access"]
    static let accessGroup = "YGN5L7SCM3.com.viettel.sso.shared"
}
