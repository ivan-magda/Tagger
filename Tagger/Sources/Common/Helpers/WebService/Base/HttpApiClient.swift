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
    static let Base = "\(Tagger.Constants.Error.baseDomain).HttpApiClient"
    static let BadResponse = "\(Base).bad-response"
    static let EmptyResponse = "\(Base).empty-response"
}

private enum ErrorCode: Int {
    case badResponse = 100
    case emptyResponse = 101
}

// MARK: - Typealiases

typealias HttpMethodParams = [String: Any]
typealias TaskCompletionHandler = (_ result: ApiClientResult) -> Void

// MARK: - HttpApiClient -

class HttpApiClient {
    
    // MARK: Instance variables
    
    /// Allow to initialize with whichever configuration you want.
    let configuration: URLSessionConfiguration
    
    let baseURL: String
    
    lazy var session: URLSession = {
        return URLSession(configuration: self.configuration)
    }()
    
    /**
     Keep track of all requests that are in flight.
     
     @return Set of NSURLSessionDataTasks, that are active.
     */
    var currentTasks: Set<URLSessionDataTask> = []
    
    /// If value is `true` then debug messages will be logged.
    var loggingEnabled = false
    
    // MARK: Initializers
    
    init(configuration: URLSessionConfiguration, baseURL: String) {
        self.configuration = configuration
        self.baseURL = baseURL
    }
    
}

// MARK: - HttpApiClient (Networking) -

extension HttpApiClient {

    /// Cancels all requests.
    func cancelAll() {
        currentTasks.forEach { $0.cancel() }
        currentTasks = []
    }

    func fetchRawData(for request: URLRequest,
                      with completionHandler: @escaping TaskCompletionHandler) {
        let task = dataTask(for: request) { result in
            onMain {
                completionHandler(result)
            }
        }

        task.resume()
    }

    func dataTask(for request: URLRequest,
                  with completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
        var task: URLSessionDataTask?
        task = session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            self.currentTasks.remove(task!)

            if let error = error {
                self.log("Received an error from HTTP \(request.httpMethod!) to \(request.url!).")
                self.log("Error: \(error.localizedDescription)).")

                completionHandler(.error(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                self.log("Failed on response processing.")
                self.log("Error: \(String(describing: error?.localizedDescription)).")

                let error = NSError(
                    domain: ErrorDomain.BadResponse,
                    code: ErrorCode.badResponse.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Failed process HTTP response."]
                )

                completionHandler(.error(error))
                return
            }

            // Did we get a successful 2XX response?
            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200...299:
                self.log("Status code: \(statusCode).")
            case 404:
                completionHandler(.notFound)
                return
            case 400...499:
                completionHandler(.clientError(statusCode))
                return
            case 500...599:
                completionHandler(.serverError(statusCode))
                return
            default:
                print("Received HTTP status code \(statusCode), which was't be handled.")
                completionHandler(.unexpectedError(statusCode, error))
                return
            }

            self.log("Received HTTP \(httpResponse.statusCode) from \(request.httpMethod!) to \(request.url!)")

            guard let data = data else {
                self.log("Received an empty response.")

                let error = NSError(
                    domain: ErrorDomain.EmptyResponse,
                    code: ErrorCode.emptyResponse.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request."]
                )

                completionHandler(.error(error))
                return
            }

            completionHandler(.rawData(data))
        })
        currentTasks.insert(task!)

        return task!
    }

}

// MARK: - HttpApiClient (Build URL) -

extension HttpApiClient {
    func buildURL(parameters: HttpMethodParams?, withPathExtension pathExtension: String = "") -> URL {
        var components = URLComponents(string: baseURL)!
        components.path = components.path + pathExtension

        guard let parameters = parameters else {
            return components.url!
        }

        components.queryItems = [URLQueryItem]()

        parameters.forEach {
            components.queryItems!.append(
                URLQueryItem(name: $0, value: "\($1)")
            )
        }

        return components.url!
    }

}

// MARK: - HttpApiClient (Debug) -

extension HttpApiClient {

    func log(_ msg: String) {
        guard loggingEnabled else { return }
        print(msg)
    }

    func log(_ data: Data) {
        guard loggingEnabled else { return }

        guard let body = String(data: data, encoding: String.Encoding.utf8) else {
            print("<empty response>")
            return
        }

        print(body)
    }

}
