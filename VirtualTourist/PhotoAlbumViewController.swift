//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Erwin Santacruz on 10/1/15.
//  Copyright © 2015 Erwin Santacruz. All rights reserved.
//

import UIKit
import MapKit
import CoreData

let CELL = "photoCell"

class PhotoAlbumViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate {
    
    var client: Client!
    var pin: Pin!
    
    var lat: String?
    var lon: String?
    var mapCoordinates: CLLocationCoordinate2D?
    
    var editButton: UIBarButtonItem!
    var refreshButton: UIBarButtonItem!
    var trashButton: UIBarButtonItem!
    var flexSpaceButton: UIBarButtonItem!
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    var selectedIndexes = [NSIndexPath]()
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStack.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin);
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
        }
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            self.mapView.mapType = .Standard
            self.mapView.delegate = self
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        client = Client.sharedInstance()
        
        let _ = fetchObjects() as! [Photo]
        
        setupUI()
        mapSetup()
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if !editing {
            navigationItem.title = pin.title
        }
        
        collectionView.reloadData()
        collectionView.layoutIfNeeded()
    }
    
    override func viewWillDisappear(animated: Bool)
    {
        // Check if user remained in edit mode
        if !navigationController!.toolbarHidden {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }
    
    func setupUI()
    {
        // Navigation buttons
        editButton = editButtonItem()
        refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Refresh, target: self, action: Selector("refreshCollection"))
        
        navigationItem.setRightBarButtonItems([editButton, refreshButton], animated: true)
        navigationItem.title = pin.title
        
        // Toolbar buttons
        trashButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deleteImages"))
        
        flexSpaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        
        self.setToolbarItems([flexSpaceButton, trashButton], animated: true)
        navigationController!.setToolbarHidden(true, animated: true)
    }
    
    func mapSetup()
    {
        if let pinObject = pin {
            lat = pinObject.latitude?.stringValue
            lon = pinObject.longitude?.stringValue
            
            mapCoordinates = CLLocationCoordinate2D(latitude: pinObject.latitude as! Double, longitude: pinObject.longitude as! Double)
            
            let span = MKCoordinateSpan(latitudeDelta: 2.5, longitudeDelta: 2.5)
            
            let region = MKCoordinateRegionMake(mapCoordinates!, span)
            mapView.setRegion(region, animated: true)
            
            mapView.centerCoordinate = mapCoordinates!
            
            mapView.addAnnotation(pin as MKAnnotation)
        }
        
    }
    
    func fetchObjects() -> [AnyObject]!
    {
        // Start the fetched results controller
        let photos:[AnyObject]!
        
        do {
            try fetchedResultsController.performFetch()
            
            if let photoObjects = fetchedResultsController.fetchedObjects {
                photos = photoObjects
            }
            else {
                print("No fetchedResultsController.fetchedObjects found.")
                photos = nil
            }
        }
        catch {
            print("No results found.")
            photos = nil
        }
        
        return photos
    }
    
    override func setEditing(editing: Bool, animated: Bool)
    {
        super.setEditing(editing, animated: animated)
        
        if editing {
            navigationItem.title = "Select images"
            navigationController?.setToolbarHidden(false, animated: true)
            collectionView.allowsMultipleSelection = true
        }
        else {
            navigationItem.title = pin.title
            navigationController?.setToolbarHidden(true, animated: true)
            
            for indexPath in selectedIndexes {
                let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
                cell.photoCell.alpha = 1.0
                collectionView.deselectItemAtIndexPath(indexPath, animated: true)
            }
            
            selectedIndexes.removeAll()
        }
    }
    
    func deleteImages()
    {
        if selectedIndexes.isEmpty {
            return
        }
        else {
            deleteAlert(nil, completionHandler: { (bool) -> () in
                if bool {
                    self.deleteImagesAtIndexPath()
                }
            })
        }
    }
    
    func deleteImagesAtIndexPath()
    {
        var photosToDelete = [Photo]()
        
        for indexPath in selectedIndexes {
            photosToDelete.append(fetchedResultsController.objectAtIndexPath(indexPath) as! Photo)
        }
        
        for i in photosToDelete {
            sharedContext.deleteObject(i)
            
            CoreDataStack.sharedInstance().saveContext()
        }
        
        selectedIndexes = [NSIndexPath]()
        
        navigationItem.title = "Select images"
    }
    
    func refreshCollection()
    {
        let photo = fetchedResultsController.fetchedObjects as! [Photo]
        
        for i in photo {
            let _ = Utilities.imageCleanup(i.id!)
            sharedContext.deleteObject(i)
        }

        self.client.getFlickrData(pin) { (errorstring) -> () in
            //print(NSThread.isMainThread())
            
            let _ = self.fetchObjects()
            
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                self.collectionView.reloadData()
            }
        }
    }
    
    func retryAlert(error:String?, completionHandler:(Bool) -> ())
    {
        let alertController = UIAlertController(title: "Error Processing Request" , message: error, preferredStyle: UIAlertControllerStyle.Alert)
        
        let retryAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) { (action) in
            completionHandler(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
            completionHandler(false)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(retryAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func deleteAlert(error:String?, completionHandler:(Bool) -> ())
    {
        let alertController = UIAlertController(title: nil, message: error, preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let deleteAction = UIAlertAction(title: "Delete", style: UIAlertActionStyle.Destructive) { (action) in
            completionHandler(true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) in
            completionHandler(false)
        }
        
        alertController.addAction(cancelAction)
        alertController.addAction(deleteAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    // MARK: - UICollectionView
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int
    {
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if sectionInfo.numberOfObjects == 0 {
            let img = UIImageView(image: UIImage(named: "launch-bg"))
            img.contentMode = UIViewContentMode.ScaleAspectFit
            collectionView.backgroundView = img
        }
        else {
            let colorview = UIView()
            colorview.backgroundColor = NAV_COLOR
            collectionView.backgroundView = colorview
        }
        
        //print("Number of cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CELL, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        cell.photoCell.alpha = selectedIndexes.contains(indexPath) ? 0.2 : 1.0

        configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func configureCell(cell: PhotoCollectionViewCell, indexPath:NSIndexPath)
    {
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as? Photo
    
        cell.activityIndicator.startAnimating()
    
        let id = photo?.id!
        let imagePath = Utilities.fileOperations.CACHE_DIR.URLByAppendingPathComponent(id!)
        
        if let imageData = Utilities.fileOperations.FILE_MANAGER.contentsAtPath(imagePath.path!) {
            let img = UIImage(data: imageData)
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                cell.photoCell.image = img
                cell.activityIndicator.stopAnimating()
            })
        }
        else {
            // File is not on disk, so download from network
            // First create a background context for long operation
            var temporaryContext: NSManagedObjectContext!
            temporaryContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.PrivateQueueConcurrencyType)
            temporaryContext.persistentStoreCoordinator = self.sharedContext.persistentStoreCoordinator
            
            temporaryContext.performBlock({ () -> Void in
                //print(NSThread.isMainThread())
                
                var mo: Photo!
                
                do {
                    mo = try temporaryContext.existingObjectWithID((photo?.objectID)!) as! Photo
                }
                catch {
                    print(error)
                }
                
                if let imageUrlString = mo!.imageUrl {
                    if let imageUrl = NSURL(string: imageUrlString) {
                        if let imageData = NSData(contentsOfURL: imageUrl) {
                            // Save data to disk
                            mo?.savePathUrl(mo!.id!)
                            
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                cell.photoCell.image = UIImage(data: imageData)
                                cell.activityIndicator.stopAnimating()
                            })
                        }
                    }
                }
            })
        }
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if editing {
            //print(cell.highlighted)
            let containsIndexPath = selectedIndexes.contains(indexPath)
            
            if !containsIndexPath {
                cell.photoCell.alpha = 0.2
                selectedIndexes.append(indexPath)
            }
            
            let imgCount = selectedIndexes.count > 1 ? "images selected" : "image selected"
            let stringTitle = selectedIndexes.count == 0 ? "Select images" : "\(selectedIndexes.count) \(imgCount)"
            navigationItem.title = "\(stringTitle)"
        }
        else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath)
    {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCollectionViewCell
        
        if editing {
            if selectedIndexes.contains(indexPath) {
                let index = selectedIndexes.indexOf(indexPath)
                
                cell.photoCell.alpha = 1.0
                selectedIndexes.removeAtIndex(index!)
            }
            
            let imgCount = selectedIndexes.count > 1 ? "images selected" : "image selected"
            let stringTitle = selectedIndexes.count == 0 ? "Select images" : "\(selectedIndexes.count) \(imgCount)"
            navigationItem.title = "\(stringTitle)"
        }
        else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        }
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(controller: NSFetchedResultsController)
    {
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?)
    {
        switch type{
            
            case .Insert:
                //print("Insert an item")
                insertedIndexPaths.append(newIndexPath!)
                break
            case .Delete:
                //print("Delete an item")
                deletedIndexPaths.append(indexPath!)
                break
            case .Update:
                //print("Update an item.")
                updatedIndexPaths.append(indexPath!)
                break
            default:
                break
            }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController)
    {
        //print("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            

            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: nil )
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}