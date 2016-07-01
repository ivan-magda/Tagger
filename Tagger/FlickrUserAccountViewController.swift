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

private enum UIState {
    case Default
    case Network
}

// MARK: - FlickrUserAccountViewController: UIViewController, Alertable

class FlickrUserAccountViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var imageView: ProfileImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: Properties
    
    var flickr: MIFlickr!
    
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.hidesWhenStopped = true
        return activityIndicator
    }()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
        setUIState(.Default)
    }
    
    // MARK: Actions
    
    @IBAction func actionButtonDidPressed(sender: AnyObject) {
        setUIState(.Network)
        if flickr.currentUser == nil {
            signIn()
        } else {
            logOut()
        }
    }
    
    private func logOut() {
        flickr.logOutCurrentUser()
        setUIState(.Default)
        configureUI()
    }
    
    private func signIn() {
        flickr.OAuth.authorizeWithPermission(.Write) { result in
            switch result {
            case .Success(_, _, let user):
                self.flickr.currentUser = user
                self.configureUI()
                self.setUIState(.Default)
            case .Failure(let error):
                self.showError(error)
                self.setUIState(.Default)
            }
        }
    }
    
}

// MARK: - FlickrUserAccountViewController (UI Functions) -

extension FlickrUserAccountViewController {
    
    private func configureUI() {
        if let user = flickr.currentUser {
            mainLabel.text = user.fullname
            detailLabel.text = user.username
            actionButton.setTitle("Log Out", forState: .Normal)
            
            setUIState(.Network)
            flickr.api.getProfilePictureWithNSID(user.userID, success: {
                self.imageView.image = $0
                self.setUIState(.Default)
                }, failure: {
                    self.showError($0)
                    self.setUIState(.Default)
            })
        } else {
            mainLabel.text = "You are not logged in"
            detailLabel.text = "If you want to interact with your account, then sign in"
            actionButton.setTitle("Sign In", forState: .Normal)
        }
        
        let spinner = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = spinner
    }
    
    private func showError(error: NSError) {
        let alertController = alert("Error", message: error.localizedDescription, handler: nil)
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    private func setUIState(state: UIState) {
        switch state {
        case .Default:
            UIUtils.hideNetworkActivityIndicator()
            activityIndicator.stopAnimating()
            actionButton.enabled = true
            actionButton.backgroundColor = UIColor(red: 0.0, green: 99.0 / 255.0, blue: 220.0 / 255.0, alpha: 1.0)
        case .Network:
            UIUtils.showNetworkActivityIndicator()
            activityIndicator.startAnimating()
            actionButton.enabled = false
            actionButton.backgroundColor = .lightGrayColor()
        }
    }
    
}
