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

typealias FlickrOAuthViewControllerSuccessCompletionHandler = (_ URL: URL) -> Void
typealias FlickrOAuthViewControllerFailureCompletionHandler = (_ error: Error) -> Void

// MARK: - FlickrOAuthViewController: UIViewController

class FlickrOAuthViewController: UIViewController {
    
    // MARK: Properties
    
    fileprivate var webView = UIWebView()
    
    fileprivate var authorizationURLString: String!
    fileprivate var callbackURLString: String!

    fileprivate var authorizationURL: URL {
        get {
            return URL(string: authorizationURLString)!
        }
    }
    fileprivate var callbackURL: URL {
        get {
            return URL(string: callbackURLString)!
        }
    }
    
    fileprivate var successBlock: FlickrOAuthViewControllerSuccessCompletionHandler!
    fileprivate var failureBlock: FlickrOAuthViewControllerFailureCompletionHandler!
    
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
    
    func authorize(success: @escaping FlickrOAuthViewControllerSuccessCompletionHandler, failure: @escaping FlickrOAuthViewControllerFailureCompletionHandler) {
        successBlock = success
        failureBlock = failure
        
        let rootViewController = UIUtils.getRootViewController()!
        let navigationController = UINavigationController(rootViewController: self)
        rootViewController.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: Actions
    
    func dismiss() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: Private
    
    fileprivate func configure() {
        title = "Flickr Auth"
        
        webView.delegate = self
        webView.frame = view.bounds
        webView.backgroundColor = .white
        webView.scalesPageToFit = true
        webView.autoresizingMask = UIViewAutoresizing(arrayLiteral: .flexibleWidth, .flexibleHeight)
        view.addSubview(webView)
        
        let request = URLRequest(url: authorizationURL)
        webView.loadRequest(request)

        let doneBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(((FlickrOAuthViewController.dismiss) as (FlickrOAuthViewController) -> (Void) -> Void))
        )
        navigationItem.rightBarButtonItem = doneBarButtonItem
    }
    
}

// MARK: - FlickrOAuthViewController: UIWebViewDelegate -

extension FlickrOAuthViewController: UIWebViewDelegate {
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {
            return false
        }

        if url.host == callbackURL.host {
            successBlock(URL: request.url!)
            dismiss()
            return false
        }

        if url.scheme != "http" && url.scheme != "https" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.openURL(url)
                return false
            }
        }

        return true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        UIUtils.showNetworkActivityIndicator()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        UIUtils.hideNetworkActivityIndicator()
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        // Ignore NSURLErrorDomain error -999.
        if (error._code == NSURLErrorCancelled) {
            return
        }

        // Ignore "Fame Load Interrupted" errors. Seen after app store links.
        if (error._code == 102 && error._domain == "WebKitErrorDomain") {
            return
        }
        
        failureBlock(error: error)
    }
    
}
