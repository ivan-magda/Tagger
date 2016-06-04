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

typealias TaskCompletionHandler = ApiClientResult -> Void

// MARK: - HttpApiClient -

class HttpApiClient {
    
    // MARK: Properties -
    
    /// Allow to initialize with whichever configuration you want.
    let configuration: NSURLSessionConfiguration
    
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
    
    init(configuration: NSURLSessionConfiguration) {
        self.configuration = configuration
    }
    
    // MARK: - Network -
    
    func cancelAllRequests() {
        for task in self.currentTasks {
            task.cancel()
        }
        self.currentTasks = []
    }
    
    // MARK: Data Tasks
    
    func fetchRawData(request: NSURLRequest, completion: TaskCompletionHandler) {
        let task = dataTaskWithRequest(request, completion: completion)
        task.resume()
    }
    
    func dataTaskWithRequest(request: NSURLRequest, completion: TaskCompletionHandler) -> NSURLSessionDataTask {
        var task: NSURLSessionDataTask?
        task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in
            self.currentTasks.remove(task!)
            
            /* GUARD: Was there an error? */
            guard error == nil else {
                self.debugLog("Received an error from HTTP \(request.HTTPMethod!) to \(request.URL!)")
                self.debugLog("Error: \(error)")
                completion(.Error(error!))
                return
            }
            
            guard let httpResponse = response as? NSHTTPURLResponse else {
                self.debugLog("Failed on response processing.")
                self.debugLog("Error: \(error)")
                let userInfo = [NSLocalizedDescriptionKey: "Failed processing on HTTP response."]
                let error = NSError(
                    domain: ErrorDomain.BadResponse,
                    code: ErrorCode.BadResponse.rawValue,
                    userInfo: userInfo
                )
                completion(.Error(error))
                return
            }
            
            // Did we get a successful 2XX response?
            let statusCode = httpResponse.statusCode
            switch statusCode {
            case 200...299:
                self.debugLog("Status code: \(statusCode)")
            case 404:
                completion(.NotFound)
                return
            case 400...499:
                completion(.ClientError(statusCode))
                return
            case 500...599:
                completion(.ServerError(statusCode))
                return
            default:
                print("Received HTTP status code \(statusCode), which was't be handled")
                completion(.UnexpectedError(statusCode, error))
                return
            }
            
            self.debugLog("Received HTTP \(httpResponse.statusCode) from \(request.HTTPMethod!) to \(request.URL!)")
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                self.debugLog("Received an empty response")
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request"]
                let error = NSError(
                    domain: ErrorDomain.EmptyResponse,
                    code: ErrorCode.EmptyResponse.rawValue,
                    userInfo: userInfo
                )
                completion(ApiClientResult.Error(error))
                return
            }
            
            completion(ApiClientResult.RawData(data))
        })
        currentTasks.insert(task!)
        
        return task!
    }
    
    // MARK: - Debug Logging
    
    func debugLog(msg: String) {
        guard loggingEnabled else { return }
        print(msg)
    }
    
    func debugResponseData(data: NSData) {
        guard loggingEnabled else { return }
        
        if let body = String(data: data, encoding: NSUTF8StringEncoding) {
            print(body)
        } else {
            print("<empty response>")
        }
    }
    
}