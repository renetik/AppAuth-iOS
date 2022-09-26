import AppAuth
import AppAuthCore
import Foundation

//class OIDCAuthorizerImpl {
//    let configuration: OIDCConfiguration
//
//    init(using configuration: OIDCConfiguration) {
//        self.configuration = configuration
//    }
//
//    var needsLogin: Bool { true }
//
//    // if user is not logged in, show login webpage and then return new token
//    // if we already have valid token, return the token
//    // if token expired and we have refresh token, use it to get new access token
//    // NOTE: refreshing token is not part of this story
//    // NOTE: permanent storage of tokens is not part of this story
//    var token: String { get async throws }
//
//    // resume login flow when app is opened from external browser
//
//    // this might not be needed if we show embedded webview within the app
//    func resume(with url: URL){
//
//    }
//
//    // clear both tokens
//
//    // after calling this method, needsLogin will be true
//    // NOTE: logout is not part of this story
//    func logout(){
//
//    }
//}
