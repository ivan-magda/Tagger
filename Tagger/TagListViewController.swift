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

private let kTableViewCellReuseIdentifier = "TagTableViewCell"

// MARK: - TagListViewController: UIViewController, Alertable

class TagListViewController: UIViewController, Alertable {
    
    // MARK: Outlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: Properties
    
    static let nibName = "TagListViewController"
    
    var tags = [Tag]() {
        didSet {
            guard tableView != nil else { return }
            reloadData()
        }
    }
    
    // MARK: Init
    
    convenience init() {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: kTableViewCellReuseIdentifier)
    }
    
    // MARK: - Private
    
    private func reloadData() {
        guard tableView.numberOfSections == 1 else {
            tableView.reloadData()
            return
        }
        tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
    }
    
}

// MARK: - TagListViewController: UITableViewDataSource -

extension TagListViewController: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(kTableViewCellReuseIdentifier)!
        configureCell(cell, withTag: tags[indexPath.row])
        return cell
    }
    
    // MARK: Helpers
    
    private func configureCell(cell: UITableViewCell, withTag tag: Tag) {
        cell.textLabel?.text = tag.name
    }
    
}

// MARK: - TagListViewController: UITableViewDelegate -

extension TagListViewController: UITableViewDelegate {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
}

