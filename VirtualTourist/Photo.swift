//
//  Photo.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/9/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Photo: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    @NSManaged var title: String?
    @NSManaged var imageUrl: String?
    @NSManaged var id: String?
    @NSManaged var pin: Pin?
    
    var dataDir: NSURL?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary:[String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary["title"] as? String
        imageUrl = dictionary["url_q"] as? String
        id = dictionary["id"] as? String
    }
    
    func savePathUrl(photoid: String!) -> NSURL?
    {
        dataDir = Utilities.fileOperations.CACHE_DIR
        
        // Check for data directory
        if !Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath((dataDir?.path)!) {
            print("Create subdirectory")
            do {
                try Utilities.fileOperations.FILE_MANAGER.createDirectoryAtURL(dataDir!, withIntermediateDirectories: true, attributes: nil)
            }
            catch {
                print("Error creating directory")
            }
        }
        
        let nsurl = NSURL(string: imageUrl!)
        let data = NSData(contentsOfURL: nsurl!)
        let path = dataDir?.URLByAppendingPathComponent(photoid)
        
        data!.writeToURL(path!, atomically: true)
        
        return path
    }
    
    override func prepareForDeletion() {
        let _ = Utilities.imageCleanup(id!)
    }
}
