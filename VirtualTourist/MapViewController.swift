//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/1/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import CoreData
import MapKit

let ANNOTATION_IDENTIFIER = "annotationId"
let NAV_COLOR = UIColor(red: 1.0, green: 35.0/255, blue: 70.0/255, alpha: 1.0)

class MapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate,CLLocationManagerDelegate {
    
    var pins: [Pin]!
    var pinObject: Pin!
    var client: Client!
    
    var locationManager: CLLocationManager?
    var editButton: UIBarButtonItem!
    var pinLocation: String?
    var mapCoordinates: CLLocationCoordinate2D!
    
    var defaults = NSUserDefaults.standardUserDefaults()
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            self.activityIndicator.hidesWhenStopped = true
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "location", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
        }()
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            self.mapView.mapType = .Standard
            self.mapView.delegate = self
            self.mapView.showsUserLocation = false
        }
    }
    
    @IBAction func pinTapGesture(sender: UILongPressGestureRecognizer)
    {
        if sender.state == UIGestureRecognizerState.Changed {
            //print("Changed")
            let touchLocation = sender.locationInView(mapView)
            mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            //print("Tapped at lat: \(mapCoordinates.latitude) long: \(mapCoordinates.longitude)")
            
        }
        
        if sender.state == UIGestureRecognizerState.Ended {
            //print("Drop pin")
            mapView.alpha = 0.5
            activityIndicator.startAnimating()
            
            let touchLocation = sender.locationInView(mapView)
            mapCoordinates = mapView.convertPoint(touchLocation, toCoordinateFromView: mapView)
            //print("Tapped at lat: \(mapCoordinates.latitude) long: \(mapCoordinates.longitude)")
            
            let loc = CLLocation(latitude: mapCoordinates.latitude, longitude: mapCoordinates.longitude)
            dropAnnotation(loc)
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        startLocationUpdates()
        client = Client.sharedInstance()
        
        mapSetUp()
        setUpUI()

        fetchedResultsController.delegate = self
        
        if let pinObjects = fetchObjects() {
            if !pinObjects.isEmpty {
                // add map annotations
                mapView.addAnnotations(pinObjects as! [MKAnnotation])
                editButton.enabled = true
            }
        }
        else {
            print("No fetchedResultsController.fetchedObjects found.")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if !navigationController!.toolbarHidden {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func mapSetUp()
    {
        // Read defaults
        let center = CLLocationCoordinate2D(latitude: defaults.doubleForKey("latitude"), longitude: defaults.doubleForKey("longitude"))
        let span = MKCoordinateSpan(latitudeDelta: defaults.doubleForKey("latitudeDelta"), longitudeDelta: defaults.doubleForKey("longitudeDelta"))
        let region = MKCoordinateRegionMake(center, span)
        
        mapView.setRegion(region, animated: true)
        mapView.centerCoordinate = center
    }
    
    func setUpUI()
    {
        // Setup navigation bar
        navigationController?.navigationBar.barTintColor = NAV_COLOR
        let titleForNav = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navigationController?.navigationBar.titleTextAttributes = titleForNav
        
        // Setup edit button to delete pins
        editButton = editButtonItem()
        navigationItem.setRightBarButtonItem(editButton, animated: true)
        editButton.enabled = false
    }
    
    func dropAnnotation(loc: CLLocation) -> ()
    {
        getPlacemarkFromLocation(loc){(placemark, error) -> () in
            if let err = error {
                let errorString = (err.localizedDescription)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.retryAlert(errorString, completionHandler: { (bool) -> () in
                        if bool {
                            print("Try refetch")
                            self.dropAnnotation(loc)
                        }
                        else {
                            print("Bail out")
                            self.mapView.alpha = 1.0
                            self.activityIndicator.stopAnimating()
                            return
                        }
                    })
                }
            }
            
            if let local = placemark {
                let dictionary: [String : AnyObject] =
                [
                    "latitude": self.mapCoordinates.latitude,
                    "longitude": self.mapCoordinates.longitude,
                    "location": local.locality as String!,
                    "title": local.locality as String!
                ]
                
                self.sharedContext.performBlock({ () -> Void in
                    //print(NSThread.isMainThread())
                    let pin = Pin(dictionary: dictionary, context: self.sharedContext)

                    self.client.getFlickrData(pin, completion: { (errorString) -> () in
                        if errorString == nil {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.mapView.alpha = 1.0
                                self.activityIndicator.stopAnimating()
                                
                                // add map annotations

                                self.mapView.addAnnotation(pin)
                                self.editButton.enabled = true
                            }
                        }
                    })
                })

            }
        }
        
    }
    
    func getPlacemarkFromLocation(location: CLLocation, handler: (CLPlacemark?, NSError?) ->())
    {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> () in
            if let err = error {
                print("reverse geodcode failed: \(error!.localizedDescription)")
                return handler(nil, err)
            }
            else {
                if let placemark = placemarks?.first {
                    return handler(placemark, nil)
                }
            }
            
            return handler(nil, nil)
        })
    }
    
    func startLocationUpdates()
    {
        // Create the location manager if this object does not
        // already have one.
        
        if locationManager == nil {
            locationManager = CLLocationManager()
        }
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager?.requestWhenInUseAuthorization()
        }
        
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func retryAlert(error:String?, completionHandler:(Bool) -> ())
    {
        let alertController = UIAlertController(title: "Connection Error" , message: error, preferredStyle: UIAlertControllerStyle.Alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) { (action) -> Void in
            completionHandler(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
            completionHandler(false)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func fetchObjects() -> [AnyObject]!
    {
        let pins:[AnyObject]!
        
        do {
            try fetchedResultsController.performFetch()
            
            if let pinObjects = fetchedResultsController.fetchedObjects {
                pins = pinObjects
            }
            else {
                print("No fetchedResultsController.fetchedObjects found.")
                pins = nil
            }
        }
        catch {
            print("No results found.")
            pins = nil
        }
        
        return pins
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "photoDetail" {
            let vc = segue.destinationViewController as! PhotoAlbumViewController
            
            pins = fetchObjects() as! [Pin]
            
            // Find pin object we tapped on
            for i in pins {
                if i.title == pinLocation {
                    vc.pin = i
                    break
                }
            }
            vc.mapCoordinates = mapCoordinates
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.title = "Tap to delete pins"
        }
        else {
            navigationItem.title = "Virtual Tourist"
        }
    }
    
    // MARK: - MapView Delegate
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        // Set defaults
        defaults.setDouble(mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        defaults.setDouble(mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        defaults.setDouble(mapView.region.center.latitude, forKey: "latitude")
        defaults.setDouble(mapView.region.center.longitude, forKey: "longitude")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView)
    {
        if editing {
            let pin = view.annotation as! Pin
            
            if !pin.photos!.isEmpty {
                for i in pin.photos! as NSArray {
                    let photo = i as! Photo
                    let _ = Utilities.imageCleanup(photo.id!)
                }
            }

            sharedContext.deleteObject(pin)
            mapView.removeAnnotation(pin)
            
            CoreDataStack.sharedInstance().saveContext()
            
            // Disable the edit button
            if mapView.annotations.isEmpty {
                setEditing(false, animated: true)
                editButton.enabled = false
            }
        }
        else {
            // We are not in edit mode so push view
            mapView.deselectAnnotation(view.annotation, animated: true)
            pinLocation = (view.annotation?.title)!
            
            performSegueWithIdentifier("photoDetail", sender: self)
        }
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?
    {
        if annotation is MKUserLocation {
            return nil
        }
        
        var annView = mapView.dequeueReusableAnnotationViewWithIdentifier(ANNOTATION_IDENTIFIER) as? MKPinAnnotationView
        
        if annView == nil {
            annView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ANNOTATION_IDENTIFIER)
            annView!.canShowCallout = false
            annView!.animatesDrop = true
        }
        else {
            annView!.annotation = annotation
        }
        
        return annView
    }
    
    // MARK: - LocationManager Delegate
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus)
    {
        if status == .AuthorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation])
    {
        let span = MKCoordinateSpan(latitudeDelta: 35, longitudeDelta: 35)
        let region:MKCoordinateRegion = MKCoordinateRegionMake((locations.first?.coordinate)!, span)
        mapView.setRegion(region, animated: true)
        
        locationManager?.stopUpdatingLocation()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

