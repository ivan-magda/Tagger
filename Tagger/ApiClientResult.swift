//
//  ApiClientResult.swift
//  On the Map
//
//  Created by Ivan Magda on 20.03.16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

/**
    Represents ApiClient task response in one of many cases, that would have.
 
    - RawData: Successful fetched raw data.
    - Json: Successful fetched raw data and deserialize it to json.
    - Error: Failed with error.
    - NotFound: HTTP response status code is 404.
    - ServerError: HTTP response status code between 500...599.
    - ClientError: HTTP response status code between 400...499.
    - UnexpectedError: Failed wit unexpected error.
*/
public enum ApiClientResult {
    case RawData(NSData)
    case Json(JSONDictionary)
    case Error(NSError)
    case NotFound
    case ServerError(Int)
    case ClientError(Int)
    case UnexpectedError(Int, NSError?)
}

extension ApiClientResult {
    
    func defaultErrorMessage() -> String? {
        switch self {
        case .Error(let error):
            return error.localizedDescription
        case .NotFound:
            return NSLocalizedString("Not found.",
                                     comment: "Requested URL not found")
        case .ServerError(let code):
            return NSLocalizedString("Server error.",
                                     comment: "Server error occured with code: \(code)")
        case .ClientError(let code):
            return NSLocalizedString("Client error.", comment: "Client error occured with code: \(code)")
        case .UnexpectedError(let code, let error):
            return (error == nil
                ? NSLocalizedString("Unexpected error occured with code: \(code).",
                    comment: "Unexpected error default template")
                : NSLocalizedString("Unexpected error occured with code: \(code), error: \(error!.localizedDescription).",
                    comment: "Unexpected error with details"))
        default:
            return nil
        }
    }
    
}
