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

import Foundation
import CoreData
import UIKit.UIImage

// MARK: Constants

let persistenceCentralDidChangeContentNotification = "PersistenceCentralDidChangeContent"
private let seedInitialDataKey = "initialDataSeeded"

// MARK: - PersistenceCentral: NSObject

final class PersistenceCentral: NSObject {
    
    // MARK: Instance Variables
    
    static let shared = PersistenceCentral()
    let coreDataStackManager = CoreDataStackManager.shared
    
    private (set) var trendingCategories: [Category]!
    private (set) var categories: [Category]!
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Category> = {
        let request = NSFetchRequest<Category>(entityName: Category.type)
        request.sortDescriptors = [
            NSSortDescriptor(key: Category.Key.trending.rawValue, ascending: true),
            NSSortDescriptor(key: Category.Key.name.rawValue, ascending: true,
                             selector: #selector(NSString.caseInsensitiveCompare(_:)))
        ]
        request.returnsObjectsAsFaults = false
        
        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: self.coreDataStackManager.managedObjectContext,
            sectionNameKeyPath: Category.Key.trending.rawValue,
            cacheName: nil
        )
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: Init
    
    private override init() {
        super.init()
        setup()
    }

}

// MARK: - PersistenceCentral (Category) -

extension PersistenceCentral {

    func deleteCategory(_ category: Category) {
        coreDataStackManager.managedObjectContext.delete(category)
        coreDataStackManager.saveContext()
    }

    func deleteCategories() {
        categories.forEach {
            coreDataStackManager.managedObjectContext.delete($0)
        }
        coreDataStackManager.saveContext()
    }

    func deleteTags(in category: Category) {
        category.deleteTags()
        coreDataStackManager.saveContext()
    }

    func saveCategory(for name: String) {
        let _ = Category(name: name,
                         context: coreDataStackManager.managedObjectContext)
        coreDataStackManager.saveContext()
    }

}

// MARK: - PersistenceCentral (CategoryImage) -

extension PersistenceCentral {

    func setImage(_ image: UIImage, to category: Category) {
        let categoryImage = CategoryImage(image: image,
                                          context: coreDataStackManager.managedObjectContext)
        category.image = categoryImage
        categoryImage.category = category

        coreDataStackManager.saveContext()
    }

    func deleteImages() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: CategoryImage.type)
        do {
            guard let results = try coreDataStackManager.managedObjectContext.fetch(request) as? [CategoryImage] else {
                return
            }

            results.forEach {
                self.coreDataStackManager.managedObjectContext.delete($0)
            }

            coreDataStackManager.saveContext()
        } catch let error as NSError {
            print("Failed to delete all images: \(error.localizedDescription)")
        }
    }

}



// MARK: - PersistenceCentral: NSFetchedResultsControllerDelegate -

extension PersistenceCentral: NSFetchedResultsControllerDelegate {
    
    // MARK: NSFetchedResultsControllerDelegate
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        updateCategories()
        PersistenceCentral.postDidChangeContentNotification()
    }
    
    // MARK: Private
    
    private func updateCategories() {
        func objectsForSection(_ section: Int) -> [Category] {
            return fetchedResultsController.sections?[section].objects as? [Category] ?? [Category]()
        }
        categories = objectsForSection(0)
        trendingCategories = objectsForSection(1)
    }
    
    private class func postDidChangeContentNotification() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.post(name: Notification.Name(rawValue: persistenceCentralDidChangeContentNotification), object: self)
    }
    
}

// MARK: - PersistenceCentral (Private Helpers) -

extension PersistenceCentral {

    private func setup() {
        seedData()
        _ = try! fetchedResultsController.performFetch()
        updateCategories()
    }

}

// MARK: - PersistenceCentral (Seed Data) -

extension PersistenceCentral {

    private func seedData() {
        let userDefaults = UserDefaults.standard

        guard userDefaults.bool(forKey: seedInitialDataKey) == false else {
            return
        }

        let context = coreDataStackManager.managedObjectContext

        let categories = [
            "sunset", "beach", "water", "sky", "dance", "red",
            "blue", "nature", "night", "vacation", "white", "green",
            "flowers", "portrait", "art", "light", "snow", "dog",
            "sun", "clouds", "cat", "park", "winter", "street",
            "landscape", "summer", "trees", "sea", "city", "yellow",
            "lake", "christmas", "family", "bridge", "people", "bird",
            "river", "pink", "house", "car", "food", "bw",
            "old", "macro", "new", "music", "garden", "orange",
            "me", "baby"
        ]
        categories.forEach { let _ = Category(name: $0, context: context) }

        let trending = ["now", "this week"]
        trending.forEach {
            let category = Category(name: $0, context: context)
            category.trending = true
        }

        coreDataStackManager.saveContext()
        UserDefaults.standard.set(true, forKey: seedInitialDataKey)
    }

}
