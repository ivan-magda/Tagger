/**
 * Copyright (c) 2016 Ivan Magda
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import KeychainSwift

/**
 * Based on this project https://github.com/josephstein/Flickr-OAuth-iOS
 *
 * The OAuth flow has 3 steps:
 * Get a Request Token                              @see getRequestToken
 * Get the User's Authorization                     @see promtsUserForAuthorization(_:)
 * Exchange the Request Token for an Access Token   @see getAccessTokenFromAuthorizationCallbackURL(_:)
 *
 * Read Flickr User Authentication for a detailed description: https://www.flickr.com/services/api/auth.oauth.html
 */

// MARK: Typealiases

typealias FlickrOAuthMethodParams = [String: String]
typealias FlickrOAuthCompletionHandler = (_ result: FlickrOAuthResult) -> Void
private typealias FlickrOAuthFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - Types

enum FlickrOAuthPermission: String {
    case read
    case write
    case delete
}

private enum OAuthParameterKey: String {
    case nonce = "oauth_nonce"
    case timestamp = "oauth_timestamp"
    case consumerKey = "oauth_consumer_key"
    case signatureMethod = "oauth_signature_method"
    case version = "oauth_version"
    case callback = "oauth_callback"
    case signature = "oauth_signature"
    case token = "oauth_token"
    case permissions = "perms"
    case verifier = "oauth_verifier"
}

private enum OAuthParameterValue: String {
    case signatureMethod = "HMAC-SHA1"
    case version = "1.0"
}

private enum OAuthResponseKey: String {
    case callbackConfirmed = "oauth_callback_confirmed"
    case token = "oauth_token"
    case tokenSecret = "oauth_token_secret"
    case userId = "user_nsid"
    case username
    case fullname
}

private enum FlickrOAuthState {
    case requestToken
    case accessToken
    case `default`
}

// MARK: - Constants

private let requestTokenBaseURL = "https://www.flickr.com/services/oauth/request_token"
private let authorizeBaseURL = "https://www.flickr.com/services/oauth/authorize"
private let accessTokenBaseURL = "https://www.flickr.com/services/oauth/access_token"

private let accessTokenKeychainKey = "flickr_access_token"
private let tokenSecretKeychainKey = "flickr_token_secret"

private let keychainServiceName = "com.flickr.oauth-token"

// MARK: - FlickrOAuth -

class FlickrOAuth {
    
    // MARK: Properties
    
    private let consumerKey: String
    private let consumerSecret: String
    private let callbackURL: String
    
    private var authenticationPermission: FlickrOAuthPermission!
    private var currentState: FlickrOAuthState = .default
    
    private var resultBlock: FlickrOAuthCompletionHandler!
    
    private var token: String?
    private var tokenSecret: String?
    
    private let authSession = URLSession(configuration: .default)
    
    // MARK: - Init
    
    init(consumerKey: String, consumerSecret: String, callbackURL: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackURL = callbackURL
    }
    
    // MARK: - Public -
    
    func auth(with permission: FlickrOAuthPermission,
              result: @escaping FlickrOAuthCompletionHandler) {
        authenticationPermission = permission
        resultBlock = result
        getRequestToken()
    }
    
    func buildSHAEncryptedURL(for httpMethod: HttpMethod,
                              baseURL url: String,
                              requestParameters parameters: FlickrOAuthMethodParams) -> URL? {
        currentState = .default
        
        getTokensFromKeychain()
        guard let token = token,
            let _ = tokenSecret else {
                return nil
        }
        
        var parameters = getRequestParams(with: parameters)
        parameters[OAuthParameterKey.token.rawValue] = token
        let urlString = getEncriptedURL(with: url,requestParams: parameters,
                                                httpMethod: httpMethod)
        
        return URL(string: urlString)
    }
    
    // MARK: - Private -
    // MARK: Request Token
    
    private func getRequestToken() {
        FlickrOAuth.removeTokensFromKeychain()
        currentState = .requestToken
        
        let urlString = getEncriptedURL(with: requestTokenBaseURL,
                                                requestParams: getBaseRequestParams())
        authSession
            .dataTask(with: URL(string: urlString)!, completionHandler: processResponse)
            .resume()
    }
    
