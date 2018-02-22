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

private let tableViewCellReuseIdentifier = "TagTableViewCell"

// MARK: - TagListViewController: UIViewController, Alertable -

class TagListViewController: UIViewController, Alertable {
    
    // MARK: IBOutlets
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var toolbar: UIToolbar!
    @IBOutlet var copyAllBarButtonItem: UIBarButtonItem!
    @IBOutlet var copyToClipboardBarButtonItem: UIBarButtonItem!
    @IBOutlet var messageBarButtonItem: UIBarButtonItem!
    
    // MARK: Instance variables
    
    var persistenceCentral: PersistenceCentral!

    // Tags to be displayed will be setted with the following steps:
    // If `category` exist -> category.tags.
    // Otherwise `tags` with empty state.
    /// Category of the tags.
    var category: Category?

    /// Tags to be displayed.
    var tags = [Tag]() {
        didSet {
            guard tableView != nil else { return }
            reloadData()
        }
    }

    /// UIAlertController with actionSheet style.
    /// Use it for presenting actions.
    let actionSheet = UIAlertController(title: nil,
                                        message: nil,
                                        preferredStyle: .actionSheet)

    static let nibName = "TagListViewController"

    private var selectedIndexes = Set<Int>()
    
    private lazy var tagsTextView: HashtagsTextView = {
        let textView = HashtagsTextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.font = UIFont.systemFont(ofSize: 19.0)
        textView.isHidden = true
        textView.alpha = 0.0

        return textView
    }()
    
    // MARK: Init
    
    convenience init() {
        self.init(nibName: TagListViewController.nibName, bundle: nil)
    }
    
    convenience init(persistenceCentral: PersistenceCentral) {
        self.init()
        self.persistenceCentral = persistenceCentral
    }
    
    // MARK: - UIViewController lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        assert(persistenceCentral != nil, "persistenceCentral should must be initialized.")
        setup()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setTabBarHidden(false)
    }
    
    // MARK: - Private

    private func setup() {
        if let category = category {
            tags = category.tags
        }

        setupUI()
    }

    private func reloadData() {
        tagsTextView.updateOnNew(
            tags.enumerated().flatMap { selectedIndexes.contains($0) ? $1.name : nil }
        )

        tableView.reloadSections(
            IndexSet(0...max(tableView.numberOfSections-1, 0)),
            with: .automatic
        )
    }
    
}

// MARK: - TagListViewController (Actions) -

extension TagListViewController {

    @objc private func onMore() {
        present(actionSheet, animated: true, completion: nil)
    }

    @IBAction func onSelectAll(_ sender: AnyObject) {
        let selectedCount = selectedIndexes.count
        selectedIndexes.removeAll()

        if selectedCount != tags.count {
            for i in 0..<tags.count {
                selectedIndexes.insert(i)
            }
        }

        reloadData()
        updateUI()
    }

    @IBAction func onCopyToClipboard(_ sender: AnyObject) {
        PasteboardUtils.copyString(tagsTextView.text)

        let alert = UIAlertController(
            title: "Copied",
            message: "Now paste the tags into your Instagram/Flickr picture comments or caption",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if URLSchemesUtils.canOpenInstagram() {
            alert.addAction(
                UIAlertAction(
                    title: "Instagram",
                    style: .default,
                    handler: { _ in URLSchemesUtils.openInstagram() }
                )
            )
        }

        if URLSchemesUtils.canOpenFlickr() {
            alert.addAction(
                UIAlertAction(
                    title: "Flickr",
                    style: .default,
                    handler: { _ in URLSchemesUtils.openFlickr() }
                )
            )
        }

        present(alert, animated: true, completion: nil)
    }

}

// MARK: - TagListViewController (UI Functions) -

extension TagListViewController {
    
    private func setupUI() {
        setTabBarHidden(true)
        
        if let parentCategory = category {
            title = parentCategory.name.capitalized
        }
        
        // Configure table view.
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self,
                           forCellReuseIdentifier: tableViewCellReuseIdentifier)
        
        // Configure text view:
        // Add as a subview to a root view and add constraints.
        view.insertSubview(tagsTextView, belowSubview: toolbar)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topGuide]-0-[textView]", options: NSLayoutFormatOptions(), metrics: nil, views: ["topGuide": topLayoutGuide, "textView": tagsTextView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[textView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["textView": tagsTextView]))
        view.addConstraint(NSLayoutConstraint(item: tagsTextView, attribute: .bottom, relatedBy: .equal, toItem: toolbar, attribute: .top, multiplier: 1.0, constant: 0.0))
        
        // Create more bar button and present action sheet with actions below on click.
        let moreBarButtonItem = UIBarButtonItem(image: UIImage(named: "more-tab-bar"),
                                                style: .plain,
                                                target: self,
                                                action: #selector(onMore))
        navigationItem.rightBarButtonItem = moreBarButtonItem
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Table View", style: .default, handler: { [weak self] action in
            guard self?.tagsTextView.isHidden == false else { return }
            self?.tableView.isHidden = false
            self?.tagsTextView.setIsHidden(true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Hashtags View", style: .default, handler: { [weak self] action in
            guard self?.tagsTextView.isHidden == true else { return }
            self?.tableView.isHidden = true
            self?.tagsTextView.setIsHidden(false)
        }))
        
        messageBarButtonItem.setTitleTextAttributes(
            [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 14.0)],
            for: UIControlState()
        )
        setUIState(.default)
    }
    
    func setUIState(_ state: TagListViewControllerUIState) {
        func setItemsEnabled(_ enabled: Bool) {
            navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = enabled }
            toolbar.items?.forEach { $0.isEnabled = enabled }
            if enabled { messageBarButtonItem.isEnabled = false }
        }
        
        UIUtils.hideNetworkActivityIndicator()
        
        switch state {
        case .default:
            setItemsEnabled(tags.count > 0)
            updateUI()
        case .downloading:
            UIUtils.showNetworkActivityIndicator()
            setItemsEnabled(false)
            messageBarButtonItem.title = "Updating..."
        case .successDoneWithDownloading:
            setItemsEnabled(tags.count > 0)
            updateUI()
        case .failureDoneWithDownloading(let error):
            setItemsEnabled(false)
            messageBarButtonItem.title = error.localizedDescription 
        }
    }
    
    private func updateUI() {
        let selectedCount = selectedIndexes.count
        
        guard tags.count > 0 else {
            messageBarButtonItem.title = "Nothing was returned"
            return
        }
        messageBarButtonItem.title = selectedCount == tags.count
            ? "All Selected (\(selectedCount))" : "\(selectedCount) Selected"
        
        copyToClipboardBarButtonItem.isEnabled = selectedIndexes.count > 0
    }
    
}

// MARK: - TagListViewController: UITableViewDataSource -

extension TagListViewController: UITableViewDataSource {
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: tableViewCellReuseIdentifier)!
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.textLabel?.text = tags[indexPath.row].name
        cell.accessoryType = selectedIndexes.contains(indexPath.row) ? .checkmark : .none
    }
    
}

// MARK: - TagListViewController: UITableViewDelegate -

extension TagListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if selectedIndexes.contains(indexPath.row) {
            selectedIndexes.remove(indexPath.row)
        } else {
            selectedIndexes.insert(indexPath.row)
        }
        
        reloadData()
        updateUI()
    }
    
}
