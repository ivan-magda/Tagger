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

// MARK: Typealiases

typealias FlickrOAuthViewControllerSuccessCompletionHandler = (URL: NSURL) -> Void
typealias FlickrOAuthViewControllerFailureCompletionHandler = (error: NSError) -> Void

// MARK: - FlickrOAuthViewController: UIViewController

class FlickrOAuthViewController: UIViewController {
    
    // MARK: Properties
    
    private var webView = UIWebView()
    
    private var authorizationURLString: String!
    private var callbackURLString: String!

    private var authorizationURL: NSURL {
        get {
            return NSURL(string: authorizationURLString)!
        }
    }
    private var callbackURL: NSURL {
        get {
            return NSURL(string: callbackURLString)!
        }
    }
    
    private var successBlock: FlickrOAuthViewControllerSuccessCompletionHandler!
    private var failureBlock: FlickrOAuthViewControllerFailureCompletionHandler!
    
    // MARK: Init
    
    init(authorizationURL: String, callbackURL: String) {
        self.authorizationURLString = authorizationURL
        self.callbackURLString = callbackURL
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(nibName: nil, bundle: nil)
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    // MARK: Public
    
    func authorize(success success: FlickrOAuthViewControllerSuccessCompletionHandler, failure: FlickrOAuthViewControllerFailureCompletionHandler) {
        successBlock = success
        failureBlock = failure
        
        let rootViewController = UIUtils.getRootViewController()!
        let navigationController = UINavigationController(rootViewController: self)
        rootViewController.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    func dismiss() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: Private
    
    private func configure() {
        title = "Flickr Auth"
        
        webView.delegate = self
        webView.frame = view.bounds
        webView.backgroundColor = .whiteColor()
        webView.scalesPageToFit = true
        webView.autoresizingMask = UIViewAutoresizing(arrayLiteral: .FlexibleWidth, .FlexibleHeight)
        view.addSubview(webView)
        
        let request = NSURLRequest(URL: authorizationURL)
        webView.loadRequest(request)
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(dismiss))
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
}

// MARK: - FlickrOAuthViewController: UIWebViewDelegate -

extension FlickrOAuthViewController: UIWebViewDelegate {
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.URL else {
            return false
        }

        if url.host == callbackURL.host {
            successBlock(URL: request.URL!)
            dismiss()
            return false
        }

        if url.scheme != "http" && url.scheme != "https" {
            if UIApplication.sharedApplication().canOpenURL(url) {
                UIApplication.sharedApplication().openURL(url)
                return false
            }
        }

        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        UIUtils.showNetworkActivityIndicator()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        UIUtils.hideNetworkActivityIndicator()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        // Ignore NSURLErrorDomain error -999.
        if (error?.code == NSURLErrorCancelled) {
            return
        }

        // Ignore "Fame Load Interrupted" errors. Seen after app store links.
        if (error?.code == 102 && error?.domain == "WebKitErrorDomain") {
            return
        }

        guard let error = error else {
            let error = NSError(domain: "\(BaseErrorDomain).FlickrOAuthViewController",
                                code: 66,
                                userInfo: [NSLocalizedDescriptionKey : "Failed promts for a user authorization."]
            )
            failureBlock(error: error)
            return
        }
        
        failureBlock(error: error)
    }
    
}
