//
//  Utilities.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 11/1/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit

class Utilities: NSObject {
    
    class func imageCleanup(id: String!) -> (Bool, String?)
    {
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(id)
        
        if Utilities.fileOperations.FILE_MANAGER.fileExistsAtPath(imagePath.path!) {
            if let _ = Utilities.fileOperations.FILE_MANAGER.contentsAtPath(imagePath.path!) {
                
                do {
                    try Utilities.fileOperations.FILE_MANAGER.removeItemAtURL(imagePath)
                    
                    return (true, nil)
                }
                catch {
                    print("Unable to delete data.")
                    let errorString = "Opps! The file does not exist"
                    return (false, errorString)
                    
                }
            }
            else {
                return (false, "No data found.")
            }
        }
        
        return (false, "File does not exist.")
    }

}
