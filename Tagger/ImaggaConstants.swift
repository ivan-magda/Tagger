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

// MARK: ImaggaApiClient (Constants)

extension ImaggaApiClient {
    
    // MARK: - Constants
    
    struct Constants {

        static let baseURL = "https://api.imagga.com/v1"
        
        // MARK: ParameterKeys
        
        struct ParameterKeys {
            static let Content = "content"
            static let ImageFile = "imagefile"
        }
        
        // MARK: ResponseKeys
        
        struct ResponseKeys {
            static let Status = "status"
            static let Message = "message"
            static let Uploaded = "uploaded"
            static let ID = "id"
            static let Results = "results"
            static let Tag = "tag"
            static let Tags = "tags"
            static let Confidence = "confidence"
        }
        
        // MARK: ResponseValues
        
        struct ResponseValues {
            static let SuccessStatus = "success"
        }
    }
    
}
