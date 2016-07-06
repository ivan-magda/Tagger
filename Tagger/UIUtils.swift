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

// MARK: UIUtils -

class UIUtils {
    
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
    
    class func statusBarHeight() -> CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.height
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
    
    // MARK: Status Bar
    
    class func setStatusBarBackgroundColor(color: UIColor) {
        guard let statusBar = UIApplication.sharedApplication().valueForKey("statusBarWindow")?.valueForKey("statusBar") as? UIView else {
            return
        }
        statusBar.backgroundColor = color
    }
    
}
