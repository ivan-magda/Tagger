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
typealias FlickrOAuthCompletionHandler = (result: FlickrOAuthResult) -> Void
private typealias FlickrOAuthFailureCompletionHandler = (error: NSError) -> Void

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
    case RequestToken
    case AccessToken
    case Default
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
    
    private let consumerKey: String
    private let consumerSecret: String
    private let callbackURL: String
    
    private var authenticationPermission: FlickrAuthenticationPermission!
    private var currentState: FlickrOAuthState = .Default
    
    private var resultBlock: FlickrOAuthCompletionHandler!
    
    private var token: String?
    private var tokenSecret: String?
    
    private let authSession = NSURLSession(configuration: .defaultSessionConfiguration())
    
    // MARK: - Init
    
    init(consumerKey: String, consumerSecret: String, callbackURL: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.callbackURL = callbackURL
    }
    
    // MARK: - Public -
    
    func authorizeWithPermission(permission: FlickrAuthenticationPermission, result: FlickrOAuthCompletionHandler) {
        authenticationPermission = permission
        resultBlock = result
        getRequestToken()
    }
    
    func buildSHAEncryptedURLForHTTPMethod(httpMethod: HttpMethod, baseURL url: String, requestParameters parameters: Parameters) -> NSURL? {
        currentState = .Default
        
        getTokensFromKeychain()
        guard let token = token,
            let _ = tokenSecret else {
                return nil
        }
        
        var parameters = getRequestParametersWithAdditionalParameters(parameters)
        parameters[OAuthParameterKey.Token.rawValue] = token
        let urlString = encriptedURLWithBaseURL(url, requestParameters: parameters, httpMethod: httpMethod)
        
        return NSURL(string: urlString)
    }
    
    // MARK: - Private -
    // MARK: Request Token
    
    private func getRequestToken() {
        FlickrOAuth.removeTokensFromKeychain()
        currentState = .RequestToken
        
        let urlString = encriptedURLWithBaseURL(kRequestTokenBaseURL, requestParameters: getBaseRequestParameters())
        let urlWithSignature = NSURL(string: urlString)!
        let task = authSession.dataTaskWithURL(urlWithSignature, completionHandler: processOnResponse)
        task.resume()
    }
    
    // MARK: User Authorization
    
    private func promtsUserForAuthorization(success: (callbackURL: NSURL) -> Void) {
        let authorizationURL = "\(kAuthorizeBaseURL)?\(OAuthParameterKey.Token.rawValue)=\(token!)&\(OAuthParameterKey.Permissions.rawValue)=\(authenticationPermission.rawValue)"
        
        let authViewController = FlickrOAuthViewController(authorizationURL: authorizationURL, callbackURL: callbackURL)
        authViewController.authorize(success: { success(callbackURL: $0)
        }){ self.resultBlock(result: .Failure(error: $0)) }
    }
    
    // MARK: Access Token
    
    private func getAccessTokenFromAuthorizationCallbackURL(url: NSURL) {
        currentState = .AccessToken
        
        var parameters = getBaseRequestParameters()
        parameters[OAuthParameterKey.Verifier.rawValue] = extractVerifierFromCallbackURL(url)
        
        let urlString = encriptedURLWithBaseURL(kAccessTokenBaseURL, requestParameters: parameters)
        let urlWithSignature = NSURL(string: urlString)!
        let task = authSession.dataTaskWithURL(urlWithSignature, completionHandler: processOnResponse)
        task.resume()
    }
    
    private func extractVerifierFromCallbackURL(url: NSURL) -> String {
        let parameters = url.absoluteString.componentsSeparatedByString("&")
        let keyValue = parameters[1].componentsSeparatedByString("=")
        return keyValue[1]
    }
    
    // MARK: Build Destination URL
    
    private func getBaseRequestParameters() -> Parameters {
        let timestamp = (floor(NSDate().timeIntervalSince1970) as NSNumber).stringValue
        let nonce = NSUUID().UUIDString
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
        case .RequestToken:
            parameters[OAuthParameterKey.Callback.rawValue] = callbackURL
        case .AccessToken:
            parameters[OAuthParameterKey.Token.rawValue] = token!
        case .Default:
            break
        }
        
        return parameters
    }
    
    private func getRequestParametersWithAdditionalParameters(param: Parameters) -> Parameters {
        var parameters = getBaseRequestParameters()
        param.forEach { parameters[$0] = $1 }
        return parameters
    }
    
    private func encriptedURLWithBaseURL(url: String, requestParameters parameters: Parameters, httpMethod: HttpMethod = .GET) -> String {
        var parameters = parameters
        let urlStringBeforeSignature = sortedURLString(url, requestParameters: parameters, urlEscape: true)
        
        let secretKey = "\(consumerSecret)&\(tokenSecret ?? "")"
        let signatureString = "\(httpMethod.rawValue)&\(urlStringBeforeSignature)"
        let signature = signatureString.generateHMACSHA1EncriptedString(secretKey: secretKey)
        
        parameters[OAuthParameterKey.Signature.rawValue] = signature
        let urlStringWithSignature = sortedURLString(url, requestParameters: parameters, urlEscape: false)
        
        return urlStringWithSignature
    }
    
    private func sortedURLString(url: String, requestParameters dictionary: Parameters, urlEscape: Bool) -> String {
        func urlEscapingIfNeeded(inout string: String) {
            if urlEscape { string = String.urlEncodedStringFromString(string) }
        }
        
        var pairs = [String]()
        let keys = Array(dictionary.keys).sort { $0.localizedCaseInsensitiveCompare($1) == .OrderedAscending }
        
        keys.forEach { key in
            let value = dictionary[key]!
            let escapedValue = String.oauthEncodedStringFromString(value)
            pairs.append("\(key)=\(escapedValue)")
        }
        
        var urlString = url
        urlEscapingIfNeeded(&urlString)
        urlString += (urlEscape ? "&" : "?")
        
        var args = pairs.joinWithSeparator("&")
        urlEscapingIfNeeded(&args)
        urlString += args
        
        return urlString
    }
    
    // MARK: Process on Response
    
    private func processOnResponse(data: NSData?, response: NSURLResponse?, error: NSError?) {
        func sendError(error: String) {
            print("Failed authorize with Flickr. Error: \(error).")
            performOnMain {
                let error = NSError(domain: "\(BaseErrorDomain).FlickrOAuth", code: 55,
                    userInfo: [NSLocalizedDescriptionKey : error])
                self.resultBlock(result: .Failure(error: error))
            }
        }
        
        guard error == nil else {
            sendError(error!.localizedDescription)
            return
        }
        
        guard let data = data,
            let responseString = String(data: data, encoding: NSUTF8StringEncoding) else {
                sendError("Could not get response string.")
                return
        }
        
        let parameters = parametersFromResponseString(responseString)
        
        switch currentState {
        case .RequestToken:
            guard let oauthStatus = parameters[OAuthResponseKey.CallbackConfirmed.rawValue]
                where (oauthStatus as NSString).boolValue == true else {
                    sendError("Failed to get a request token. OAuth status is not confirmed.")
                    return
            }
            updateTokensFromResponseParameters(parameters)
            
            performOnMain {
                self.promtsUserForAuthorization { [unowned self] callbackURL in
                    self.getAccessTokenFromAuthorizationCallbackURL(callbackURL)
                }
            }
        case .AccessToken:
            guard let username = parameters[OAuthResponseKey.Username.rawValue],
                let userID = parameters[OAuthResponseKey.UserID.rawValue],
                let fullname = parameters[OAuthResponseKey.Fullname.rawValue]?.stringByRemovingPercentEncoding
                where username.characters.count > 0 else {
                    sendError("Failed to get an access token.")
                    return
            }
            updateTokensFromResponseParameters(parameters)
            
            performOnMain {
                let result = FlickrOAuthResult.Success(
                    token: self.token!,
                    tokenSecret: self.tokenSecret!,
                    user: FlickrUser(fullname: fullname, username: username, userID: userID)
                )
                self.resultBlock(result: result)
            }
        default:
            break
        }
    }
    
    private func parametersFromResponseString(responseString: String) -> Parameters {
        let parameters = responseString.componentsSeparatedByString("&")
        var dictionary = [String: String]()
        parameters.forEach {
            let components = $0.componentsSeparatedByString("=")
            let key = components[0]
            let value = components[1]
            dictionary[key] = value
        }
        
        return dictionary
    }
    
    private func updateTokensFromResponseParameters(parameters: Parameters) {
        token = parameters[OAuthResponseKey.Token.rawValue]
        tokenSecret = parameters[OAuthResponseKey.TokenSecret.rawValue]
        if currentState == .AccessToken { storeTokensInKeychain() }
    }
    
    // MARK: Keychain Support
    
    class func removeTokensFromKeychain() {
        let keychain = FlickrOAuth.getKeychain()
        keychain[kAccessTokenKeychainKey] = nil
        keychain[kTokenSecretKeychainKey] = nil
    }
    
    class func getTokensFromKeychain() -> (accessToken: String?, tokenSecret: String?) {
        let keychain = FlickrOAuth.getKeychain()
        let token = keychain[kAccessTokenKeychainKey]
        let tokenSecret = keychain[kTokenSecretKeychainKey]
        
        return (token, tokenSecret)
    }
    
    private class func getKeychain() -> Keychain {
        return Keychain(service: kKeychainServiceName)
    }
    
    private func storeTokensInKeychain() {
        let keychain = FlickrOAuth.getKeychain()
        keychain[kAccessTokenKeychainKey] = token!
        keychain[kTokenSecretKeychainKey] = tokenSecret!
    }
    
    private func getTokensFromKeychain() -> Bool {
        let keychain = FlickrOAuth.getKeychain()
        guard let token = keychain[kAccessTokenKeychainKey],
            let tokenSecret = keychain[kTokenSecretKeychainKey] else {
                return false
        }
        
        self.token = token
        self.tokenSecret = tokenSecret
        
        return true
    }
    
}
