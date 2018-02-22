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

// MARK: - Constants for project

final class Tagger {

    struct Constants {

        // MARK: Flickr

        struct Flickr {
            static let applicationKey = "REPLACE_WITH_YOUR_FLICKR_API_KEY"
            static let applicationSecret = "REPLACE_WITH_YOUR_FLICKR_API_SECRET"
            static let OAuthCallbackURL = "REPLACE_WITH_YOUR_CALLBACK_URL"
        }

        // MARK: Imagga

        struct Imagga {
            static let applicationKey = "REPLACE_WITH_YOUR_IMAGGA_API_KEY"
            static let applicationSecret = "REPLACE_WITH_YOUR_IMAGGA_API_SECRET"
            static let authenticationToken = "REPLACE_WITH_YOUR_IMAGGA_AUTHORIZATION"
        }

        // MARK: URL Schemes

        struct URLSchemes {
            static let instagram = "instagram://app"
            static let fLickr = "flickr://"
        }

        // MARK: Error

        struct Error {
            static let baseDomain = "com.ivanmagda.Tagger"
        }

    }

    private init() {
    }

}
