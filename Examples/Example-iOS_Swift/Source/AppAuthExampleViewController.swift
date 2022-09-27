import AppAuth
import UIKit
import SequenexOpenIdConnectLibrary

class AppAuthExampleViewController: UIViewController {
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var logOutButton: UIButton!
    private let oidcAuthorizer = (UIApplication.shared.delegate as? AppDelegate)!.oidcAuthorizer

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func login(success: @escaping (String) -> Void, failure: @escaping (Error) -> Void) {
        Task {
            do {
                let token = try await oidcAuthorizer.login()
                DispatchQueue.main.async { success(token) }
            } catch {
                failure(error)
            }
        }
    }

    func updateUI() {
        loginButton.isEnabled = oidcAuthorizer.needsLogin
        logOutButton.isEnabled = !oidcAuthorizer.needsLogin
    }
}
