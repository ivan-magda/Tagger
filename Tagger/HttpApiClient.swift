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
    static let Base = "\(BaseErrorDomain).HttpApiClient"
    static let BadResponse = "\(Base).bad-response"
    static let EmptyResponse = "\(Base).empty-response"
}

private enum ErrorCode: Int {
    case badResponse = 100
    case emptyResponse = 101
}

// MARK: - Typealiases

typealias MethodParameters = [String: AnyObject]
typealias TaskCompletionHandler = (_ result: ApiClientResult) -> Void

// MARK: - HttpApiClient -

class HttpApiClient {
    
    // MARK: Properties -
    
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
    
    // MARK: - Initializers
    
    init(configuration: URLSessionConfiguration, baseURL: String) {
        self.configuration = configuration
        self.baseURL = baseURL
    }
    
    // MARK: - Network -
    
    func cancelAllRequests() {
        currentTasks.forEach { $0.cancel() }
        currentTasks = []
    }
    
    // MARK: Data Tasks
    
    func fetchRawDataForRequest(_ request: URLRequest, completionHandler: @escaping TaskCompletionHandler) {
        let task = dataTaskWithRequest(request) { result in
            performOnMain {
                completionHandler(result)
            }
        }
        task.resume()
    }
    
    func dataTaskWithRequest(_ request: URLRequest, completionHandler: @escaping TaskCompletionHandler) -> URLSessionDataTask {
        var task: URLSessionDataTask?
        task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            self.currentTasks.remove(task!)
            
            guard error == nil else {
                self.debugLog("Received an error from HTTP \(request.httpMethod!) to \(request.url!).")
                self.debugLog("Error: \(String(describing: error)).")
                completionHandler(.error(error! as NSError))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                self.debugLog("Failed on response processing.")
                self.debugLog("Error: \(String(describing: error)).")
                let error = NSError(
                    domain: ErrorDomain.BadResponse,
                    code: ErrorCode.badResponse.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Failed processing on HTTP response."]
                )
                completionHandler(.error(error))
                return
            }
            
            // Did we get a successful 2XX response?
            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200...299:
                self.debugLog("Status code: \(statusCode).")
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
                completionHandler(.unexpectedError(statusCode, error! as NSError))
                return
            }
            self.debugLog("Received HTTP \(httpResponse.statusCode) from \(request.httpMethod!) to \(request.url!)")
            
            guard let data = data else {
                self.debugLog("Received an empty response.")
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
    
    // MARK: - Building URL
    
    func urlFromParameters(_ parameters: MethodParameters?, withPathExtension pathExtension: String? = nil) -> URL {
        var components = URLComponents(string: baseURL)!
        components.path = components.path + (pathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        guard let parameters = parameters else {
            return components.url!
        }
        parameters.forEach { components.queryItems!.append(URLQueryItem(name: $0, value: "\($1)")) }
        
        return components.url!
    }
    
    // MARK: - Debug Logging
    
    func debugLog(_ msg: String) {
        guard loggingEnabled else { return }
        print(msg)
    }
    
    func debugResponseData(_ data: Data) {
        guard loggingEnabled else { return }
        
        guard let body = String(data: data, encoding: String.Encoding.utf8) else {
            print("<empty response>")
            return
        }
        print(body)
    }
    
}
