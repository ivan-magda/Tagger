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
    case discover
    case tagging
    case more
}

// MARK: - AppDelegate: UIResponder, UIApplicationDelegate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: Instance Variables

    var window: UIWindow?

    private let flickr = IMFlickr.shared
    private let persistenceCentral = PersistenceCentral.shared

    // MARK: UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        setup()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        persistenceCentral.coreDataStackManager.saveContext()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        persistenceCentral.coreDataStackManager.saveContext()
    }
}

// MARK: - AppDelegate (Setup) -

extension AppDelegate {
    private func setup() {
        checkConstants()
        shareData()
        themeApplication()
    }

    private func checkConstants() {
        assert(
                Tagger.Constants.Flickr.applicationKey != "REPLACE_WITH_YOUR_FLICKR_API_KEY" &&
                Tagger.Constants.Flickr.applicationSecret != "REPLACE_WITH_YOUR_FLICKR_API_SECRET" &&
                Tagger.Constants.Flickr.OAuthCallbackURL != "REPLACE_WITH_YOUR_CALLBACK_URL" &&
                Tagger.Constants.Imagga.applicationKey != "REPLACE_WITH_YOUR_IMAGGA_API_KEY" &&
                Tagger.Constants.Imagga.applicationSecret != "REPLACE_WITH_YOUR_IMAGGA_API_SECRET" &&
                Tagger.Constants.Imagga.authenticationToken != "REPLACE_WITH_YOUR_IMAGGA_AUTHORIZATION",
                "Change the constants properties with your own instances."
        )
    }

    private func shareData() {
        let tabBarController = window!.rootViewController as! UITabBarController

        let discoverNavigationController = tabBarController.viewControllers![TabBarControllerItem.discover.rawValue] as! UINavigationController
        let discoverViewController = discoverNavigationController.topViewController as! DiscoverTagsViewController
        discoverViewController.flickr = flickr
        discoverViewController.persistenceCentral = persistenceCentral

        let taggingNavigationController = tabBarController.viewControllers![TabBarControllerItem.tagging.rawValue] as! UINavigationController
        let taggingDataSourceViewController = taggingNavigationController.topViewController as! ImageTaggerDataSourceViewController
        taggingDataSourceViewController.flickr = flickr
        taggingDataSourceViewController.persistenceCentral = persistenceCentral

        let moreInfoNavigationController = tabBarController.viewControllers![TabBarControllerItem.more.rawValue] as! UINavigationController
        let moreInfoTableViewController = moreInfoNavigationController.topViewController as! MoreInfoTableViewController
        moreInfoTableViewController.flickr = flickr
        moreInfoTableViewController.persistenceCentral = persistenceCentral
    }
}

// MARK: - AppDelegate (UI) -

extension AppDelegate {
    private func themeApplication() {
        window?.tintColor = UIColor(.primary)
    }
}
