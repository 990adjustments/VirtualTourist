//
//  Constants.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/1/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

extension Client {
    struct methods  {
        static let FLICKR_BASE_URL = "https://api.flickr.com/services/rest/"
        static let METHOD_NAME = "flickr.photos.search"
    }
    
    struct parameters {
        static let API_KEY = "55e86208c2487021da7ebcc2a23a2ab8"
        static let METHOD_NAME = "flickr.photos.search"
        static let EXTRAS = "url_q, geo"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let HAS_GEO = "1"
        static let BBOX = "0,0,180,90"
        static let PER_PAGE = "56"
        static let RADIUS = "3"
        static let RADIUS_UNITS = "km"
        static let ACCURACY = "11"
        static let MIN_DATE = "2000-01-01 00:00:00"
    }
}