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

import UIKit
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

typealias Parameters = [String: String]
typealias FlickrOAuthCompletionHandler = (_ result: FlickrOAuthResult) -> Void
private typealias FlickrOAuthFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - Types

enum FlickrAuthenticationPermission: String {
    case Read = "read"
    case Write = "write"
    case Delete = "delete"
}

private enum OAuthParameterKey: String {
    case Nonce = "oauth_nonce"
    case Timestamp = "oauth_timestamp"
    case ConsumerKey = "oauth_consumer_key"
    case SignatureMethod = "oauth_signature_method"
    case Version = "oauth_version"
    case Callback = "oauth_callback"
    case Signature = "oauth_signature"
    case Token = "oauth_token"
    case Permissions = "perms"
    case Verifier = "oauth_verifier"
}

private enum OAuthParameterValue: String {
    case SignatureMethod = "HMAC-SHA1"
    case Version = "1.0"
}

private enum OAuthResponseKey: String {
    case CallbackConfirmed = "oauth_callback_confirmed"
    case Token = "oauth_token"
    case TokenSecret = "oauth_token_secret"
    case Username = "username"
    case UserID = "user_nsid"
    case Fullname = "fullname"
}

private enum FlickrOAuthState {
    case requestToken
    case accessToken
    case `default`
}

// MARK: - Constants

private let kRequestTokenBaseURL = "https://www.flickr.com/services/oauth/request_token"
private let kAuthorizeBaseURL = "https://www.flickr.com/services/oauth/authorize"
private let kAccessTokenBaseURL = "https://www.flickr.com/services/oauth/access_token"

private let kAccessTokenKeychainKey = "flickr_access_token"
private let kTokenSecretKeychainKey = "flickr_token_secret"

private let kKeychainServiceName = "com.flickr.oauth-token"

// MARK: - FlickrOAuth -

class FlickrOAuth {
    
    // MARK: Properties
    
    fileprivate let consumerKey: String
    fileprivate let consumerSecret: String
    fileprivate let callbackURL: String
    
    fileprivate var authenticationPermission: FlickrAuthenticationPermission!
    fileprivate var currentState: FlickrOAuthState = .default
    
    fileprivate var resultBlock: FlickrOAuthCompletionHandler!
    
    fileprivate var token: String?
    fileprivate var tokenSecret: String?
    
    fileprivate let authSession = URLSession(configuration: .default)
    
    // MARK: - Init
    
    init(consumerKey: String, consumerSecret: String, callbackURL: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackURL = callbackURL
    }
    
    // MARK: - Public -
    
    func authorizeWithPermission(_ permission: FlickrAuthenticationPermission, result: @escaping FlickrOAuthCompletionHandler) {
        authenticationPermission = permission
        resultBlock = result
        getRequestToken()
    }
    
    func buildSHAEncryptedURLForHTTPMethod(_ httpMethod: HttpMethod, baseURL url: String, requestParameters parameters: Parameters) -> URL? {
        currentState = .default
        
        getTokensFromKeychain()
        guard let token = token,
            let _ = tokenSecret else {
                return nil
        }
        
        var parameters = getRequestParametersWithAdditionalParameters(parameters)
        parameters[OAuthParameterKey.Token.rawValue] = token
        let urlString = encriptedURLWithBaseURL(url, requestParameters: parameters, httpMethod: httpMethod)
        
        return URL(string: urlString)
    }
    
    // MARK: - Private -
    // MARK: Request Token
    
    fileprivate func getRequestToken() {
        FlickrOAuth.removeTokensFromKeychain()
        currentState = .requestToken
        
        let urlString = encriptedURLWithBaseURL(kRequestTokenBaseURL, requestParameters: getBaseRequestParameters())
        let urlWithSignature = URL(string: urlString)!
        let task = authSession.dataTask(with: urlWithSignature, completionHandler: processOnResponse)
        task.resume()
    }
    
    // MARK: User Authorization
    
