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

private enum SegueIdentifier: String {
    case showCategories
    case addCategory
    case flickrAccount
}

// MARK: - MoreInfoTableViewController: UITableViewController

final class MoreInfoTableViewController: UITableViewController {
    
    // MARK: Instance Variables
    
    var flickr: IMFlickr!
    var persistenceCentral: PersistenceCentral!

    // MARK: UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(flickr != nil && persistenceCentral != nil)
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }

        switch identifier {
        case SegueIdentifier.showCategories.rawValue:
            let controller = segue.destination as! CategoriesTableViewController
            controller.persistenceCentral = persistenceCentral
        case SegueIdentifier.addCategory.rawValue:
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! ManageCategoryTableViewController
            controller.persistenceCentral = persistenceCentral
        case SegueIdentifier.flickrAccount.rawValue:
            let controller = segue.destination as! FlickrUserAccountViewController
            controller.flickr = flickr
        default:
            fatalError("Receive unknow segue identifier")
        }
    }
    
    // MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
