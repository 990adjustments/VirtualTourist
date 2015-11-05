//
//  PhotoCollectionViewCell.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/14/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    var imageURL: String!
    
    @IBOutlet weak var photoCell: UIImageView!

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.hidesWhenStopped = true
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        photoCell.image = nil
    }
}
