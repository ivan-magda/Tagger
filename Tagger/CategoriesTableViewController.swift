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

// MARK: Constants

private let kReuseIdentifier = "CategoryCell"

// MARK: - Types

private enum SegueIdentifier: String {
    case EditCategory
}

// MARK: - CategoriesTableViewController: UITableViewController

class CategoriesTableViewController: UITableViewController {
    
    // MARK: Properties
    
    var persistenceCentral: PersistenceCentral!

    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(persistenceCentral != nil)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == SegueIdentifier.EditCategory.rawValue {
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ManageCategoryTableViewController
            controller.persistenceCentral = persistenceCentral
            
            let indexPath = tableView.indexPathForSelectedRow!
            let category = persistenceCentral.categories[indexPath.row]
            controller.category = category
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return persistenceCentral.categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: kReuseIdentifier)!
        
        let category = persistenceCentral.categories[indexPath.row]
        cell.textLabel?.text = category.name
        
        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteCategoryAtIndexPath(indexPath)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    // MARK: Public
    
    func reloadData() {
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
    
    // MARK: Private
    
    fileprivate func setup() {
        navigationItem.rightBarButtonItem = editButtonItem
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(reloadData), name: NSNotification.Name(rawValue: kManageCategoryTableViewControllerDidDoneOnCategoryNotification), object: nil)
    }
    
    fileprivate func deleteCategoryAtIndexPath(_ indexPath: IndexPath) {
        let category = persistenceCentral.categories[indexPath.row]
        persistenceCentral.deleteCategory(category)
    }

}
