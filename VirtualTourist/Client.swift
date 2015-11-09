//
//  Client.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/12/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import Foundation
import CoreData


class Client: NSObject {
    
    var session: NSURLSession
    var sharedContext: NSManagedObjectContext
    
    
    override init() {
        session = NSURLSession.sharedSession()
        sharedContext = CoreDataStack.sharedInstance().managedObjectContext

        super.init()
    }
    
    func getFlickrData(pin: Pin, completion:(errorstring: String?) ->())
    {
        // Get a random radius to search
        let randomRadius = Int(arc4random_uniform(10) + 1)
        
        let lat = pin.latitude
        let lon = pin.longitude
        
        let urlString = "\(Client.methods.FLICKR_BASE_URL)?method=\(Client.methods.METHOD_NAME)&api_key=\(Client.parameters.API_KEY)&format=\(Client.parameters.DATA_FORMAT)&has_geo=\(Client.parameters.HAS_GEO)&lat=\(lat!.stringValue)&lon=\(lon!.stringValue)&extras=\(Client.parameters.EXTRAS)&nojsoncallback=\(Client.parameters.NO_JSON_CALLBACK)&per_page=\(Client.parameters.PER_PAGE)&radius=\(randomRadius)&radius_units=\(Client.parameters.RADIUS_UNITS)&accuracy=\(Client.parameters.ACCURACY)&min_taken_date=\(Client.parameters.MIN_DATE)"
        
        let escapedURLString = urlString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        
        initiateRequest(escapedURLString!, completionHandler: { (flickrResults, error) -> () in
            if let err = error {
                print(err.localizedDescription)
                completion(errorstring: err.localizedDescription)

            }
            
            let error: String = "Unable to retrieve data."
            if let flickrPhotos = flickrResults {
                if let photosDict = flickrPhotos.valueForKey("photos") as? NSDictionary {
                    if let photoArrayDict = photosDict.valueForKey("photo") as? [[String:AnyObject]] {
                        
                        self.sharedContext.performBlock({ () -> Void in
                            //print(NSThread.isMainThread())
                            for dic in photoArrayDict {
                                // Creat Photo entity
                                let photo = Photo(dictionary: dic, context: self.sharedContext)
                                photo.pin = pin
                            }
                            
                            CoreDataStack.sharedInstance().saveContext()
                        })
                        
                        completion(errorstring: nil)
                    }
                    else {
                        completion(errorstring: error)
                    }
                }
                else {
                    completion(errorstring: error)
                }
            }
            else {
                completion(errorstring: error)
            }
        })
    }


    func initiateRequest(resource: String, completionHandler: (flickrResults: AnyObject?, error: NSError?) -> ())
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
                self.parseJSONData(data!, completionHandler: handler)
            }
        }
        
        return task
    }

    func parseJSONData(data: NSData, completionHandler: (result: AnyObject?, error: NSError?) -> ())
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