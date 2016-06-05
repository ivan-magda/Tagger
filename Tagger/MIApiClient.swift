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
    static let Base = "\(BaseErrorDomain).MIApiClient"
    static let ApiRequest = "\(Base).api-request"
    static let UnexpectedResponse = "\(Base).api-request-unexpected-response"
    static let UnexpectedSituation = "\(Base).api-request-unexpected-situation"
}

private enum ErrorCode: Int {
    case FailureApiRequestReason = 130
    case UnexpectedResponse = 131
    case UnexpectedSituation = 132
}

// MARK: Typealias

typealias MIFailureCompletionHandler = (error: NSError) -> Void

// MARK: - MIApiClient: JsonApiClient -

class MIApiClient: JsonApiClient {
    
    // MARK: - Requests -
    // MARK: Public
    
    func fetchResource<T: JSONParselable>(request: NSURLRequest, success: T -> Void, fail: MIFailureCompletionHandler) {
        fetchForResource(request, parseBlock: { json -> T? in
            return T.decode(json)
            }, success: success, fail: fail)
    }
    
    func fetchCollection<T: JSONParselable>(request: NSURLRequest, rootKeys: [String], success: [T] -> Void, fail: MIFailureCompletionHandler) {
        fetchForCollection(request, rootKeys: rootKeys, parseBlock: { (json) -> [T]? in
            return json.flatMap { T.decode($0) }
            }, success: success, failure: fail)
    }
    
    // MARK: Private
    
    private func fetchForResource<T>(request: NSURLRequest, parseBlock: JSONDictionary -> T?, success: T -> Void, fail: MIFailureCompletionHandler) {
        fetchJson(request) { result in
            performOnMain {
                if let error = self.checkApiClientResultForAnError(result) {
                    fail(error: error)
                } else {
                    switch result {
                    case .Json(let json):
                        if let resource = parseBlock(json) {
                            success(resource)
                        } else {
                            self.debugLog("WARNING: Couldn't parse the following JSON as a \(T.self)")
                            self.debugLog("\(json)")
                            
                            let error = NSError(
                                domain: ErrorDomain.UnexpectedResponse,
                                code: ErrorCode.UnexpectedResponse.rawValue,
                                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."]
                            )
                            
                            fail(error: error)
                        }
                    default:
                        fail(error: NSError(domain: ErrorDomain.UnexpectedSituation,
                            code: ErrorCode.UnexpectedSituation.rawValue,
                            userInfo: [NSLocalizedDescriptionKey : "Unexpected situation reached."]))
                    }
                }
            }
        }
    }
    
    private func fetchForCollection<T>(request: NSURLRequest, rootKeys: [String], parseBlock: [JSONDictionary] -> [T]?, success: [T] -> Void, failure: MIFailureCompletionHandler) {
        func parsingJsonError() -> NSError {
            return NSError(
                domain: ErrorDomain.UnexpectedResponse,
                code: ErrorCode.UnexpectedResponse.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."]
            )
        }
        
        fetchJson(request) { result in
            performOnMain {
                if let error = self.checkApiClientResultForAnError(result) {
                    failure(error: error)
                } else {
                    switch result {
                    case .Json(let json):
                        var jsonArray: [JSONDictionary]?
                        var json = json
                        for key in rootKeys {
                            if key == rootKeys.last! {
                                jsonArray = json[key] as? [JSONDictionary]
                            } else {
                                if let node = json[key] as? JSONDictionary {
                                    json = node
                                } else {
                                    failure(error: parsingJsonError())
                                    self.debugLog("\(json)")
                                    return
                                }
                            }
                        }
                        
                        guard jsonArray != nil else {
                            failure(error: parsingJsonError())
                            return
                        }
                        
                        if let resourceCollection = parseBlock(jsonArray!) {
                            success(resourceCollection)
                        } else {
                            self.debugLog("WARNING: Couldn't parse the following JSON as a \(T.self)")
                            self.debugLog("\(json)")
                            failure(error: parsingJsonError())
                        }
                    default:
                        failure(error: NSError(domain: ErrorDomain.UnexpectedSituation,
                            code: ErrorCode.UnexpectedSituation.rawValue,
                            userInfo: [NSLocalizedDescriptionKey : "Unexpected situation reached."]))
                    }
                }
            }
        }
    }
    
    private func checkApiClientResultForAnError(result: ApiClientResult) -> NSError? {
        switch result {
        case .Error, .NotFound, .ServerError, .ClientError, .UnexpectedError:
            let message = result.defaultErrorMessage()!
            var rawDataString: String?
            
            switch result {
            case .RawData(let data):
                rawDataString = String(data: data, encoding: NSUTF8StringEncoding)
            default:
                break
            }
            
            self.debugLog("Failed to perform api request. Message: \(message)")
            if let rawDataString = rawDataString {
                self.debugLog("Raw data string: \(rawDataString)")
            }
            
            let error = NSError(
                domain: ErrorDomain.ApiRequest,
                code: ErrorCode.FailureApiRequestReason.rawValue,
                userInfo: [NSLocalizedDescriptionKey : message]
            )
            
            return error
        default:
            return nil
        }
    }
    
}
