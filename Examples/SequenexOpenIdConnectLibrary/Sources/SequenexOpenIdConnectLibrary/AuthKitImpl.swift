import AppAuth
import AppAuthCore
import Foundation

public class DefaultOIDCAuthorizer: OIDCAuthorizer {

    let configuration: OIDCConfiguration

    required public init(using configuration: OIDCConfiguration) {
        self.configuration = configuration
    }

    public var needsLogin: Bool { true }

    // if user is not logged in, show login webpage and then return new token
    // if we already have valid token, return the token
    // if token expired and we have refresh token, use it to get new access token
    // NOTE: refreshing token is not part of this story
    // NOTE: permanent storage of tokens is not part of this story
    public func login() async throws -> String {
        "token"
    }

    // resume login flow when app is opened from external browser

    // this might not be needed if we show embedded webview within the app
    public func resume(with url: URL) -> Bool {
        false
    }

    // clear both tokens

    // after calling this method, needsLogin will be true
    // NOTE: logout is not part of this story
    public func logout() {

    }
}
