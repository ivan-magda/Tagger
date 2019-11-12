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

        static let baseURL = "https://api.imagga.com/v2"
        
        // MARK: - Params

        struct Params {

            // MARK: Keys

            struct Keys {
                static let content = "content"
                static let imageFile = "image"
            }
        }
        
        // MARK: - Response

        struct Response {

            // MARK: Keys

            struct Keys {
                static let status = "status"
                static let message = "message"
                static let uploaded = "uploaded"
                static let id = "id"
                static let results = "results"
                static let result = "result"
                static let tag = "tag"
                static let tags = "tags"
                static let confidence = "confidence"
            }

            // MARK: Values

            struct Values {
                static let successStatus = "success"
            }
        }
    }
    
}
