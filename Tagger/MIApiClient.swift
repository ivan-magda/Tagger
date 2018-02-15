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
    case failureApiRequestReason = 130
    case unexpectedResponse = 131
    case unexpectedSituation = 132
}

// MARK: Typealias

typealias MIFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - MIApiClient: JsonApiClient -

class MIApiClient: JsonApiClient {
    
    // MARK: - Requests -
    // MARK: Public
    
    func fetchResourceForRequest<T: JSONParselable>(_ request: URLRequest, success: @escaping (T) -> Void, fail: @escaping MIFailureCompletionHandler) {
        fetchForResource(request, parseBlock: { json -> T? in
            return T.decode(json)
            }, success: success, fail: fail)
    }

    func fetchCollectionForRequest<T: JSONParselable>(_ request: URLRequest, rootKeys: [String], success: @escaping ([T]) -> Void, fail: @escaping MIFailureCompletionHandler) {
        fetchForCollection(request, rootKeys: rootKeys, parseBlock: { (json) -> [T]? in
            return json.flatMap { T.decode($0) }
            }, success: success, failure: fail)
    }
    
    // MARK: Private
    
    fileprivate func fetchForResource<T>(_ request: URLRequest, parseBlock: @escaping (JSONDictionary) -> T?, success: @escaping (T) -> Void, fail: @escaping MIFailureCompletionHandler) {
        fetchJsonForRequest(request) { [unowned self] result in
            if let error = self.checkApiClientResultForAnError(result) {
                fail(error)
                return
            }
            
            switch result {
            case .json(let json):
                performOnBackgroud {
                    guard let resource = parseBlock(json) else {
                        self.log("WARNING: Couldn't parse the following JSON as a \(T.self)")
                        self.log("\(json)")
                        performOnMain {
                            fail(NSError(domain: ErrorDomain.UnexpectedResponse,
                                         code: ErrorCode.unexpectedResponse.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."])
                            )
                        }
                        return
                    }
                    performOnMain {
                        success(resource)
                    }
                }
            default:
                fail(NSError(domain: ErrorDomain.UnexpectedSituation,
                             code: ErrorCode.unexpectedSituation.rawValue,
                             userInfo: [NSLocalizedDescriptionKey : "Unexpected error."])
                )
            }
        }
    }
    
    fileprivate func fetchForCollection<T>(_ request: URLRequest, rootKeys: [String], parseBlock: @escaping ([JSONDictionary]) -> [T]?, success: @escaping ([T]) -> Void, failure: @escaping MIFailureCompletionHandler) {
        func parsingJsonError() -> Error {
            return NSError(
                domain: ErrorDomain.UnexpectedResponse,
                code: ErrorCode.unexpectedResponse.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."]
            )
        }
        
        fetchJsonForRequest(request) { [unowned self] result in
            if let error = self.checkApiClientResultForAnError(result) {
                failure(error)
                return
            }
            
            switch result {
            case .json(let json):
                performOnBackgroud {
                    let keyPath = rootKeys.joined(separator: ".")
                    guard let jsonArray = (json as NSDictionary).value(forKeyPath: keyPath) as? [JSONDictionary] else {
                        performOnMain {
                            failure(parsingJsonError())
                        }
                        return
                    }
                    
                    guard let collection = parseBlock(jsonArray) else {
                        self.log("WARNING: Couldn't parse the following JSON as a \(T.self)")
                        self.log("\(json)")
                        performOnMain {
                            failure(parsingJsonError())
                        }
                        return
                    }
                    performOnMain {
                        success(collection)
                    }
                }
            default:
                failure(NSError(domain: ErrorDomain.UnexpectedSituation,
                    code: ErrorCode.unexpectedSituation.rawValue,
                    userInfo: [NSLocalizedDescriptionKey : "Unexpected situation reached."])
                )
            }
        }
    }
    
    // MARK: - Helpers
    
    func checkApiClientResultForAnError(_ result: ApiClientResult) -> Error? {
        switch result {
        case .error, .notFound, .serverError, .clientError, .unexpectedError:
            let message = result.defaultErrorMessage()!
            self.log("Failed to perform api request. Message: \(message).")
            
            switch result {
            case .rawData(let data):
                log(data)
            default:
                break
            }

            return NSError(
                domain: ErrorDomain.ApiRequest,
                code: ErrorCode.failureApiRequestReason.rawValue,
                userInfo: [NSLocalizedDescriptionKey : message]
            )
        default:
            return nil
        }
    }
    
}
