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

let kManageCategoryTableViewControllerDidDoneOnCategoryNotification = "ManageCategoryTableViewControllerDidDoneOnCategory"

// MARK: ManageCategoryTableViewController: UITableViewController, Alertable

class ManageCategoryTableViewController: UITableViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var doneBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var textField: UITextField!
    
    // MARK: Properties
    
    var persistenceCentral: PersistenceCentral!
    var category: Category?
    
    fileprivate var name = String()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(persistenceCentral != nil)
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textField.resignFirstResponder()
    }
    
    // MARK: Actions
    
    @IBAction func cancelDidPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneDidPressed(_ sender: AnyObject) {
        textField.resignFirstResponder()
        
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if category != nil {
            editCategory()
        } else {
            createCategory()
        }
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: kManageCategoryTableViewControllerDidDoneOnCategoryNotification), object: nil)
    }
    
    // MARK: Private
    
    fileprivate func setup() {
        configureUI()
        textField.delegate = self
    }
    
    fileprivate func shouldDoneOnCategory() -> Bool {
        guard let category = category else {
            return true
        }
        return name != category.name
    }
    
    fileprivate func createCategory() {
        persistenceCentral.saveCategory(for: name)
        
        let alert = self.alert("Success", message: "Category created") { _ in
            self.dismiss(animated: true, completion: nil)
        }
        present(alert, animated: true, completion: nil)
    }
    
    fileprivate func editCategory() {
        let manager = persistenceCentral.coreDataStackManager
        
        category!.name = name
        if let image = category!.image {
            manager.managedObjectContext.delete(image)
        }
        manager.saveContext()
        
        let alert = self.alert("Success", message: "Category edited", handler: { _ in
            self.dismiss(animated: true, completion: nil)
        })
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK: - ManageCategoryTableViewController (UI Functions) -

extension ManageCategoryTableViewController {
    
    fileprivate func configureUI() {
        if let category = category {
            title = "Edit Category"
            textField.text = category.name
            name = category.name
        } else {
            title = "Add Category"
        }
        updateDoneButtonEnabledState()
    }
    
    fileprivate func updateDoneButtonEnabledState() {
        doneBarButtonItem.isEnabled = !name.isEmpty && shouldDoneOnCategory()
    }
    
}

// MARK: - ManageCategoryTableViewController: UITextFieldDelegate -

extension ManageCategoryTableViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {

        name = textField.text ?? ""
        name = (name as NSString).replacingCharacters(in: range, with: string)

        updateDoneButtonEnabledState()

        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        name = textField.text ?? ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if shouldDoneOnCategory() {
            doneDidPressed(textField)
            return true
        }
        return false
    }
    
}
