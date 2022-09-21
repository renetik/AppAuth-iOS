import AppAuth
import UIKit
import SequenexOpenIdConnectLibrary

typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?,
                                      _ registrationResponse: OIDRegistrationResponse?) -> Void
let OIDCIssuer: String = "https://accounts.google.com";
let OAuthClientID: String? = "192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re.apps.googleusercontent.com";
let OAuthRedirectURI: String = "com.googleusercontent.apps.192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re:/oauth2redirect/google";
let kAppAuthExampleAuthStateKey: String = "authState";

class AppAuthExampleViewController: UIViewController {
    @IBOutlet private weak var authAutoButton: UIButton!
    @IBOutlet private weak var authManual: UIButton!
    @IBOutlet private weak var codeExchangeButton: UIButton!
    @IBOutlet private weak var userinfoButton: UIButton!
    @IBOutlet private weak var logTextView: UITextView!
    @IBOutlet private weak var trashButton: UIBarButtonItem!
    private var authState: OIDAuthState?
    let oidc = SequenexOpenIdConnectLibrary(OIDCIssuer, OAuthClientID, OAuthRedirectURI)

    override func viewDidLoad() {
        super.viewDidLoad()
        validateOAuthConfiguration()
        loadState()
        updateUI()
    }
}

extension AppAuthExampleViewController {
    func validateOAuthConfiguration() {
        assert(OIDCIssuer != "https://issuer.example.com",
            "Update kIssuer with your own issuer.\n" +
                "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        assert(OAuthClientID != "YOUR_CLIENT_ID",
            "Update kClientID with your own client ID.\n" +
                "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        assert(OAuthRedirectURI != "com.example.app:/oauth2redirect/example-provider",
            "Update kRedirectURI with your own redirect URI.\n" +
                "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        guard let urlTypes: [AnyObject] = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject], urlTypes.count > 0 else {
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
    }

}

extension AppAuthExampleViewController {

