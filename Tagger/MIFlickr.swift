//
//  MIFlickr.swift
//  Tagger
//
//  Created by Ivan Magda on 25/06/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import Foundation

// MARK: MIFlickr

class MIFlickr {
    
    // MARK: - Properties
    
    /**
     *  This class constant provides an easy way to get access
     *  to a shared instance of the MIFlickr class.
     */
    static let sharedInstance = MIFlickr()
    
    let api: FlickrApiClient
    let OAuth: FlickrOAuth
    
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
