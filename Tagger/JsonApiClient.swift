//
//  JsonApiClient.swift
//  On the Map
//
//  Created by Ivan Magda on 20.03.16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// MARK: Types -

private struct ErrorDomain {
    static let Base = "\(BaseErrorDomain).JsonApiClient"
    static let EmptyResponse = "\(Base).empty-response"
    static let JSONDeserializing = "\(Base).jsonerror.deserializing"
    static let NotSuccsessfullResponse = "\(Base).bad-response-code"
}

private enum ErrorCode: Int {
    case EmptyResponse = 120
    case JSONDeserializing = 121
    case NotSuccsessfullResponseStatusCode = 122
}

// MARK: - Typealiases

typealias JsonDeserializingCompletionHandler = (jsonObject: AnyObject?, error: NSError?) -> Void

// MARK: - JsonApiClient: HttpApiClient -

class JsonApiClient: HttpApiClient {
    
    // MARK: Data Tasks
    
    func fetchJson(request: NSURLRequest, completionHandler: TaskCompletionHandler) {
        fetchRawData(request) { result in
            switch result {
            case .RawData(let data):
                // Deserializing the JSON data.
                self.deserializeJsonData(data) { (jsonObject, error) in
                    guard error == nil else {
                        completionHandler(.Error(error!))
                        return
                    }
                    
                    // Try to give raw JSON a usable Foundation object form.
                    guard let json = jsonObject as? JSONDictionary else {
                        let errorMessage = "Could not cast the JSON object as JSONDictionary: '\(jsonObject)'"
                        self.debugLog(errorMessage)
                        
                        let userInfo = [NSLocalizedDescriptionKey: errorMessage]
                        let error = NSError(domain: ErrorDomain.JSONDeserializing,
                                            code: ErrorCode.JSONDeserializing.rawValue, userInfo: userInfo)
                        completionHandler(.Error(error))
                        return
                    }
                    
                    completionHandler(.Json(json))
                }
            default:
                completionHandler(result)
            }
        }
    }
    
    // MARK: JSON Deserializing
    
    func deserializeJsonData(data: NSData, completionHandler: JsonDeserializingCompletionHandler) {
        var deserializedJSON: AnyObject?
        
        do {
            deserializedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
        } catch let error as NSError {
            completionHandler(jsonObject: nil, error: error)
        }
        
        completionHandler(jsonObject: deserializedJSON, error: nil)
    }
    
}
