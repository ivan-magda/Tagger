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

// MARK: Types

private enum CoderKey: String {
    case fullname
    case username
    case userID
}

// MARK: - FlickrUser: NSObject, NSCoding

class FlickrUser: NSObject, NSCoding {
    
    // MARK: - Properties
    
    let fullname: String
    let username: String
    let userID: String
    
    override var description: String {
        return "FlickrUser {\n\tFullname: \(fullname)\n\tUsername: \(username)\n\tUserID: \(userID).\n}"
    }
    
    // MARK: Init
    
    init(fullname: String, username: String, userID: String) {
        self.fullname = fullname
        self.username = username
        self.userID = userID
    }
    
    // MARK: NSCoding
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let fullname = aDecoder.decodeObject(forKey: CoderKey.fullname.rawValue) as? String,
            let username = aDecoder.decodeObject(forKey: CoderKey.username.rawValue) as? String,
            let userID = aDecoder.decodeObject(forKey: CoderKey.userID.rawValue) as? String else {
                return nil
        }
        
        self.init(fullname: fullname, username: username, userID: userID)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fullname, forKey: CoderKey.fullname.rawValue)
        aCoder.encode(username, forKey: CoderKey.username.rawValue)
        aCoder.encode(userID, forKey: CoderKey.userID.rawValue)
    }
    
}
