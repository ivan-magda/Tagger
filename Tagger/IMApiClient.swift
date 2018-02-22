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

// MARK: - Typealias

typealias IMFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - IMApiClient: JsonApiClient -

class IMApiClient: JsonApiClient {}

// MARK: - IMApiClient (Networking) -

extension IMApiClient {

    // MARK: Public

    func getResource<T: JSONParselable>(for request: URLRequest,
                                        success: @escaping (T) -> Void,
                                        failure: @escaping IMFailureCompletionHandler) {
        getResource(for: request, parse: { json -> T? in
            return T.decode(json)
        }, success: success, failure: failure)
    }

    func getCollection<T: JSONParselable>(for request: URLRequest,
                                          rootKeys: [String],
                                          success: @escaping ([T]) -> Void,
                                          failure: @escaping IMFailureCompletionHandler) {
        getCollection(for: request, rootKeys: rootKeys, parse: { (json) -> [T]? in
            return json.flatMap { T.decode($0) }
        }, success: success, failure: failure)
    }

    // MARK: Private

    private func getResource<T>(for request: URLRequest,
                                parse: @escaping (JSONDictionary) -> T?,
                                success: @escaping (T) -> Void,
                                failure: @escaping IMFailureCompletionHandler) {
        fetchJson(for: request) { [unowned self] result in
            if let error = self.isContainsError(result: result) {
                failure(error)
                return
            }

            switch result {
            case .json(let json):
                onBackgroud {
                    guard let resource = parse(json) else {
                        self.log("WARNING: Couldn't parse the following JSON as a \(T.self)")
                        self.log("\(json)")

                        onMain {
                            failure(NSError(domain: ErrorDomain.UnexpectedResponse,
                                         code: ErrorCode.unexpectedResponse.rawValue,
                                         userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."]))
                        }

                        return
                    }

                    onMain {
                        success(resource)
                    }
                }
            default:
                failure(NSError(domain: ErrorDomain.UnexpectedSituation,
                             code: ErrorCode.unexpectedSituation.rawValue,
                             userInfo: [NSLocalizedDescriptionKey : "Unexpected error."]))
            }
        }
    }

    private func getCollection<T>(for request: URLRequest,
                                  rootKeys: [String],
                                  parse: @escaping ([JSONDictionary]) -> [T]?,
                                  success: @escaping ([T]) -> Void,
                                  failure: @escaping IMFailureCompletionHandler) {
        func getJSONParseError() -> Error {
            return NSError(
                domain: ErrorDomain.UnexpectedResponse,
                code: ErrorCode.unexpectedResponse.rawValue,
                userInfo: [NSLocalizedDescriptionKey : "Couldn't parse the returned JSON."]
            )
        }

        fetchJson(for: request) { [unowned self] result in
            if let error = self.isContainsError(result: result) {
                failure(error)
                return
            }

            switch result {
            case .json(let json):
                onBackgroud {
                    let keyPath = rootKeys.joined(separator: ".")
                    guard let jsonArray = (json as NSDictionary).value(forKeyPath: keyPath) as? [JSONDictionary] else {
                        onMain {
                            failure(getJSONParseError())
                        }
                        return
                    }

                    guard let collection = parse(jsonArray) else {
                        self.log("WARNING: Couldn't parse the following JSON as a \(T.self)")
                        self.log("\(json)")

                        onMain {
                            failure(getJSONParseError())
                        }

                        return
                    }

                    onMain {
                        success(collection)
                    }
                }
            default:
                failure(
                    NSError(domain: ErrorDomain.UnexpectedSituation,
                            code: ErrorCode.unexpectedSituation.rawValue,
                            userInfo: [NSLocalizedDescriptionKey : "Unexpected situation reached."]
                    )
                )
            }
        }
    }
}

// MARK: - IMApiClient (Utility) -

extension IMApiClient {

    func isContainsError(result: ApiClientResult) -> Error? {
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
