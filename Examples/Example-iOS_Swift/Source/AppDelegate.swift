import AppAuth
import UIKit
import SequenexOpenIdConnectLibrary

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let oidc = SequenexOpenIdConnectLibrary("https://accounts.google.com",
        "192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re.apps.googleusercontent.com",
        "com.googleusercontent.apps.192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re:/oauth2redirect/google")
    var currentAuthorizationFlow: OIDExternalUserAgentSession?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }

    func application(_ app: UIApplication, open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if oidc.onApplication(app, open: url, options: options) { return true }
        return false
    }
}