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
    case `default`
    case network
}

// MARK: - FlickrUserAccountViewController: UIViewController, Alertable

final class FlickrUserAccountViewController: UIViewController, Alertable {
    
    // MARK: IBOutlets
    
    @IBOutlet weak var imageView: ProfileImageView!
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
    
    // MARK: Instance variables
    
    var flickr: IMFlickr!
    
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        activityIndicator.hidesWhenStopped = true

        return activityIndicator
    }()
    
    // MARK: UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
        setUIState(.default)
    }
    
}

// MARK: - FlickrUserAccountViewController (Actions) -

extension FlickrUserAccountViewController {

    @IBAction func actionButtonDidPressed(_ sender: AnyObject) {
        setUIState(.network)

        if flickr.currentUser == nil {
            signIn()
        } else {
            logOut()
        }
    }

    private func logOut() {
        flickr.logOut()
        setUIState(.default)
        configureUI()
    }

    private func signIn() {
        flickr.OAuth.auth(with: .write) { [weak self] result in
            guard let strongSelf = self else { return }

            switch result {
            case .success(_, _, let user):
                strongSelf.flickr.currentUser = user
                strongSelf.configureUI()
                strongSelf.setUIState(.default)
            case .failure(let error):
                strongSelf.showError(error)
                strongSelf.setUIState(.default)
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
            actionButton.setTitle("Log Out", for: UIControlState())
            
            setUIState(.network)
            flickr.api.getProfilePhotoWithNSID(user.userID, success: {
                self.imageView.image = $0
                self.setUIState(.default)
                }, failure: {
                    self.showError($0)
                    self.setUIState(.default)
            })
        } else {
            imageView.image = UIImage(named: "flickr_rocket_logo")!
            mainLabel.text = "You are not logged in"
            detailLabel.text = "If you want to interact with your account, then sign in"
            actionButton.setTitle("Sign In", for: UIControlState())
        }
        
        let spinner = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = spinner
    }
    
    private func showError(_ error: Error) {
        let alertController = alert("Error", message: error.localizedDescription, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
    private func setUIState(_ state: UIState) {
        switch state {
        case .default:
            UIUtils.hideNetworkActivityIndicator()
            activityIndicator.stopAnimating()
            actionButton.isEnabled = true
            actionButton.backgroundColor = UIColor(red: 0.0, green: 99.0 / 255.0, blue: 220.0 / 255.0, alpha: 1.0)
        case .network:
            UIUtils.showNetworkActivityIndicator()
            activityIndicator.startAnimating()
            actionButton.isEnabled = false
            actionButton.backgroundColor = .lightGray
        }
    }
    
}
