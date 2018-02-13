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
import CoreData

// MARK: CategoryImage: NSManagedObject

class CategoryImage: NSManagedObject {
    
    // MARK: Types
    
    enum Key: String {
        case Data = "data"
        case Category = "category"
    }
    
    // MARK: Properties
    
    var image: UIImage? {
        get {
            guard data != nil else { return nil }
            return _image
        }
    }
    
    fileprivate lazy var _image: UIImage? = {
        return UIImage(data: self.data! as Data)
    }()
    
    // MARK: Init

    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    convenience init(data: Data, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entity(forEntityName: CategoryImage.type, in: context)!
        self.init(entity: entity, insertInto: context)
        self.data = data
    }
    
    convenience init(image: UIImage, context: NSManagedObjectContext) {
        let data = UIImageJPEGRepresentation(image, 1.0)!
        self.init(data: data, context: context)
    }
    
}
