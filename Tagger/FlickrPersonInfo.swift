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

// MARK: FlickrPersonInfo

struct FlickrPersonInfo {
    
    // MARK: Properties
    
    let id: String
    let nsid: String
    let iconServer: String
    let iconFarm: Int
    let username: String
    let realName: String
    
    // MARK: Init
    
    init?(json: JSONDictionary) {
        guard let person = json[FlickrApiClient.Constants.Response.Keys.person] as? JSONDictionary,
            let id = JSON.string(person, key: FlickrApiClient.Constants.Response.Keys.id),
            let nsid = JSON.string(person, key: FlickrApiClient.Constants.Response.Keys.NSID),
            let iconServer = JSON.string(person, key: FlickrApiClient.Constants.Response.Keys.iconServer),
            let iconFarm = JSON.int(person, key: FlickrApiClient.Constants.Response.Keys.iconFarm),
            let usernameDict = person[FlickrApiClient.Constants.Response.Keys.username] as? JSONDictionary,
            let username = JSON.string(usernameDict, key: FlickrApiClient.Constants.Response.Keys.content),
            let realNameDict = person[FlickrApiClient.Constants.Response.Keys.realName] as? JSONDictionary,
            let realName = JSON.string(realNameDict, key: FlickrApiClient.Constants.Response.Keys.content) else {
                return nil
        }
        
        self.id = id
        self.nsid = nsid
        self.iconServer = iconServer
        self.iconFarm = iconFarm
        self.username = username
        self.realName = realName
    }
    
}

// MARK: - FlickrPersonInfo: JSONParselable -

extension FlickrPersonInfo: JSONParselable {
    
    static func decode(_ input: JSONDictionary) -> FlickrPersonInfo? {
        return FlickrPersonInfo.init(json: input)
    }
    
}
