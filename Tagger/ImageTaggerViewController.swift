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

// MARK: Types

private enum UIState {
    case `default`
    case networking
    case doneWithNetworking
}

// MARK: - ImageTaggerViewController: UIViewController, Alertable

class ImageTaggerViewController: UIViewController, Alertable {
    
    // MARK: - Properties
    
    var taggingImage: UIImage!
    var persistenceCentral: PersistenceCentral!
    
    fileprivate let imaggaApiClient = ImaggaApiClient.sharedInstance
    
    fileprivate var generatedTags: [ImaggaTag]?
    fileprivate var createdCategory: Category?
    fileprivate lazy var temporaryContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.persistenceCentral.coreDataStackManager.persistentStoreCoordinator
        return context
    }()
    
    // MARK: Outlets
    
    @IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var generateBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var resultsBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveResultsBarButtonItem: UIBarButtonItem!
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(taggingImage != nil && persistenceCentral != nil)
        configureUI()
    }
    
    // MARK: - Actions
    
    @IBAction func cancelDidPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func generateTags(_ sender: AnyObject) {
        setUIState(.networking)
        imaggaApiClient.taggingImage(taggingImage, success: { [weak self] tags in
            self?.processOnGeneratedTags(tags)
        }) { [weak self] error in
            self?.generatedTags = nil
            self?.setUIState(.doneWithNetworking)
            let alert = self?.alert("Error", message: error.localizedDescription, handler: nil)
            self?.present(alert!, animated: true, completion: nil)
        }
    }
    
    @IBAction func showResults(_ sender: AnyObject) {
        let tagListViewController = TagListViewController(persistenceCentral: persistenceCentral)
        
        if let createdCategory = createdCategory {
            tagListViewController.parentCategory = createdCategory
        } else {
            tagListViewController.title = "Results"
            tagListViewController.tags = ImaggaTag.mapImaggaTags(generatedTags!,
                                                                 toTagsInContext: temporaryContext)
        }
        navigationController?.pushViewController(tagListViewController, animated: true)
    }
    
    @IBAction func saveResults(_ sender: AnyObject) {
        func showInvalidNameAlert() {
            let alert = self.alert("Invalid category name", message: "Try again", handler: { [unowned self] in
                self.saveResults($0)
            })
            present(alert, animated: true, completion: nil)
        }
        
        var categoryNameTextField: UITextField?
        
        let alert = UIAlertController(title: "Create Category", message: "To save the tags, please enter the category name.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [unowned self] _ in
            guard let name = categoryNameTextField?.text, !name.isEmpty else {
                showInvalidNameAlert()
                return
            }
            self.createCategoryWithName(name)
        }))
        alert.addTextField { textField in
            categoryNameTextField = textField
            categoryNameTextField?.placeholder = "Enter category name"
        }
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Private
    
    fileprivate func processOnGeneratedTags(_ tags: [ImaggaTag]) {
        generatedTags = tags
        setUIState(.doneWithNetworking)
        
        let alert = UIAlertController(title: "Success", message: "Tags successfully generated. Do you want save or see them?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Save", style: .default) { [unowned self]  _ in
            self.saveResults(self)
        })
        alert.addAction(UIAlertAction(title: "See Results", style: .default) { [unowned self]  _ in
            self.showResults(self)
        })
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func createCategoryWithName(_ name: String) {
        let name = name.trimmingCharacters(in: .whitespaces)
        let manager = persistenceCentral.coreDataStackManager
        let context = manager.managedObjectContext
        
        let category = Category(name: name, context: context)
        ImaggaTag.mapImaggaTags(generatedTags!, withParentCategory: category, toTagsInContext: context)
        manager.saveContext()
        
        createdCategory = category
        
        saveResultsBarButtonItem.isEnabled = false
        showResults(self)
    }
    
}

// MARK: - ImageTaggerViewController (UI Functions) -

extension ImageTaggerViewController {
    
    fileprivate func configureUI() {
        setUIState(.default)
        navigationController?.view.backgroundColor = .white
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    }
    
    fileprivate func setUIState(_ state: UIState) {
        func updateResultsButtonState() {
            let enabled = generatedTags != nil && generatedTags!.count > 0
            resultsBarButtonItem.isEnabled = enabled
            saveResultsBarButtonItem.isEnabled = enabled
        }
        
        switch state {
        case .default:
            imageView.image = taggingImage
            resultsBarButtonItem.isEnabled = false
            saveResultsBarButtonItem.isEnabled = false
        case .networking:
            UIUtils.showNetworkActivityIndicator()
            activityIndicator.startAnimating()
            resultsBarButtonItem.isEnabled = false
            generateBarButtonItem.isEnabled = false
            saveResultsBarButtonItem.isEnabled = false
        case .doneWithNetworking:
            UIUtils.hideNetworkActivityIndicator()
            activityIndicator.stopAnimating()
            generateBarButtonItem.isEnabled = true
            updateResultsButtonState()
        }
    }
    
}