    // MARK: User Authorization
    
    private func promtsUserForAuth(_ success: @escaping (_ callbackURL: URL) -> Void) {
        let authURL = "\(authorizeBaseURL)?\(OAuthParameterKey.token.rawValue)=\(token!)&\(OAuthParameterKey.permissions.rawValue)=\(authenticationPermission.rawValue)"
        let authVC = FlickrOAuthViewController(authorizationURL: authURL,
                                               callbackURL: callbackURL)

        authVC.authorize(success: { success($0 as URL) },
                         failure: { self.resultBlock(.failure(error: $0)) })
    }
    
    // MARK: Access Token
    
    private func getAccessToken(from authorizationCallbackURL: URL) {
        currentState = .accessToken
        
        var parameters = getBaseRequestParams()
        parameters[OAuthParameterKey.verifier.rawValue] = extractVerifier(from: authorizationCallbackURL)
        
        let urlString = getEncriptedURL(with: accessTokenBaseURL, requestParams: parameters)
        let urlWithSignature = URL(string: urlString)!
        authSession
            .dataTask(with: urlWithSignature, completionHandler: processResponse)
            .resume()
    }
    
    private func extractVerifier(from callbackURL: URL) -> String {
        let parameters = callbackURL.absoluteString.components(separatedBy: "&")
        let keyValue = parameters[1].components(separatedBy: "=")

        return keyValue[1]
    }
    
    // MARK: Build Destination URL
    
    private func getBaseRequestParams() -> FlickrOAuthMethodParams {
        let timestamp = (floor(Date().timeIntervalSince1970) as NSNumber).stringValue
        let nonce = UUID().uuidString
        let signatureMethod = OAuthParameterValue.signatureMethod.rawValue
        let version = OAuthParameterValue.version.rawValue
        
        var params = [
            OAuthParameterKey.nonce.rawValue: nonce,
            OAuthParameterKey.timestamp.rawValue: timestamp,
            OAuthParameterKey.consumerKey.rawValue: consumerKey,
            OAuthParameterKey.signatureMethod.rawValue: signatureMethod,
            OAuthParameterKey.version.rawValue: version
        ]
        
        switch currentState {
        case .requestToken:
            params[OAuthParameterKey.callback.rawValue] = callbackURL
        case .accessToken:
            params[OAuthParameterKey.token.rawValue] = token!
        case .default:
            break
        }
        
        return params
    }
    
    private func getRequestParams(with params: FlickrOAuthMethodParams) -> FlickrOAuthMethodParams {
        var resParams = getBaseRequestParams()
        params.forEach { resParams[$0] = $1 }

        return resParams
    }
    
    private func getEncriptedURL(with baseURL: String,
                                 requestParams parameters: FlickrOAuthMethodParams,
                                 httpMethod: HttpMethod = .get) -> String {
        var parameters = parameters
        let urlBeforeSignature = getSortedURLString(baseURL,
                                                 requestParams: parameters,
                                                 urlEscape: true)
        
        let secretKey = "\(consumerSecret)&\(tokenSecret ?? "")"
        let signatureString = "\(httpMethod.rawValue)&\(urlBeforeSignature)"
        let signature = signatureString.generateHMACSHA1EncriptedString(secretKey: secretKey)
        
        parameters[OAuthParameterKey.signature.rawValue] = signature
        let urlWithSignature = getSortedURLString(baseURL,
                                               requestParams: parameters,
                                               urlEscape: false)
        
        return urlWithSignature
    }
    
    private func getSortedURLString(_ url: String,
                                    requestParams dictionary: FlickrOAuthMethodParams,
                                    urlEscape: Bool) -> String {
        func doUrlEscaping(_ string: inout String) {
            if urlEscape {
                string = String.urlEncodedStringFromString(string)
            }
        }
        
        var pairs = [String]()
        let keys = Array(dictionary.keys).sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
        
        keys.forEach { key in
            let value = dictionary[key]!
            let escapedValue = String.oauthEncodedStringFromString(value)
            pairs.append("\(key)=\(escapedValue)")
        }
        
        var urlString = url
        doUrlEscaping(&urlString)
        urlString += (urlEscape ? "&" : "?")
        
        var args = pairs.joined(separator: "&")
        doUrlEscaping(&args)
        urlString += args
        
        return urlString
    }
    
