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

// MARK: Constants

private let modelName = "Tagger"
private let SQLiteFileName = "\(modelName).sqlite"

// MARK: - CoreDataStackManager

final class CoreDataStackManager {
    
    // MARK: Instance Variables
    
    static let shared = CoreDataStackManager()
    
    // MARK: Core Data Stack

    /// The managed object model for the application. This property is not optional.
    /// It is a fatal error for the application not to be able to find and load its model.
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")!

        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    /// The persistent store coordinator for the application.
    /// This implementation creates and returns a coordinator, having added
    /// the store for the application to it. This property is optional since
    /// there are legitimate error conditions that could cause the creation
    /// of the store to fail. Create the coordinator and store.
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = PathUtils.applicationDocumentsDirectory().appendingPathComponent(SQLiteFileName)

        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                               configurationName: nil,
                                               at: url,
                                               options: nil)
        } catch {
            var dict = [String: Any]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
            dict[NSUnderlyingErrorKey] = error

            let wrappedError = NSError(
                domain: BaseErrorDomain,
                code: 9999,
                userInfo: dict
            )
            print("Unresolved error \(wrappedError), \(wrappedError.userInfo)")

            abort()
        }
        
        return coordinator
    }()

    /// Returns the managed object context for the application
    /// (which is already bound to the persistent store coordinator for the application.)
    /// This property is optional since there are legitimate error conditions
    /// that could cause the creation of the context to fail.
    lazy var managedObjectContext: NSManagedObjectContext = {
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator

        return managedObjectContext
    }()
    
}

// MARK: - CoreDataStackManager (Save) -

extension CoreDataStackManager {

    func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch let error as NSError {
                print("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }

}
