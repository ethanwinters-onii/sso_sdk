//
//  MySSOSDK.swift
//  MySSOSDK
//
//  Created by Nguyen Quyet on 12/3/26.
//

import Foundation
import UIKit
@_implementationOnly import AppAuth
import AuthenticationServices

public struct SSOConfig {
    public let discoveryURL: URL
    public let clientId: String
    public let redirectURL: URL
    public let scopes: [String]
    public let allowInsecureConnection: Bool
    public let prefersEphemeralSession: Bool
    public let accessGroup: String

    public init(
        discoveryURL: URL,
        clientId: String,
        redirectURL: URL,
        scopes: [String],
        allowInsecureConnection: Bool = false,
        prefersEphemeralSession: Bool = false,
        accessGroup: String
    ) {
        self.discoveryURL = discoveryURL
        self.clientId = clientId
        self.redirectURL = redirectURL
        self.scopes = scopes
        self.allowInsecureConnection = allowInsecureConnection
        self.prefersEphemeralSession = prefersEphemeralSession
        self.accessGroup = accessGroup
    }
}

public struct SSOToken {
    public let accessToken: String?
    public let idToken: String?
    public let refreshToken: String?

    public init(
        accessToken: String?,
        idToken: String?,
        refreshToken: String?
    ) {
        self.accessToken = accessToken
        self.idToken = idToken
        self.refreshToken = refreshToken
    }
}

public enum SSOError: Error {
    case invalidDiscovery
    case authorizationFailed(String)
    case noAuthState
    case noAuthorizationResponse
    case invalidAuthorizationCode
    case noIDToken
    case invalidLogoutURL
}

// MARK: - Insecure session delegate (HTTP / self-signed HTTPS)
private final class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let trust = challenge.protectionSpace.serverTrust {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}

public final class SDKSSOManager: NSObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = SDKSSOManager()

    private let storage = KeychainService.shared
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var endSessionFlow: ASWebAuthenticationSession?
    private var authState: OIDAuthState?
    private var pendingAuthorizationResponse: OIDAuthorizationResponse?
    private weak var presentationAnchorWindow: UIWindow?
    private var prefersEphemeralSession: Bool = false

    private lazy var insecureURLSession: URLSession = {
        URLSession(
            configuration: .default,
            delegate: InsecureURLSessionDelegate(),
            delegateQueue: nil
        )
    }()

    private override init() {
        super.init()
    }

    private func configureSessionIfNeeded() {
//        guard issuer.scheme?.lowercased() == "http" else { return }
        OIDURLSessionProvider.setSession(insecureURLSession)
    }
    
    private func saveTokens(_ token: SSOToken) {
        storage.save(token.accessToken!, for: .accessToken)
        storage.save(token.idToken!, for: .idToken)
        storage.save(token.refreshToken!, for: .refreshToken)
    }
    
    private func checkExistTokens() -> Bool {
        if let _ = storage.getValue(for: .accessToken),
           let __ = storage.getValue(for: .idToken),
           let ___ = storage.getValue(for: .refreshToken) {
            return true
        }
        return false
    }

    public func authorize(
        config: SSOConfig,
        presentingViewController: UIViewController,
        completion: @escaping (Result<NSDictionary, Error>) -> Void
    ) {
        storage.accessGroup = config.accessGroup
        self.prefersEphemeralSession = config.prefersEphemeralSession
        if config.prefersEphemeralSession && self.checkExistTokens() {
            completion(.success([
                "status": "success"
            ]))
        } else {
            if config.allowInsecureConnection {
                configureSessionIfNeeded()
            }
            OIDAuthorizationService.discoverConfiguration(forDiscoveryURL: config.discoveryURL) { [weak self] serviceConfig, error in
                guard let self, let serviceConfig else {
                    completion(.failure(error ?? SSOError.invalidDiscovery))
                    return
                }
                
                let request = OIDAuthorizationRequest(
                    configuration: serviceConfig,
                    clientId: config.clientId,
                    clientSecret: nil,
                    scopes: config.scopes,
                    redirectURL: config.redirectURL,
                    responseType: OIDResponseTypeCode,
                    additionalParameters: nil
                )
                
                let externalUserAgent = OIDExternalUserAgentIOS(presenting: presentingViewController, prefersEphemeralSession: config.prefersEphemeralSession)

                self.currentAuthorizationFlow = OIDAuthorizationService.present(
                    request,
                    externalUserAgent: externalUserAgent!
    //                presenting: presentingViewController
                ) { [weak self] authorizationResponse, error in
                    guard let self else { return }

                    if let authorizationResponse {
                        self.pendingAuthorizationResponse = authorizationResponse
                        self.authState = OIDAuthState(authorizationResponse: authorizationResponse)
                        
                        guard let authorizationCode = authorizationResponse.authorizationCode else {
                            completion(.failure(SSOError.invalidAuthorizationCode))
                            return
                        }
                        
                        guard let codeVerifier = request.codeVerifier else {
                            completion(.failure(SSOError.authorizationFailed("Invalid code verifier")))
                            return
                        }
                        
    //                    print("Code Verifier: \(request.codeVerifier)")
                        
                        completion(.success([
                            "authorizationCode": authorizationCode,
                            "codeVerifier": codeVerifier
                        ]))
                    } else {
                        completion(.failure(error ?? SSOError.authorizationFailed("Unknown error")))
                    }
                }
            }
        }
    }

    public func exchangeCode(
        completion: @escaping (Result<SSOToken, Error>) -> Void
    ) {
        if self.prefersEphemeralSession && self.checkExistTokens() {
            completion(.success(SSOToken(
                accessToken: storage.getValue(for: .accessToken),
                idToken: storage.getValue(for: .idToken),
                refreshToken: storage.getValue(for: .refreshToken)
            )))
            
            return
        }
        
        guard let authorizationResponse = pendingAuthorizationResponse else {
            completion(.failure(SSOError.noAuthorizationResponse))
            return
        }

        guard let tokenRequest = authorizationResponse.tokenExchangeRequest() else {
            completion(.failure(SSOError.invalidAuthorizationCode))
            return
        }

        OIDAuthorizationService.perform(
            tokenRequest,
            originalAuthorizationResponse: authorizationResponse
        ) { [weak self] tokenResponse, error in
            guard let self else { return }

            if let tokenResponse {
                if let authState = self.authState {
                    authState.update(with: tokenResponse, error: nil)
                } else {
                    self.authState = OIDAuthState(
                        authorizationResponse: authorizationResponse,
                        tokenResponse: tokenResponse
                    )
                }

                self.pendingAuthorizationResponse = nil
                let token = SSOToken(
                    accessToken: tokenResponse.accessToken,
                    idToken: tokenResponse.idToken,
                    refreshToken: tokenResponse.refreshToken
                )
                self.saveTokens(token)
                completion(.success(token))
            } else {
                completion(.failure(error ?? SSOError.authorizationFailed("Code exchange failed")))
            }
        }
    }

    public func handleRedirect(url: URL) -> Bool {
        if let flow = currentAuthorizationFlow, flow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }

    public func getTokens(
        completion: @escaping (Result<NSDictionary, Error>) -> Void
    ) {
        if (checkExistTokens()) {
            completion(.success([
                "accessToken": storage.getValue(for: .accessToken)!,
                "idToken": storage.getValue(for: .idToken)!,
                "refreshToken": storage.getValue(for: .refreshToken)!
            ]))
        } else {
            completion(.failure(SSOError.noIDToken))
        }
    }

    public func refreshToken(
        completion: @escaping (Result<SSOToken, Error>) -> Void
    ) {
        guard let authState else {
            completion(.failure(SSOError.noAuthState))
            return
        }

        authState.performAction { [weak self] accessToken, idToken, error in
            guard let self else { return }

            if let error {
                completion(.failure(error))
                return
            }

            let token = SSOToken(
                accessToken: accessToken,
                idToken: idToken,
                refreshToken: authState.lastTokenResponse?.refreshToken
                    ?? self.storage.getValue(for: .refreshToken) as? String
            )
            self.saveTokens(token)
            completion(.success(token))
        }
    }

