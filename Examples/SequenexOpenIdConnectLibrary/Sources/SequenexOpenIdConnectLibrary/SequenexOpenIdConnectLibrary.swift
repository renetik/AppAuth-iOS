import AppAuth
import AppAuthCore
import Foundation

public class SequenexOpenIdConnectLibrary {
    let issuer: String,  clientID: String?,  redirectURI: String

    public init(_ issuer: String, _ clientID: String?, _ redirectURI: String) {
        self.issuer = issuer; self.clientID = clientID; self.redirectURI = redirectURI
        assert(issuer != "https://issuer.example.com",
            "Update kIssuer with your own issuer.\n" +
                "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        assert(clientID != "YOUR_CLIENT_ID",
            "Update kClientID with your own client ID.\n" +
                "Instructions: https://github.com/openid/AppAuth-iOS/blob/master/Examples/Example-iOS_Swift-Carthage/README.md");
        assert(redirectURI != "com.example.app:/oauth2redirect/example-provider",
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

    func authWithAutoCodeExchange() {
        guard let issuer = URL(string: self.issuer) else {
            print("Error creating URL for : \(self.issuer)")
            return
        }
        print("Fetching configuration for issuer: \(self.issuer)")
        OIDAuthorizationService.discoverConfiguration(forIssuer: issuer) { configuration, error in
            guard let config = configuration else {
                print("Error retrieving discovery document: \(error?.localizedDescription ?? "DEFAULT_ERROR")")
//                self.setAuthState(nil)
                return
            }
            print("Got configuration: \(config)")
            if let clientId = self.clientID {
//                self.doAuthWithAutoCodeExchange(configuration: config, clientID: clientId, clientSecret: nil)
            }
            else {
//                self.doClientRegistration(configuration: config) { configuration, response in
//                    guard let configuration = configuration, let clientID = response?.clientID else {
//                        self.logMessage("Error retrieving configuration OR clientID")
//                        return
//                    }
//                    self.doAuthWithAutoCodeExchange(configuration: configuration,
//                        clientID: clientID,
//                        clientSecret: response?.clientSecret)
//                }
            }
        }
    }
}
