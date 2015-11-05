//
//  UtilitiesConstants.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 11/1/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit

extension Utilities {
    struct fileOperations {
        static let CACHE_IDENTIFIER = "Images"
        static let FILE_MANAGER = NSFileManager.defaultManager()
        static let CACHE_DIR = FILE_MANAGER.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!.URLByAppendingPathComponent(CACHE_IDENTIFIER, isDirectory: true)
    }
}