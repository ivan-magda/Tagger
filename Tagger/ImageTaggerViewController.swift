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
    case Networking
    case DoneWithNetworking
}

// MARK: - ImageTaggerViewController: UIViewController, Alertable

class ImageTaggerViewController: UIViewController, Alertable {
    
    // MARK: - Properties
    
    var taggingImage: UIImage!
    
    private let imaggaApiClient = ImaggaApiClient.sharedInstance
    private var generatedTags: [ImaggaTag]?
    
    // MARK: - Outlets
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var generateBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var resultsBarButtonItem: UIBarButtonItem!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(taggingImage != nil)
        configureUI()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelDidPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func generateTags(sender: AnyObject) {
        setUIState(.Networking)
        imaggaApiClient.taggingImage(taggingImage, successBlock: { [unowned self] tags in
            self.generatedTags = tags
            self.setUIState(.DoneWithNetworking)
            self.showResults(self)
        }) { [unowned self] error in
            self.generatedTags = nil
            self.setUIState(.DoneWithNetworking)
            let alertController = self.alert("Error", message: error.localizedDescription, handler: nil)
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    @IBAction func showResults(sender: AnyObject) {
        let tagListViewController = TagListViewController()
        tagListViewController.title = "Results"
        tagListViewController.tags = generatedTags!.map { $0.tag }
        navigationController?.pushViewController(tagListViewController, animated: true)
    }
    
}

// MARK: - ImageTaggerViewController (UI Functions) -

extension ImageTaggerViewController {
    
    private func configureUI() {
        setUIState(.Default)
        navigationController?.view.backgroundColor = .whiteColor()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Plain, target: nil, action: nil)
    }
    
    private func setUIState(state: UIState) {
        func updateResultsButtonState() {
            resultsBarButtonItem.enabled = generatedTags != nil && generatedTags?.count > 0
        }
        
        switch state {
        case .Default:
            imageView.image = taggingImage
            resultsBarButtonItem.enabled = false
        case .Networking:
            UIUtils.showNetworkActivityIndicator()
            activityIndicator.startAnimating()
            resultsBarButtonItem.enabled = false
            generateBarButtonItem.enabled = false
        case .DoneWithNetworking:
            UIUtils.hideNetworkActivityIndicator()
            activityIndicator.stopAnimating()
            generateBarButtonItem.enabled = true
            updateResultsButtonState()
        }
    }
    
}
