import AppAuth
import UIKit
import SequenexOpenIdConnectLibrary

typealias PostRegistrationCallback = (_ configuration: OIDServiceConfiguration?,
                                      _ registrationResponse: OIDRegistrationResponse?) -> Void
let OIDCIssuer: String = "https://accounts.google.com"
let OAuthClientID: String? = "192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re.apps.googleusercontent.com"
let OAuthRedirectURI: String =
    "com.googleusercontent.apps.192175042918-bns3qrlggk28ue4jhnuemv1irh6b00re:/oauth2redirect/google"
let kAppAuthExampleAuthStateKey: String = "authState"

class AppAuthExampleViewController: UIViewController {
    @IBOutlet private weak var authAutoButton: UIButton!
    @IBOutlet private weak var authManual: UIButton!
    @IBOutlet private weak var codeExchangeButton: UIButton!
    @IBOutlet private weak var userinfoButton: UIButton!
    @IBOutlet private weak var logTextView: UITextView!
    @IBOutlet private weak var trashButton: UIBarButtonItem!
    private let appDelegate = UIApplication.shared.delegate as? AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        appDelegate?.oidc.onStateChanged = { [weak self] in self?.updateUI() }
        updateUI()
    }

    func updateUI() {
        codeExchangeButton.isEnabled = appDelegate?.oidc.isCodeExchangePossible == true
        if appDelegate?.oidc.isAuthenticated == true {
            authAutoButton.setTitle("1. Re-Auth", for: .normal)
            authManual.setTitle("1(A) Re-Auth", for: .normal)
            userinfoButton.isEnabled = appDelegate?.oidc.isAuthorized == true
        } else {
            authAutoButton.setTitle("1. Auto", for: .normal)
            authManual.setTitle("1(A) Manual", for: .normal)
            userinfoButton.isEnabled = false
        }
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

extension AppAuthExampleViewController {

    @IBAction func authWithAutoCodeExchange(_ sender: UIButton) {
        appDelegate?.oidc.authWithAutoCodeExchange(parent: self)
    }

    @IBAction func authNoCodeExchange(_ sender: UIButton) {
        appDelegate?.oidc.authWithNoCodeExchange(parent: self)
    }

    @IBAction func codeExchange(_ sender: UIButton) {
        appDelegate?.oidc.codeExchange()
    }

    @IBAction func userinfo(_ sender: UIButton) {
        appDelegate?.oidc.getUserInfo { json in self.logMessage("Success: \(json)") }
    }

    @IBAction func trashClicked(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil,
            message: nil,
            preferredStyle: UIAlertController.Style.actionSheet)

        let clearAuthAction = UIAlertAction(title: "Clear OAuthState",
            style: .destructive) { (_: UIAlertAction) in
            self.appDelegate?.oidc.clearAuthState()
        }
        alert.addAction(clearAuthAction)
        let clearLogs = UIAlertAction(title: "Clear Logs", style: .default) { (_: UIAlertAction) in
            DispatchQueue.main.async { self.logTextView.text = "" }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(clearLogs)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
}
