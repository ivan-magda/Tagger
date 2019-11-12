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

import UIKit.UIImage
import CoreData

// MARK: - ImageTaggerViewController: UIViewController, Alertable

final class ImageTaggerViewController: UIViewController, Alertable {

    // MARK: - Types

    private enum State {
        case idle
        case fetching
        case fetched
        case error
    }
    
    // MARK: - Instance Variables

    /// Image for analysis and discovery.
    /// Hashtags will be generated using this image.
    var taggingImage: UIImage!

    var persistenceCentral: PersistenceCentral!
    
    private let imaggaApiClient = ImaggaApiClient.shared

    /// Generated hashtags from the `taggingImage`.
    private var generatedTags: [ImaggaTag]?

    /// Category associated with the `generatedTags`.
    private var createdCategory: Category?

    private lazy var temporaryContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistenceCentral.coreDataStackManager.persistentStoreCoordinator

        return context
    }()

    private var state: State = .idle {
        didSet {
            switch self.state {
            case .idle, .error:
                UIUtils.hideNetworkActivityIndicator()
                self.activityIndicator.stopAnimating()
                self.imageView.image = self.taggingImage

                self.generateBarButtonItem.isEnabled = true
                self.resultsBarButtonItem.isEnabled = false
                self.saveResultsBarButtonItem.isEnabled = false
            case .fetching:
                UIUtils.showNetworkActivityIndicator()
                self.activityIndicator.startAnimating()

                self.resultsBarButtonItem.isEnabled = false
                self.generateBarButtonItem.isEnabled = false
                self.saveResultsBarButtonItem.isEnabled = false
            case .fetched:
                UIUtils.hideNetworkActivityIndicator()
                self.activityIndicator.stopAnimating()

                let isEnabled = generatedTags != nil && generatedTags!.count > 0
                self.resultsBarButtonItem.isEnabled = isEnabled
                self.saveResultsBarButtonItem.isEnabled = isEnabled
                self.generateBarButtonItem.isEnabled = false
            }
        }
    }
    
    // MARK: IBOutlets

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet var generateBarButtonItem: UIBarButtonItem!
    @IBOutlet var resultsBarButtonItem: UIBarButtonItem!
    @IBOutlet var saveResultsBarButtonItem: UIBarButtonItem!
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        assert(self.taggingImage != nil && self.persistenceCentral != nil)

        self.configureUI()
    }
}

// MARK: - ImageTaggerViewController (Data) -

extension ImageTaggerViewController {
    private func handleGeneratedTags(_ tags: [ImaggaTag]) {
        self.generatedTags = tags
        self.state = .fetched

        let alert = UIAlertController(
            title: NSLocalizedString("Success", comment: "ImageTaggerViewController"),
            message: NSLocalizedString("Tags successfully generated. Do you want save or see them?", comment: ""),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "ImageTaggerViewController"), style: .cancel)
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Save", comment: "ImageTaggerViewController"),
                style: .default
            ) { [weak self]  _ in
                if let strongSelf = self {
                    strongSelf.saveResults(strongSelf)
                }
            }
        )
        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("See Results", comment: "ImageTaggerViewController"),
                style: .default
            ) { [weak self]  _ in
                if let strongSelf = self {
                    strongSelf.showResults(strongSelf)
                }
            }
        )

        self.present(alert, animated: true)
    }

    private func createCategory(with name: String) {
        let name = name.trimmingCharacters(in: .whitespaces)
        let manager = self.persistenceCentral.coreDataStackManager
        let context = manager.managedObjectContext

        let category = Category(name: name, context: context)
        ImaggaTag.map(on: self.generatedTags!, with: category, in: context)
        manager.saveContext()

        self.createdCategory = category

        self.saveResultsBarButtonItem.isEnabled = false
        self.showResults(self)
    }

}

// MARK: - ImageTaggerViewController (Actions) -

extension ImageTaggerViewController {
    @IBAction func cancelDidPressed(_ sender: AnyObject) {
        self.dismiss(animated: true)
    }

    @IBAction func generateTags(_ sender: AnyObject) {
        self.state = .fetching

        self.imaggaApiClient.taggingImage(
            self.taggingImage,
            success: { [weak self] tags in
                self?.handleGeneratedTags(tags)
            },
            failure: { [weak self] error in
                guard let strongSelf = self else {
                    return
                }

                strongSelf.generatedTags = nil
                strongSelf.state = .fetched

                let alert = strongSelf.alert(
                    NSLocalizedString("Error", comment: "ImageTaggerViewController"),
                    message: error.localizedDescription,
                    handler: nil
                )

                strongSelf.present(alert, animated: true, completion: nil)
            }
        )
    }

    @IBAction func showResults(_ sender: AnyObject) {
        let tagListViewController = TagListViewController(persistenceCentral: persistenceCentral)

        if let createdCategory = self.createdCategory {
            tagListViewController.category = createdCategory
        } else {
            tagListViewController.title = NSLocalizedString("Results", comment: "ImageTaggerViewController")
            tagListViewController.tags = ImaggaTag.map(on: self.generatedTags!, in: self.temporaryContext)
        }

        self.navigationController?.pushViewController(tagListViewController, animated: true)
    }

    @IBAction func saveResults(_ sender: AnyObject) {
        func showAlert() {
            let alert = self.alert(
                NSLocalizedString("Invalid category name", comment: "ImageTaggerViewController"),
                message: NSLocalizedString("Try again", comment: "ImageTaggerViewController"),
                handler: { [weak self] in
                    self?.saveResults($0)
                }
            )

            self.present(alert, animated: true, completion: nil)
        }

        var categoryNameTextField: UITextField?

        let alert = UIAlertController(
            title: NSLocalizedString("Create Category", comment: "ImageTaggerViewController"),
            message: NSLocalizedString("To save the tags, please enter the category name.", comment: "ImageTaggerViewController"),
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: NSLocalizedString("Cancel", comment: "ImageTaggerViewController"), style: .cancel)
        )

        alert.addAction(
            UIAlertAction(
                title: NSLocalizedString("Save", comment: "ImageTaggerViewController"),
                style: .default,
                handler: { [weak self] _ in
                    guard let strongSelf = self,
                          let name = categoryNameTextField?.text,
                          !name.isEmpty else {
                        return showAlert()
                    }

                    strongSelf.createCategory(with: name)
                }
            )
        )

        alert.addTextField { textField in
            categoryNameTextField = textField
            categoryNameTextField?.placeholder = NSLocalizedString(
                "Enter category name",
                comment: "ImageTaggerViewController"
            )
        }

        self.present(alert, animated: true)
    }
}

// MARK: - ImageTaggerViewController (UI) -

extension ImageTaggerViewController {
    private func configureUI() {
        self.state = .idle

        self.navigationController?.view.backgroundColor = .white
        self.navigationItem.backBarButtonItem = UIBarButtonItem(
            title: NSLocalizedString("Back", comment: "ImageTaggerViewController"),
            style: .plain,
            target: nil,
            action: nil
        )
    }
}