    @IBAction func authWithAutoCodeExchange(_ sender: UIButton) {
        guard let issuer = URL(string: OIDCIssuer) else {
            logMessage("Error creating URL for : \(OIDCIssuer)")
            return
        }
        logMessage("Fetching configuration for issuer: \(issuer)")
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                let error = error?.localizedDescription ?? "DEFAULT_ERROR"
                self.logMessage("Error retrieving discovery document: \(error)")
                self.setAuthState(nil)
                return
            }
            self.logMessage("Got configuration: \(config)")
            if let clientId = OAuthClientID {
                self.doAuthWithAutoCodeExchange(configuration: config, clientID: clientId, clientSecret: nil)
            } else {
                self.doClientRegistration(configuration: config) { configuration, response in
                    guard let configuration = configuration, let clientID = response?.clientID else {
                        self.logMessage("Error retrieving configuration OR clientID")
                        return
                    }
                    self.doAuthWithAutoCodeExchange(configuration: configuration,
                        clientID: clientID,
                        clientSecret: response?.clientSecret)
                }
            }
        }

    }

    @IBAction func authNoCodeExchange(_ sender: UIButton) {
        guard let issuer = URL(string: OIDCIssuer) else {
            logMessage("Error creating URL for : \(OIDCIssuer)")
            return
        }
        logMessage("Fetching configuration for issuer: \(issuer)")
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            if let error = error {
                self.logMessage("Error retrieving discovery document: \(error.localizedDescription)")
                return
            }
            guard let configuration = configuration else {
                self.logMessage("Error retrieving discovery document. Error & Configuration both are NIL!")
                return
            }
            self.logMessage("Got configuration: \(configuration)")
            if let clientId = OAuthClientID {
                self.doAuthWithoutCodeExchange(configuration: configuration, clientID: clientId, clientSecret: nil)
            } else {
                self.doClientRegistration(configuration: configuration) { configuration, response in
                    guard let configuration = configuration, let response = response else {
                        return
                    }
                    self.doAuthWithoutCodeExchange(configuration: configuration,
                        clientID: response.clientID,
                        clientSecret: response.clientSecret)
                }
            }
        }
    }

    @IBAction func codeExchange(_ sender: UIButton) {
        guard let tokenExchangeRequest = authState?.lastAuthorizationResponse.tokenExchangeRequest() else {
            logMessage("Error creating authorization code exchange request")
            return
        }
        logMessage("Performing authorization code exchange with request \(tokenExchangeRequest)")
        OIDAuthorizationService.perform(tokenExchangeRequest, callback: { response, error in
            if let tokenResponse = response {
                let token = tokenResponse.accessToken ?? "DEFAULT_TOKEN"
                self.logMessage("Received token response with accessToken: \(token)")
            } else {
                self.logMessage("Token exchange error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
            }
            self.authState?.update(with: response, error: error)
        })
    }

    @IBAction func userinfo(_ sender: UIButton) {
        guard let userinfoEndpoint = authState?.lastAuthorizationResponse.request
            .configuration.discoveryDocument?.userinfoEndpoint
        else {
            logMessage("Userinfo endpoint not declared in discovery document")
            return
        }
        logMessage("Performing userinfo request")
        let currentAccessToken: String? = self.authState?.lastTokenResponse?.accessToken
        authState?.performAction { (accessToken, _, error) in
            if error != nil {
                self.logMessage("Error fetching fresh tokens: \(error?.localizedDescription ?? "ERROR")")
                return
            }
            guard let accessToken = accessToken else {
                self.logMessage("Error getting accessToken")
                return
            }
            if currentAccessToken != accessToken {
                let info = "\(currentAccessToken ?? "CURRENT_ACCESS_TOKEN") to \(accessToken)"
                self.logMessage("Access token was refreshed automatically (\(info))")
            } else {
                self.logMessage("Access token was fresh and not updated \(accessToken)")
            }
            var urlRequest = URLRequest(url: userinfoEndpoint)
            urlRequest.allHTTPHeaderFields = ["Authorization": "Bearer \(accessToken)"]
            let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in
                DispatchQueue.main.async {
                    guard error == nil else {
                        self.logMessage("HTTP request failed \(error?.localizedDescription ?? "ERROR")")
                        return
                    }
                    guard let response = response as? HTTPURLResponse else {
                        self.logMessage("Non-HTTP response")
                        return
                    }
                    guard let data = data else {
                        self.logMessage("HTTP response data is empty")
                        return
                    }
                    var json: [AnyHashable: Any]?
                    do {
                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    } catch {
                        self.logMessage("JSON Serialization Error")
                    }
                    if response.statusCode != 200 {
                        let errorText: String? = String(data: data, encoding: String.Encoding.utf8)
                        if response.statusCode == 401 {
                            let oauthError = OIDErrorUtilities.resourceServerAuthorizationError(withCode: 0,
                                errorResponse: json, underlyingError: error)
                            self.authState?.update(withAuthorizationError: oauthError)
                            let response = errorText ?? "RESPONSE_TEXT"
                            self.logMessage("Authorization Error (\(oauthError)). Response: \(response)")
                        } else {
                            self.logMessage("HTTP: \(response.statusCode), Response: \(errorText ?? "RESPONSE_TEXT")")
                        }
                        return
                    }
                    if let json = json { self.logMessage("Success: \(json)") }
                }
            }
            task.resume()
        }
    }

    @IBAction func trashClicked(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil,
            message: nil,
            preferredStyle: UIAlertController.Style.actionSheet)

        let clearAuthAction = UIAlertAction(title: "Clear OAuthState", style: .destructive) { (_: UIAlertAction) in
            self.setAuthState(nil)
            self.updateUI()
        }
        alert.addAction(clearAuthAction)
        let clearLogs = UIAlertAction(title: "Clear Logs", style: .default) { (_: UIAlertAction) in
            DispatchQueue.main.async {
                self.logTextView.text = ""
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(clearLogs)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}

extension AppAuthExampleViewController {
    func doClientRegistration(configuration: OIDServiceConfiguration, callback: @escaping PostRegistrationCallback) {
        guard let redirectURI = URL(string: OAuthRedirectURI) else {
            logMessage("Error creating URL for : \(OAuthRedirectURI)")
            return
        }
        let request: OIDRegistrationRequest = OIDRegistrationRequest(configuration: configuration,
            redirectURIs: [redirectURI],
            responseTypes: nil,
            grantTypes: nil,
            subjectType: nil,
            tokenEndpointAuthMethod: "client_secret_post",
            additionalParameters: nil)
        logMessage("Initiating registration request")
        OIDAuthorizationService.perform(request) { response, error in
            if let regResponse = response {
                self.setAuthState(OIDAuthState(registrationResponse: regResponse))
                self.logMessage("Got registration response: \(regResponse)")
                callback(configuration, regResponse)
            } else {
                self.logMessage("Registration error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
            }
        }
    }

    func doAuthWithAutoCodeExchange(configuration: OIDServiceConfiguration, clientID: String, clientSecret: String?) {
        guard let redirectURI = URL(string: OAuthRedirectURI) else {
            logMessage("Error creating URL for : \(OAuthRedirectURI)")
            return
        }

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            logMessage("Error accessing AppDelegate")
            return
        }
        let request = OIDAuthorizationRequest(configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        logMessage("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")
        appDelegate.currentAuthorizationFlow = OIDAuthState.authState(
            byPresenting: request, presenting: self) { authState, error in
            if let authState = authState {
                let token = authState.lastTokenResponse?.accessToken ?? "DEFAULT_TOKEN"
                self.logMessage("Got authorization tokens. Access token: \(token)")
                self.setAuthState(authState)
            } else {
                self.logMessage("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                self.setAuthState(nil)
            }
        }
    }

    func doAuthWithoutCodeExchange(configuration: OIDServiceConfiguration,
                                   clientID: String, clientSecret: String?) {
        guard let redirectURI = URL(string: OAuthRedirectURI) else {
            logMessage("Error creating URL for : \(OAuthRedirectURI)")
            return
        }
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            logMessage("Error accessing AppDelegate")
            return
        }
        let request = OIDAuthorizationRequest(configuration: configuration,
            clientId: clientID,
            clientSecret: clientSecret,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil)

        logMessage("Initiating authorization request with scope: \(request.scope ?? "DEFAULT_SCOPE")")

        appDelegate.currentAuthorizationFlow = OIDAuthorizationService
            .present(request, presenting: self) { (response, error) in
                if let response = response {
                    let authState = OIDAuthState(authorizationResponse: response)
                    self.setAuthState(authState)
                    self.logMessage("Authorization response with code: \(response.authorizationCode ?? "DEFAULT_CODE")")
                    // could just call [self tokenExchange:nil] directly, but will let the user initiate it.
                } else {
                    self.logMessage("Authorization error: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
                }
            }
    }
}

extension AppAuthExampleViewController: OIDAuthStateChangeDelegate, OIDAuthStateErrorDelegate {
    func didChange(_ state: OIDAuthState) {
        stateChanged()
    }

    func authState(_ state: OIDAuthState, didEncounterAuthorizationError error: Error) {
        logMessage("Received authorization error: \(error)")
    }
}

extension AppAuthExampleViewController {

    func saveState() {
        var data: Data?
        if let authState = authState { data = NSKeyedArchiver.archivedData(withRootObject: authState) }
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

    func updateUI() {
        codeExchangeButton.isEnabled = authState?.lastAuthorizationResponse.authorizationCode != nil
            && !((authState?.lastTokenResponse) != nil)
        if let authState = authState {
            authAutoButton.setTitle("1. Re-Auth", for: .normal)
            authManual.setTitle("1(A) Re-Auth", for: .normal)
            userinfoButton.isEnabled = authState.isAuthorized ? true : false
        } else {
            authAutoButton.setTitle("1. Auto", for: .normal)
            authManual.setTitle("1(A) Manual", for: .normal)
            userinfoButton.isEnabled = false
        }
    }

    func stateChanged() {
        saveState()
        updateUI()
    }

    func logMessage(_ message: String?) {
        guard let message = message else { return }
        print(message)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        let dateString = dateFormatter.string(from: Date())
        DispatchQueue.main.async {
            self.logTextView.text = "\(self.logTextView.text ?? "")\n\(dateString): \(message)"
        }
    }
}