//    public func signOut() {
//        authState = nil
//        currentAuthorizationFlow = nil
//        endSessionFlow = nil
//        presentationAnchorWindow = nil
//        storage.clearAll()
//    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let presentationAnchorWindow {
            return presentationAnchorWindow
        }

        if let keyWindow = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })) {
            return keyWindow
        }

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return ASPresentationAnchor(windowScene: scene)
        }

        return UIWindow(frame: .zero)
    }
    
    public func endSession(
        idToken: String? = nil,
        logoutEndpoint: URL,
        postLogoutRedirectURL: URL,
        presentingViewController: UIViewController,
        completion: ((Result<URL?, Error>) -> Void)? = nil
    ) {
        presentationAnchorWindow = presentingViewController.view.window

        // let idToken = authState?.lastTokenResponse?.idToken
        //   ?? authState?.lastAuthorizationResponse.idToken

        guard let idTokenToUse = idToken else {
            completion?(.failure(SSOError.noIDToken))
            return
        }

        var components = URLComponents(url: logoutEndpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "id_token_hint", value: idTokenToUse),
            URLQueryItem(name: "post_logout_redirect_uri", value: postLogoutRedirectURL.absoluteString)
        ]

        guard let logoutURL = components.url else {
            completion?(.failure(SSOError.invalidLogoutURL))
            return
        }

        let session = ASWebAuthenticationSession(
            url: logoutURL,
            callbackURLScheme: postLogoutRedirectURL.scheme
        ) { [weak self] callbackURL, error in
            defer {
                self?.endSessionFlow = nil
                self?.presentationAnchorWindow = nil
            }

            if let error {
                completion?(.failure(error))
                return
            }

            self?.authState = nil
            self?.currentAuthorizationFlow = nil
            self?.storage.clearAll()
            completion?(.success(callbackURL))
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = true
        endSessionFlow = session

        guard session.start() else {
            endSessionFlow = nil
            completion?(.failure(SSOError.authorizationFailed("Cannot start end-session flow")))
            return
        }
    }
}