    fileprivate func promtsUserForAuthorization(_ success: @escaping (_ callbackURL: URL) -> Void) {
        let authorizationURL = "\(kAuthorizeBaseURL)?\(OAuthParameterKey.Token.rawValue)=\(token!)&\(OAuthParameterKey.Permissions.rawValue)=\(authenticationPermission.rawValue)"
        
        let authViewController = FlickrOAuthViewController(authorizationURL: authorizationURL, callbackURL: callbackURL)



        authViewController.authorize(success: { success($0 as URL) },
                                     failure: { self.resultBlock(.failure(error: $0)) })
    }
    
    // MARK: Access Token
    
    fileprivate func getAccessTokenFromAuthorizationCallbackURL(_ url: URL) {
        currentState = .accessToken
        
        var parameters = getBaseRequestParameters()
        parameters[OAuthParameterKey.Verifier.rawValue] = extractVerifierFromCallbackURL(url)
        
        let urlString = encriptedURLWithBaseURL(kAccessTokenBaseURL, requestParameters: parameters)
        let urlWithSignature = URL(string: urlString)!
        let task = authSession.dataTask(with: urlWithSignature, completionHandler: processOnResponse)
        task.resume()
    }
    
    fileprivate func extractVerifierFromCallbackURL(_ url: URL) -> String {
        let parameters = url.absoluteString.components(separatedBy: "&")
        let keyValue = parameters[1].components(separatedBy: "=")
        return keyValue[1]
    }
    
    // MARK: Build Destination URL
    
    fileprivate func getBaseRequestParameters() -> Parameters {
        let timestamp = (floor(Date().timeIntervalSince1970) as NSNumber).stringValue
        let nonce = UUID().uuidString
        let signatureMethod = OAuthParameterValue.SignatureMethod.rawValue
        let version = OAuthParameterValue.Version.rawValue
        
        var parameters = [
            OAuthParameterKey.Nonce.rawValue: nonce,
            OAuthParameterKey.Timestamp.rawValue: timestamp,
            OAuthParameterKey.ConsumerKey.rawValue: consumerKey,
            OAuthParameterKey.SignatureMethod.rawValue: signatureMethod,
            OAuthParameterKey.Version.rawValue: version
        ]
        
        switch currentState {
        case .requestToken:
            parameters[OAuthParameterKey.Callback.rawValue] = callbackURL
        case .accessToken:
            parameters[OAuthParameterKey.Token.rawValue] = token!
        case .default:
            break
        }
        
        return parameters
    }
    
    fileprivate func getRequestParametersWithAdditionalParameters(_ param: Parameters) -> Parameters {
        var parameters = getBaseRequestParameters()
        param.forEach { parameters[$0] = $1 }
        return parameters
    }
    
    fileprivate func encriptedURLWithBaseURL(_ url: String, requestParameters parameters: Parameters, httpMethod: HttpMethod = .GET) -> String {
        var parameters = parameters
        let urlStringBeforeSignature = sortedURLString(url, requestParameters: parameters, urlEscape: true)
        
        let secretKey = "\(consumerSecret)&\(tokenSecret ?? "")"
        let signatureString = "\(httpMethod.rawValue)&\(urlStringBeforeSignature)"
        let signature = signatureString.generateHMACSHA1EncriptedString(secretKey: secretKey)
        
        parameters[OAuthParameterKey.Signature.rawValue] = signature
        let urlStringWithSignature = sortedURLString(url, requestParameters: parameters, urlEscape: false)
        
        return urlStringWithSignature
    }
    
    fileprivate func sortedURLString(_ url: String, requestParameters dictionary: Parameters, urlEscape: Bool) -> String {
        func urlEscapingIfNeeded(_ string: inout String) {
            if urlEscape { string = String.urlEncodedStringFromString(string) }
        }
        
        var pairs = [String]()
        let keys = Array(dictionary.keys).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending }
        
        keys.forEach { key in
            let value = dictionary[key]!
            let escapedValue = String.oauthEncodedStringFromString(value)
            pairs.append("\(key)=\(escapedValue)")
        }
        
