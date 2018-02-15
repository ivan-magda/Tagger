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

// MARK: Typealiases

/// - parameter data: Data to uploaded
/// - parameter name: The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
/// - parameter fileName: Name of the uploading file
typealias MultipartData = (data: Data, name: String, fileName: String)

// MARK: - HttpApiClient (multipart/form-data)

extension HttpApiClient {
    
    /// Creates body of the multipart/form-data request
    ///
    /// - parameter parameters: The optional dictionary containing keys and values to be passed to web service
    /// - parameter files: An optional array containing multipart/form-data parts
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns: The NSData of the body of the request
    func createMultipartBody(params parameters: HttpMethodParams?,
                             files: [MultipartData]?,
                             boundary: String) -> Data {
        let body = NSMutableData()
        

        parameters?.forEach { (key, value) in
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }

        files?.forEach {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition:form-data; name=\"\($0.name)\"; filename=\"\($0.fileName)\"\r\n")
            body.appendString("Content-Type: \($0.data.mimeType)\r\n\r\n")
            body.append($0.data)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)--\r\n")
        
        return body as Data
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns: The boundary string that consists of "Boundary-" followed by a UUID string.
    func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
}

// MARK: - NSMutableData+AppendString -

extension NSMutableData {
    
    /// Append string to NSMutableData
    ///
    /// Rather than littering my code with calls to `dataUsingEncoding` to convert strings to NSData, and then add that data to the NSMutableData, this wraps it in a nice convenient little extension to NSMutableData. This converts using UTF-8.
    ///
    /// - parameter string:       The string to be added to the `NSMutableData`.
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: true)
        append(data!)
    }
    
}
