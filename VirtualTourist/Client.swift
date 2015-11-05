//
//  Client.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/12/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation


class Client: NSObject {
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }

    func getFlickrPhotos(resource: String, completionHandler: (flickrResults: AnyObject?, error: NSError?) -> ())
    {
        let url = NSURL(string: resource)
        let request = NSURLRequest(URL: url!)
        
        let task = createTask(request, handler: completionHandler)
        task.resume()
        
        
    }
    
    func createTask(request: NSURLRequest, handler:(results: AnyObject?, error: NSError?) -> ()) -> NSURLSessionDataTask
    {
        let task = session.dataTaskWithRequest(request) { (data, response, error) -> Void in
            if let err = error {
                handler(results: nil, error: err)
            }
            else {
                // parse data
                Client.parseJSONData(data!, completionHandler: handler)
            }
        }
        
        return task
    }

    class func parseJSONData(data: NSData, completionHandler: (result: AnyObject?, error: NSError?) -> ())
    {
        var parseError: NSError?
        
        let parsedResult: AnyObject?
        
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch let error as NSError {
            parseError = error
            parsedResult = nil
        }
        
        if let error = parseError {
            completionHandler(result: nil, error: error)
        }
        else {
            completionHandler(result: parsedResult!, error: nil)
        }
        
    }
    
    class func sharedInstance() -> Client {
        struct Static {
            static let instance = Client()
        }
        
        return Static.instance
    }
}