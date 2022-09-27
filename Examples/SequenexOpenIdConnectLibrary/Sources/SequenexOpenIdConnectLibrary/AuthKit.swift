import AppAuth
import AppAuthCore
import Foundation

public protocol OIDCAuthorizer {
    init(using configuration: OIDCConfiguration)

    // indicates if we need to display login interface to get token
    var needsLogin: Bool { get }

    // if user is not logged in, show login webpage and then return new token
    // if we already have valid token, return the token
    // if token expired and we have refresh token, use it to get new access token
    // NOTE: refreshing token is not part of this story
    // NOTE: permanent storage of tokens is not part of this story
    func login() async throws -> String

    // resume login flow when app is opened from external browser
    // this might not be needed if we show embedded webview within the app
    func resume(with url: URL) -> Bool

    // clear both tokens
    // after calling this method, needsLogin will be true
    // NOTE: logout is not part of this story
    func logout()
}

public struct OIDCConfiguration {
    var issuer: String
    var clientID: String?
    var redirectURI: URL
    var barTintColor: UIColor?
    var controlTintColor: UIColor?
    
    public init(issuer: String, clientID: String? = nil,
                redirectURI: URL, barTintColor: UIColor? = nil,
                controlTintColor: UIColor? = nil) {
        self.issuer = issuer
        self.clientID = clientID
        self.redirectURI = redirectURI
        self.barTintColor = barTintColor
        self.controlTintColor = controlTintColor
    }
}


public enum OIDCError: LocalizedError {
    case loginCancelled
    case offline
    case networkError(cause: Error)
}

//import UIKit

//
//extension Decodable where Self: UIColor {
//
//    public init(from decoder: Decoder) throws {
//        let container = try decoder.singleValueContainer()
//        let components = try container.decode([CGFloat].self)
//        self = Self.init(red: components[0], green: components[1],
//                         blue: components[2], alpha: components[3])
//    }
//}
//
//extension Encodable where Self: UIColor {
//    public func encode(to encoder: Encoder) throws {
//        var r, g, b, a: CGFloat
//        (r, g, b, a) = (0, 0, 0, 0)
//        var container = encoder.singleValueContainer()
//        self.getRed(&r, green: &g, blue: &b, alpha: &a)
//        try container.encode([r, g, b, a])
//    }
//
//}
//
//extension UIColor: Codable { }
