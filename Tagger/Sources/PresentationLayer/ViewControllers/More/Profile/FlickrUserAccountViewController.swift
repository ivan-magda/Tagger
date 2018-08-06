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

// MARK: - FlickrUserAccountViewController: UIViewController, Alertable

final class FlickrUserAccountViewController: UIViewController, Alertable {

    private enum State {
        case guest
        case fetching
        case signedIn
    }

    // MARK: IBOutlets
    
    @IBOutlet var imageView: ProfileImageView!
    @IBOutlet var mainLabel: UILabel!
    @IBOutlet var detailLabel: UILabel!
    @IBOutlet var actionButton: UIButton!
    
    // MARK: Instance variables
    
    var flickr: IMFlickr!
    
    private let activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.hidesWhenStopped = true

        return activityIndicator
    }()

    private var state: State = .guest {
        didSet {
            var title: String

            switch state {
            case .guest:
                UIUtils.hideNetworkActivityIndicator()
                activityIndicator.stopAnimating()
                title = NSLocalizedString("Sign in", comment: "")
            case .signedIn:
                UIUtils.hideNetworkActivityIndicator()
                activityIndicator.stopAnimating()
                title = NSLocalizedString("Sign Out", comment: "")
            case .fetching:
                UIUtils.showNetworkActivityIndicator()
                activityIndicator.startAnimating()
                title = NSLocalizedString("Signing in...", comment: "")
            }

            actionButton.isEnabled = state == .guest || state == .signedIn
            actionButton.setTitle(title, for: .normal)
        }
    }
    
    // MARK: UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(flickr != nil)

        navigationController?.view.backgroundColor = .white
        hideLargeTitle()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
    }
    
}

// MARK: - FlickrUserAccountViewController (Actions) -

extension FlickrUserAccountViewController {

    @IBAction func actionButtonDidPressed(_ sender: AnyObject) {
        if flickr.currentUser == nil {
            signIn()
        } else {
            logOut()
        }
    }

    private func logOut() {
        state = .guest
        flickr.logOut()
        configureUI()
    }

    private func signIn() {
        state = .fetching
        flickr.OAuth.auth(with: .write) { [weak self] result in
            guard let strongSelf = self else { return }

            switch result {
            case .success(_, _, let user):
                strongSelf.flickr.currentUser = user
                strongSelf.configureUI()
                strongSelf.state = .signedIn
            case .failure(let error):
                strongSelf.showError(error)
                strongSelf.state = .guest
            }
        }
    }

}

// MARK: - FlickrUserAccountViewController (UI Functions) -

extension FlickrUserAccountViewController {
    
    private func configureUI() {
        actionButton.layer.cornerRadius = 10
        actionButton.clipsToBounds = true

        let spinner = UIBarButtonItem(customView: activityIndicator)
        navigationItem.rightBarButtonItem = spinner

        if let user = flickr.currentUser {
            state = .signedIn
            mainLabel.text = user.fullname
            detailLabel.text = user.username

            activityIndicator.startAnimating()

            flickr.api.getProfilePhotoWithNSID(user.userID, success: { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.imageView.image = $0
            }, failure: { [weak self] in
                self?.activityIndicator.stopAnimating()
                self?.showError($0)
            })
        } else {
            state = .guest
            imageView.image = UIImage(named: "flickr_rocket_logo")!
            mainLabel.text = "You are not signed in"
            detailLabel.text = "If you want to interact with your account, please sign in."
        }
    }
    
    private func showError(_ error: Error) {
        let alertController = alert("Error", message: error.localizedDescription, handler: nil)
        present(alertController, animated: true, completion: nil)
    }
    
}
