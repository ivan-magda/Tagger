//
//  MIFlickr.swift
//  Tagger
//
//  Created by Ivan Magda on 25/06/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// MARK: Constants

private let kFlickrCurrentUserKey = "FLICKR_CURRENT_USER_KEY"

// MARK: - MIFlickr

class MIFlickr {
    
    // MARK: - Properties
    
    /**
     *  This class constant provides an easy way to get access
     *  to a shared instance of the MIFlickr class.
     */
    static let sharedInstance = MIFlickr()
    
    let api: FlickrApiClient
    let OAuth: FlickrOAuth
    
    var currentUser: FlickrUser? {
        get {
            guard let data = NSUserDefaults.standardUserDefaults().objectForKey(kFlickrCurrentUserKey) as? NSData,
                let user = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? FlickrUser else {
                    return nil
            }
            
            return user
        }
        
        set {
            let userDefaults = NSUserDefaults.standardUserDefaults()
            
            if let newValue = newValue {
                let data = NSKeyedArchiver.archivedDataWithRootObject(newValue)
                userDefaults.setObject(data, forKey: kFlickrCurrentUserKey)
            } else {
                userDefaults.setObject(nil, forKey: kFlickrCurrentUserKey)
            }
            
            userDefaults.synchronize()
        }
    }
    
    // MARK: Init
    
    private init() {
        self.api = FlickrApiClient.sharedInstance
        self.OAuth = FlickrOAuth(
            consumerKey: FlickrApplicationKey,
            consumerSecret: FlickrApplicationSecret,
            callbackURL: FlickrOAuthCallbackURL
        )
    }
    
}
