import AppAuth
import AppAuthCore
import Foundation

typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?,
                                      _ registrationResponse: OIDRegistrationResponse?) -> Void

let kAppAuthExampleAuthStateKey: String = "authState"

public class SequenexOpenIdConnectLibrary: NSObject, OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    let issuer: String, clientID: String?, redirectURI: String
    private var authState: OIDAuthState?
    public var onStateChanged: (() -> Void)?
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    public var hasAuthState: Bool { authState != nil }

    public var isAuthorized: Bool { authState?.isAuthorized == true }

    public var isCodeExchangePossible: Bool {
        authState?.lastAuthorizationResponse.authorizationCode != nil && !((authState?.lastTokenResponse) != nil)
    }

    public func clearAuthState() { setAuthState(nil) }

    public init(issuer: String, clientID: String?, redirectURI: String) {
        self.issuer = issuer; self.clientID = clientID; self.redirectURI = redirectURI
        super.init()
        guard let urlTypes: [AnyObject] = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject], urlTypes.count > 0
        else {
            assertionFailure("No custom URI scheme has been configured for the project.")
            return
        }
        guard let items = urlTypes[0] as? [String: AnyObject],
              let urlSchemes = items["CFBundleURLSchemes"] as? [AnyObject], urlSchemes.count > 0
        else {
            assertionFailure("No custom URI scheme has been configured for the project.")
            return
        }
        guard let urlScheme = urlSchemes[0] as? String else {
            assertionFailure("No custom URI scheme has been configured for the project.")
            return
        }
        assert(urlScheme != "com.example.app",
            "Configure the URI scheme in Info.plist (URL Types -> Item 0 -> URL Schemes -> Item 0) " +
                "with the scheme of your redirect URI. Full instructions: " +
                "https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md")
        loadState()
    }

    public func onApplication(_ app: UIApplication, open url: URL,
                              options: [UIApplication.OpenURLOptionsKey: Any]) -> Bool {
        if let authorizationFlow = currentAuthorizationFlow,
           authorizationFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }

    public func authWithAutoCodeExchange(parent: UIViewController) {
        guard let issuer = URL(string: issuer) else {
            print("Error creating URL for : \(issuer)")
            return
        }
        print("Fetching configuration for issuer: \(self.issuer)")
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                print("Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
                return
            }
            print("Got configuration: \(config)")
            if let clientId = self.clientID {
                self.doAuthWithAutoCodeExchange(parent, configuration: config, clientID: clientId, clientSecret: nil)
            } else {
                self.doClientRegistration(configuration: config) { configuration, response in
                    guard let configuration = configuration, let clientID = response?.clientID else {
                        print("Error retrieving configuration OR clientID")
                        return
                    }
                    self.doAuthWithAutoCodeExchange(parent, configuration: configuration,
                        clientID: clientID, clientSecret: response?.clientSecret)
                }
            }
        }
    }

    public func authWithNoCodeExchange(parent: UIViewController) {
        guard let issuer = URL(string: issuer) else {
            print("Error creating URL for : \(issuer)")
            return
        }
        print("Fetching configuration for issuer: \(issuer)")
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            if let error = error {
                print("Error retrieving discovery document: \(error.localizedDescription)")
                return
            }
            guard let configuration = configuration else {
                print("Error retrieving discovery document. Error & Configuration both are NIL!")
                return
            }
            print("Got configuration: \(configuration)")
            if let clientId = self.clientID {
                self.doAuthWithoutCodeExchange(parent, configuration: configuration,
                    clientID: clientId, clientSecret: nil)
            } else {
                self.doClientRegistration(configuration: configuration) { configuration, response in
                    guard let configuration = configuration, let response = response else {
                        return
                    }
                    self.doAuthWithoutCodeExchange(parent, configuration: configuration,
                        clientID: response.clientID, clientSecret: response.clientSecret)
                }
            }
        }
    }

    public func codeExchange() {
        guard let tokenExchangeRequest = authState?.lastAuthorizationResponse.tokenExchangeRequest() else {
            print("Error creating authorization code exchange request")
            return
        }
        print("Performing authorization code exchange with request \(tokenExchangeRequest)")
        OIDAuthorizationService.perform(tokenExchangeRequest, callback: { response, error in
            if let tokenResponse = response {
                let token = tokenResponse.accessToken ?? "DEFAULT_TOKEN"
                print("Received token response with accessToken: \(token)")
            } else {
                print("Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
            }
            self.authState?.update(with: response, error: error)
        })
    }

    public func getUserInfo(onSuccess: @escaping (_ json: [AnyHashable: Any]) -> Void) {
        guard let userinfoEndpoint = authState?.lastAuthorizationResponse.request
            .configuration.discoveryDocument?.userinfoEndpoint
        else {
            print("Userinfo endpoint not declared in discovery document")
            return
        }
        print("Performing userinfo request")
        let currentAccessToken: String? = authState?.lastTokenResponse?.accessToken
        authState?.performAction { (accessToken, _, error) in
            if error != nil {
                print("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }
            guard let accessToken = accessToken else {
                print("Error getting accessToken")
                return
            }
            if currentAccessToken != accessToken {
                let info = "\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken)"
                print("Access token was refreshed automatically (\(info))")
            } else {
                print("Access token was fresh and not updated \(accessToken)")
            }
            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
            self.getUserInfo(with: urlRequest, onSuccess: onSuccess)
        }
    }

    func getUserInfo(with request: URLRequest,
                     onSuccess: @escaping (_ json: [AnyHashable: Any]) -> Void) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                guard error == nil else {
                    print("HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                    return
                }
                guard let response = response as? HTTPURLResponse else {
                    print("Non-HTTP response")
                    return
                }
                guard let data = data else {
                    print("HTTP response data is empty")
                    return
                }
                var json: [AnyHashable: Any]?
                do {
                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    print("JSON Serialization Error")
                }
                if response.statusCode != 200 {
                    let errorText: String? = String(data: data, encoding: String.Encoding.utf8)
                    if response.statusCode == 401 {
                        let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                            errorResponse: json, underlyingError: error)
                        self.authState?.update(withAuthorizationError: oauthError)
                        let response = errorText ?? "RESPONSE_TEXT"
                        print("Authorization Error (\(oauthError)). Response: \(response)")
                    } else {
                        print("HTTP: \(response.statusCode), Response: \(errorText ?? "RESPONSE_TEXT")")
                    }
                    return
                }
                if let json = json {
                    print("Success: \(json)")
                    onSuccess(json)
                }
            }
        }
        task.resume()
    }

    func doClientRegistration(configuration: OIDServiceConfiguration,
                              callback: @escaping PostRegistrationCallback) {
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }
        let request: OIDRegistrationRequest = OIDRegistrationRequest(configuration: configuration,
            redirectURIs: [redirectURI],
            responseTypes: nil,
            grantTypes: nil,
            subjectType: nil,
            tokenEndpointAuthMethod: "client_secret_post",
            additionalParameters: nil)
        print("Initiating registration request")
        OIDAuthorizationService.perform(request) { response, error in
            if let regResponse = response {
                print("Got registration response: \(regResponse)")
                self.setAuthState(OIDAuthState(registrationResponse: regResponse))
                callback(configuration, regResponse)
            } else {
                print("Registration error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
            }
        }
    }

    func doAuthWithAutoCodeExchange(_ parent: UIViewController,
                                    configuration: OIDServiceConfiguration,
                                    clientID: String, clientSecret: String?) {
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }

        let request = OIDAuthorizationRequest(configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request, presenting: parent) { authState, error in
            if let authState = authState {
                let token = authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN"
                print("Got authorization tokens. Access token: \(token)")
                self.setAuthState(authState)
            } else {
                print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
            }
        }
    }

    func doAuthWithoutCodeExchange(_ parent: UIViewController,
                                   configuration: OIDServiceConfiguration,
                                   clientID: String, clientSecret: String?) {
        guard let redirectURI = URL(string: redirectURI) else {
            print("Error creating URL for : \(redirectURI)")
            return
        }
        let request = OIDAuthorizationRequest(configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        print("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        currentAuthorizationFlow = OIDAuthorizationService
            .present(request, presenting: parent) { (response, error) in
                if let response = response {
                    self.setAuthState(OIDAuthState(authorizationResponse: response))
                    print("Authorization response with code: \(response.authorizationCode ?? "DEFAULT_CODE")")
                    // could just call [self tokenExchange:nil] directly, but will let the user initiate it.
                } else {
                    print("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                }
            }
    }

    func saveState() {
        var data: Data?
        if let authState = authState {
            data = try? NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false)
        }
        if let userDefaults = UserDefaults(suiteName: "group.net.openid.appauth.Example") {
            userDefaults.set(data, forKey: kAppAuthExampleAuthStateKey)
            userDefaults.synchronize()
        }
    }

    func loadState() {
        guard let data = UserDefaults(suiteName: "group.net.openid.appauth.Example")?
            .object(forKey: kAppAuthExampleAuthStateKey) as? Data
        else {
            return
        }
        if let authState = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
            setAuthState(authState)
        }
    }

    func setAuthState(_ authState: OIDAuthState?) {
        if self.authState == authState { return }
        self.authState = authState
        self.authState?.stateChangeDelegate = self
        stateChanged()
    }

    func stateChanged() {
        saveState()
        onStateChanged?()
    }

    public func didChange(_ state: OIDAuthState) {
        stateChanged()
    }

    public func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        print("Received authorization error: \(error)")
    }
}