    // MARK: Process on Response
    
    private func processResponse(data: Data?, response: URLResponse?, error: Error?) {
        func returnError(_ error: String) {
            print("Failed authorize with Flickr. Error: \(error).")
            performOnMain {
                let error = NSError(
                    domain: "\(BaseErrorDomain).FlickrOAuth",
                    code: 55,
                    userInfo: [NSLocalizedDescriptionKey : error]
                )
                self.resultBlock(.failure(error: error))
            }
        }
        
        guard error == nil else {
            returnError(error!.localizedDescription)
            return
        }
        
        guard let data = data,
            let responseString = String(data: data, encoding: String.Encoding.utf8) else {
                returnError("Could not get response string.")
                return
        }
        
        let params = buildParams(from: responseString)
        
        switch currentState {
        case .requestToken:
            guard let oauthStatus = params[OAuthResponseKey.callbackConfirmed.rawValue],
                (oauthStatus as NSString).boolValue == true else {
                    returnError("Failed to get a request token. OAuth status is not confirmed.")
                    return
            }
            updateTokens(from: params)
            
            performOnMain {
                self.promtsUserForAuth { [unowned self] callbackURL in
                    self.getAccessToken(from: callbackURL)
                }
            }
        case .accessToken:
            guard let username = params[OAuthResponseKey.username.rawValue]?.removingPercentEncoding,
                let userID = params[OAuthResponseKey.userId.rawValue]?.removingPercentEncoding,
                let fullname = params[OAuthResponseKey.fullname.rawValue]?.removingPercentEncoding,
                !username.isEmpty else {
                    returnError("Failed to get an access token.")
                    return
            }
            updateTokens(from: params)
            
            performOnMain {
                self.resultBlock(
                    FlickrOAuthResult.success(
                        token: self.token!,
                        tokenSecret: self.tokenSecret!,
                        user: FlickrUser(fullname: fullname, username: username, userID: userID)
                    )
                )
            }
        default:
            break
        }
    }
    
    private func buildParams(from responseString: String) -> FlickrOAuthMethodParams {
        let params = responseString.removingPercentEncoding!.components(separatedBy: "&")
        var dictionary = [String: String]()

        params.forEach {
            let components = $0.components(separatedBy: "=")
            let key = components[0]
            let value = components[1]
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    private func updateTokens(from responseParams: FlickrOAuthMethodParams) {
        token = responseParams[OAuthResponseKey.token.rawValue]
        tokenSecret = responseParams[OAuthResponseKey.tokenSecret.rawValue]

        if currentState == .accessToken {
            storeTokensInKeychain()
        }
    }
    
}

// MARK: - FlickrOAuth (Keychain Support) -

extension FlickrOAuth {

    // MARK: Instance Variables

    private static let keychain = KeychainSwift(keyPrefix: keychainServiceName)

    // MARK: Public

    static func removeTokensFromKeychain() {
        keychain.delete(accessTokenKeychainKey)
        keychain.delete(tokenSecretKeychainKey)
    }

    static func getTokensFromKeychain() -> (accessToken: String?, tokenSecret: String?) {
        let token = keychain.get(accessTokenKeychainKey)
        let tokenSecret = keychain.get(tokenSecretKeychainKey)

        return (token, tokenSecret)
    }

    // MARK: Private

    private func storeTokensInKeychain() {
        FlickrOAuth.keychain.set(token!, forKey: accessTokenKeychainKey)
        FlickrOAuth.keychain.set(tokenSecret!, forKey: tokenSecretKeychainKey)
    }

    @discardableResult private func getTokensFromKeychain() -> Bool {
        let data = FlickrOAuth.getTokensFromKeychain()

        guard let token = data.accessToken,
            let tokenSecret = data.tokenSecret else {
                return false
        }

        self.token = token
        self.tokenSecret = tokenSecret

        return true
    }

}
