//
//  UIUtils.swift
//  VirtualTourist
//
//  Created by Ivan Magda on 17/05/16.
//  Copyright © 2016 Ivan Magda. All rights reserved.
//

import UIKit.UIScreen
import CoreGraphics.CGGeometry

// MARK: UIUtils -

class UIUtils {
    
    // MARK: Properties
    
    static let placeholderImageName = "Placeholder"
    static let checkmarkImageName = "Checkmark"
    static let editImageName = "Edit"
    
    // MARK: Init
    
    private init() {
    }
    
    // MARK: - Class Functions -
    // MARK: Screen Sizes
    
    class func screenBounds() -> CGRect {
        return UIScreen.mainScreen().bounds
    }
    
    class func screenSize() -> CGSize {
        return UIScreen.mainScreen().bounds.size
    }
    
    // MARK: Network Indicator
    
    class func showNetworkActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    class func hideNetworkActivityIndicator() {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    // MARK: View Controller
    
    class func getRootViewController() -> UIViewController? {
        return UIApplication.sharedApplication().keyWindow?.rootViewController
    }
    
}
