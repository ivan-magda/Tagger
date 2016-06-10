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

typealias DeserializedJsonTuple = (json: AnyObject?, error: NSError?)

// MARK: - JsonApiClient: HttpApiClient -

class JsonApiClient: HttpApiClient {
    
    // MARK: Data Tasks
    
    func fetchJsonForRequest(request: NSURLRequest, completionHandler: TaskCompletionHandler) {
        fetchRawDataForRequest(request) { result in
            switch result {
            case .RawData(let data):
                let deserializedJson = self.deserializeJsonData(data)
                
                guard deserializedJson.error == nil else {
                    completionHandler(result: .Error(deserializedJson.error!))
                    return
                }
                
                guard let json = deserializedJson.json as? JSONDictionary else {
                    let errorMessage = "Could not cast the JSON object as JSONDictionary: '\(deserializedJson.json)'"
                    self.debugLog(errorMessage)
                    
                    let error = NSError(domain: ErrorDomain.JSONDeserializing,
                                        code: ErrorCode.JSONDeserializing.rawValue,
                                        userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    completionHandler(result: .Error(error))
                    return
                }
                completionHandler(result: .Json(json))
            default:
                completionHandler(result: result)
            }
        }
    }
    
    // MARK: JSON Deserializing
    
    func deserializeJsonData(data: NSData) -> DeserializedJsonTuple {
        do {
            let deserializedJSON = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            return (json: deserializedJSON, error: nil)
        } catch let error as NSError {
            return (json: nil, error: error)
        }
    }
    
}
