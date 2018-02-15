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

// MARK: ApiClientResult

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
enum ApiClientResult {
    case rawData(Data)
    case json(JSONDictionary)
    case error(Error)
    case notFound
    case serverError(Int)
    case clientError(Int)
    case unexpectedError(Int, Error?)
}

// MARK: - ApiClientResult (Error Message) -

extension ApiClientResult {
    
    func defaultErrorMessage() -> String? {
        switch self {
        case .error(let error):
            return error.localizedDescription
        case .notFound:
            return NSLocalizedString("Not found.",
                                     comment: "Requested URL not found")
        case .serverError(let code):
            return NSLocalizedString("Server error.",
                                     comment: "Server error occured with code: \(code)")
        case .clientError(let code):
            return NSLocalizedString("Client error.",
                                     comment: "Client error occured with code: \(code)")
        case .unexpectedError(let code, let error):
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
