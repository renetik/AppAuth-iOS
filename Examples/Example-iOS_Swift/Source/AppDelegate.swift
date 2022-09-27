import AppAuth
import UIKit
import SequenexOpenIdConnectLibrary

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    static let issuer = "https://accounts.google.com"
    static let clientID = "192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re.apps.googleusercontent.com"
    static let redirectURI =
        "com.googleusercontent.apps.192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re:/oauth2redirect/google"

    let oidcAuthorizer = DefaultOIDCAuthorizer(
        using: OIDCConfiguration(issuer: issuer, clientID: clientID,
            redirectURI: URL(string: redirectURI)!))

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if oidcAuthorizer.resume(with: url) { return true }
        return false
    }
}