        var urlString = url
        urlEscapingIfNeeded(&urlString)
        urlString += (urlEscape ? "&" : "?")
        
        var args = pairs.joined(separator: "&")
        urlEscapingIfNeeded(&args)
        urlString += args
        
        return urlString
    }
    
    // MARK: Process on Response
    
    fileprivate func processOnResponse(_ data: Data?, response: URLResponse?, error: Error?) {
        func sendError(_ error: String) {
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
            sendError(error!.localizedDescription)
            return
        }
        
        guard let data = data,
            let responseString = String(data: data, encoding: String.Encoding.utf8) else {
                sendError("Could not get response string.")
                return
        }
        
        let parameters = parametersFromResponseString(responseString)
        
        switch currentState {
        case .requestToken:
            guard let oauthStatus = parameters[OAuthResponseKey.CallbackConfirmed.rawValue], (oauthStatus as NSString).boolValue == true else {
                    sendError("Failed to get a request token. OAuth status is not confirmed.")
                    return
            }
            updateTokensFromResponseParameters(parameters)
            
            performOnMain {
                self.promtsUserForAuthorization { [unowned self] callbackURL in
                    self.getAccessTokenFromAuthorizationCallbackURL(callbackURL)
                }
            }
        case .accessToken:
            guard let username = parameters[OAuthResponseKey.Username.rawValue]?.removingPercentEncoding,
                let userID = parameters[OAuthResponseKey.UserID.rawValue]?.removingPercentEncoding,
                let fullname = parameters[OAuthResponseKey.Fullname.rawValue]?.removingPercentEncoding, username.characters.count > 0 else {
                    sendError("Failed to get an access token.")
                    return
            }
            updateTokensFromResponseParameters(parameters)
            
            performOnMain {
                let result = FlickrOAuthResult.success(
                    token: self.token!,
                    tokenSecret: self.tokenSecret!,
                    user: FlickrUser(fullname: fullname, username: username, userID: userID)
                )
                self.resultBlock(result)
            }
        default:
            break
        }
    }
    
    fileprivate func parametersFromResponseString(_ responseString: String) -> Parameters {
        let parameters = responseString.removingPercentEncoding!.components(separatedBy: "&")
        var dictionary = [String: String]()
        parameters.forEach {
            let components = $0.components(separatedBy: "=")
            let key = components[0]
            let value = components[1]
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    fileprivate func updateTokensFromResponseParameters(_ parameters: Parameters) {
        token = parameters[OAuthResponseKey.Token.rawValue]
        tokenSecret = parameters[OAuthResponseKey.TokenSecret.rawValue]
        if currentState == .accessToken { storeTokensInKeychain() }
    }
    
    // MARK: Keychain Support
    
    class func removeTokensFromKeychain() {
        let keychain = FlickrOAuth.getKeychain()
        keychain.delete(kAccessTokenKeychainKey)
        keychain.delete(kTokenSecretKeychainKey)
    }
    
    class func getTokensFromKeychain() -> (accessToken: String?, tokenSecret: String?) {
        let keychain = FlickrOAuth.getKeychain()
        let token = keychain.get(kAccessTokenKeychainKey)
        let tokenSecret = keychain.get(kTokenSecretKeychainKey)
        
        return (token, tokenSecret)
    }
    
    fileprivate class func getKeychain() -> KeychainSwift {
        return KeychainSwift(keyPrefix: kKeychainServiceName)
    }
    
    fileprivate func storeTokensInKeychain() {
        let keychain = FlickrOAuth.getKeychain()
        keychain.set(token!, forKey: kAccessTokenKeychainKey)
        keychain.set(tokenSecret!, forKey: kTokenSecretKeychainKey)
    }
    
    @discardableResult fileprivate func getTokensFromKeychain() -> Bool {
        let data = FlickrOAuth.getTokensFromKeychain()
        guard let token = data.accessToken,
            let tokenSecret = data.tokenSecret else { return false }
        
        self.token = token
        self.tokenSecret = tokenSecret
        
        return true
    }
    
}
