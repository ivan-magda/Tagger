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

// MARK: UIUtils

final class UIUtils {
    
    // MARK: Init
    
    private init() {
    }
    
}

// MARK: - UIUtils (Screen sizes) -

extension UIUtils {

    static func screenBounds() -> CGRect {
        return UIScreen.main.bounds
    }

    static func screenSize() -> CGSize {
        return UIScreen.main.bounds.size
    }

    static func statusBarHeight() -> CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }

}

// MARK: - UIUtils (Network Indicator) -

extension UIUtils {

    static func showNetworkActivityIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }

    static func hideNetworkActivityIndicator() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

}

// MARK: - UIUtils (UIViewController) -

extension UIUtils {

    static func rootViewController() -> UIViewController? {
        return UIApplication.shared.keyWindow?.rootViewController
    }

}

// MARK: - UIUtils (Status bar) -

extension UIUtils {

    static func setStatusBarBackgroundColor(_ color: UIColor) {
        guard let statusBar = (UIApplication.shared.value(forKey: "statusBarWindow") as AnyObject).value(forKey: "statusBar") as? UIView else {
            return
        }

        statusBar.backgroundColor = color
    }

}
