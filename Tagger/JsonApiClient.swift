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
