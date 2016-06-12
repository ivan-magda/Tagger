//
//  HttpApiClient.swift
//  On the Map
//
//  Created by Ivan Magda on 20.03.16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// MARK: Types -

private struct ErrorDomain {
    static let Base = "\(BaseErrorDomain).HttpApiClient"
    static let BadResponse = "\(Base).bad-response"
    static let EmptyResponse = "\(Base).empty-response"
}

private enum ErrorCode: Int {
    case BadResponse = 100
    case EmptyResponse = 101
}

// MARK: - Typealiases

typealias MethodParameters = [String: AnyObject]
typealias TaskCompletionHandler = (result: ApiClientResult) -> Void

// MARK: - HttpApiClient -

class HttpApiClient {
    
    // MARK: Properties -
    
    /// Allow to initialize with whichever configuration you want.
    let configuration: NSURLSessionConfiguration
    
    let baseURL: String
    
    lazy var session: NSURLSession = {
        return NSURLSession(configuration: self.configuration)
    }()
    
    /**
     Keep track of all requests that are in flight.
     
     @return Set of NSURLSessionDataTasks, that are active.
     */
    var currentTasks: Set<NSURLSessionDataTask> = []
    
    /// If value is `true` then debug messages will be logged.
    var loggingEnabled = false
    
    // MARK: - Initializers
    
    init(configuration: NSURLSessionConfiguration, baseURL: String) {
        self.configuration = configuration
        self.baseURL = baseURL
    }
    
    // MARK: - Network -
    
    func cancelAllRequests() {
        currentTasks.forEach { $0.cancel() }
        currentTasks = []
    }
    
    // MARK: Data Tasks
    
    func fetchRawDataForRequest(request: NSURLRequest, completionHandler: TaskCompletionHandler) {
        let task = dataTaskWithRequest(request) { result in
            performOnMain {
                completionHandler(result: result)
            }
        }
        task.resume()
    }
    
    func dataTaskWithRequest(request: NSURLRequest, completionHandler: TaskCompletionHandler) -> NSURLSessionDataTask {
        var task: NSURLSessionDataTask?
        task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            self.currentTasks.remove(task!)
            
            guard error == nil else {
                self.debugLog("Received an error from HTTP \(request.HTTPMethod!) to \(request.URL!).")
                self.debugLog("Error: \(error).")
                completionHandler(result: .Error(error!))
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.debugLog("Failed on response processing.")
                self.debugLog("Error: \(error).")
                let error = NSError(
                    domain: ErrorDomain.BadResponse,
                    code: ErrorCode.BadResponse.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "Failed processing on HTTP response."]
                )
                completionHandler(result: .Error(error))
                return
            }
            
            // Did we get a successful 2XX response?
            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200...299:
                self.debugLog("Status code: \(statusCode).")
            case 404:
                completionHandler(result: .NotFound)
                return
            case 400...499:
                completionHandler(result: .ClientError(statusCode))
                return
            case 500...599:
                completionHandler(result: .ServerError(statusCode))
                return
            default:
                print("Received HTTP status code \(statusCode), which was't be handled.")
                completionHandler(result: .UnexpectedError(statusCode, error))
                return
            }
            self.debugLog("Received HTTP \(httpResponse.statusCode) from \(request.HTTPMethod!) to \(request.URL!)")
            
            guard let data = data else {
                self.debugLog("Received an empty response.")
                let error = NSError(
                    domain: ErrorDomain.EmptyResponse,
                    code: ErrorCode.EmptyResponse.rawValue,
                    userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request."]
                )
                completionHandler(result: .Error(error))
                return
            }
            completionHandler(result: .RawData(data))
        })
        currentTasks.insert(task!)
        
        return task!
    }
    
    // MARK: - Building URL
    
    func urlFromParameters(parameters: MethodParameters?, withPathExtension pathExtension: String? = nil) -> NSURL {
        let components = NSURLComponents(string: baseURL)!
        components.path = (components.path ?? "") + (pathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        guard let parameters = parameters else {
            return components.URL!
        }
        parameters.forEach { components.queryItems!.append(NSURLQueryItem(name: $0, value: "\($1)")) }
        
        return components.URL!
    }
    
    // MARK: - Debug Logging
    
    func debugLog(msg: String) {
        guard loggingEnabled else { return }
        print(msg)
    }
    
    func debugResponseData(data: NSData) {
        guard loggingEnabled else { return }
        
        guard let body = String(data: data, encoding: NSUTF8StringEncoding) else {
            print("<empty response>")
            return
        }
        print(body)
    }
    
}