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

// MARK: ImageTaggerViewController: UIViewController, Alertable

class ImageTaggerViewController: UIViewController, Alertable {
    
    // MARK: - Properties
    
    var taggingImage: UIImage!
    
    private let imaggaApiClient = ImaggaApiClient.sharedInstance
    private var generatedTags: [ImaggaTag]?
    
    // MARK: - Outlets
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var processOnImageButton: UIButton!
    
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
    
    @IBAction func processOnImageButtonDidPressed(sender: AnyObject) {
        if generatedTags != nil {
            showTags()
        } else {
            imaggaApiClient.taggingImage(taggingImage, successBlock: { [unowned self] tags in
                self.generatedTags = tags
                self.showTags()
            }) { [unowned self] error in
                let alertController = self.alert("Error", message: error.localizedDescription, handler: nil)
                self.presentViewController(alertController, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showTags() {
        let tagListViewController = TagListViewController()
        tagListViewController.title = "Generated Tags"
        tagListViewController.tags = generatedTags!
        navigationController?.pushViewController(tagListViewController, animated: true)
    }
    
}

// MARK: - ImageTaggerViewController (UI Functions) -

extension ImageTaggerViewController {
    
    private func configureUI() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        imageView.image = taggingImage
    }
    
}
