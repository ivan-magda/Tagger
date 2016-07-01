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

import UIKit

// MARK: Types

private enum TabBarControllerItem: Int {
    case Discover
    case Tagging
    case More
}

// MARK: - AppDelegate: UIResponder, UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?
    
    private let flickr = MIFlickr.sharedInstance
    private let persistenceCentral = PersistenceCentral.sharedInstance
    
    // MARK: UIApplicationDelegate
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        shareData()
        themeApplication()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        persistenceCentral.coreDataStackManager.saveContext()
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        persistenceCentral.coreDataStackManager.saveContext()
    }
    
    // MARK: Private
    
    private func shareData() {
        let tabBarController = window!.rootViewController as! UITabBarController
        
        let discoverNavigationController = tabBarController.viewControllers![TabBarControllerItem.Discover.rawValue] as! UINavigationController
        let discoverViewController = discoverNavigationController.topViewController as! DiscoverTagsViewController
        discoverViewController.flickr = flickr
        discoverViewController.persistenceCentral = persistenceCentral
        
        let taggingNavigationController = tabBarController.viewControllers![TabBarControllerItem.Tagging.rawValue] as! UINavigationController
        let taggingDataSourceViewController = taggingNavigationController.topViewController as! ImageTaggerDataSourceViewController
        taggingDataSourceViewController.flickr = flickr
        taggingDataSourceViewController.persistenceCentral = persistenceCentral
        
        let moreInfoNavigationController = tabBarController.viewControllers![TabBarControllerItem.More.rawValue] as! UINavigationController
        let moreInfoTableViewController = moreInfoNavigationController.topViewController as! MoreInfoTableViewController
        moreInfoTableViewController.flickr = flickr
        moreInfoTableViewController.persistenceCentral = persistenceCentral
    }
    
    private func themeApplication() {
        window?.tintColor = UIColor(red:0.34, green:0.70, blue:0.64, alpha:1.00)
    }
    
}
