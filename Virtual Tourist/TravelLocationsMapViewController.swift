//
//  TravelLocationsMapView.swift
//  Virtual Tourist
//
//  Created by jiya on 8/19/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    var appDelegate: AppDelegate!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tabToDeleteLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    var editMode = false
    
    var chosenPin: Pin!
    
    var allPins = [Pin]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        // Setup map
        mapView.delegate = self
        setMapRegion()
        
        // Define gestures
        longPressGesture()
        
        //Fetch Pins
        allPins = fetchAllPins()
        
//        do{
//            try fetchedResultsController.performFetch()
//        }catch let e as NSError{
//            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
//        }
        
        // Add pins on map
        addPinsOnMap()
        
    }
    
    func fetchAllPins() -> [Pin] {
        
        // Create the Fetch Request
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        // Execute the Fetch Request
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch  let error as NSError {
            print("Error in fetchAllActors(): \(error)")
            return [Pin]()
        }
    }
    
//    var fetchedResultsController: NSFetchedResultsController {
//        let fetchRequest = NSFetchRequest(entityName: "Pin")
//        fetchRequest.sortDescriptors = []
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil,cacheName: nil)
//        
//        fetchedResultsController.delegate = self
//        
//        return fetchedResultsController
//    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        tabToDeleteLabel.hidden = true
    
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    // Add pins on map
    func addPinsOnMap(){
        var annotations = [Pin]()
        
        if !allPins.isEmpty{
            for pin in allPins {
                annotations.append(pin)
            }
        
            print("how many pins? \(annotations.count)")
            self.mapView.addAnnotations(annotations)
        }
    }
    
    // set region
    func setMapRegion(){
        if(NSUserDefaults.standardUserDefaults().boolForKey("hasSavingRegion")){
            if let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey("myMapRegion") as? [String: Double] {
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapCenterLat"]!, longitude: savedRegion["mapCenterLng"]!)
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapSpanLat"]!, longitudeDelta: savedRegion["mapSpanLng"]!)
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
        }
    }
    
    // long press gesture
    func longPressGesture(){
        let longPressGesRecognizer = UILongPressGestureRecognizer(target: self, action: "longTapMapAction:")
        longPressGesRecognizer.minimumPressDuration = 1
        mapView.addGestureRecognizer(longPressGesRecognizer)
    }
    
    // Drop a new pin on map
    func longTapMapAction(longPress: UILongPressGestureRecognizer){
        // handle long tap if edit mode is not active
        if !self.editMode{
            print("long tapped begin")
            let cgPoint = longPress.locationInView(self.mapView)
            let mapPoint = self.mapView.convertPoint(cgPoint, toCoordinateFromView: self.mapView)
            
            switch longPress.state {
            case .Began:
                let annotation = MKPointAnnotation()
                annotation.coordinate = mapPoint
                
                // Create a new pin
                var locationDictionary = [String : AnyObject]()
                locationDictionary[Pin.Keys.latitude] = mapPoint.latitude
                locationDictionary[Pin.Keys.longitude] = mapPoint.longitude
                self.chosenPin = Pin(dictionary: locationDictionary, context: sharedContext)
                
                // Add pin to the map
                dispatch_async(dispatch_get_main_queue(), {
                    self.mapView.addAnnotation(self.chosenPin)
                })
                
                // Save pin
                dispatch_async(dispatch_get_main_queue(), {
                    CoreDataStackManager.sharedInstance().saveContext()
                })
            case.Changed:
                chosenPin.willChangeValueForKey("coordinate")
                chosenPin.locCoordinate = mapPoint
                chosenPin.didChangeValueForKey("coordinate")
            case.Ended:
                //Fetch Photos from Flicker
                FlickrClient.sharedInstance().taskForGettingImages(self.chosenPin) {
                    (result, error) in
                    print("Fetched \(result?.count) photos!")
                    if error == nil {
                        // Parse photos
                        dispatch_async(dispatch_get_main_queue()){
                           _ = result?.map() {
                            (dictionary: [String : AnyObject]) -> Photo in
                                //init photo
                                let photo = Photo(dictionary: dictionary, pin: self.chosenPin, context: self.sharedContext)
                            
                                //print("image url is \(photo.imageUrl)")
                                // Get image by url and store it into file system
                                FlickrClient.sharedInstance().getPhotoByImageURL(photo){
                                    (fileSavedPath, error) in
                                
                                    if error == nil {
                                        photo.filepath = fileSavedPath
                                        //print("Saving photo url is \(photo.url), and file save at path: \(photo.filepath)")
                                        
                                        // Save photo
                                        dispatch_async(dispatch_get_main_queue(), {
                                            CoreDataStackManager.sharedInstance().saveContext()
                                        })
                                    } else {
                                        print("Store image into CoreData failed, the error is: \(error)")
                                    }
                                }
                            
                                return photo
                            }
                        }
                    }else{
                        // Can't get photos
                        print("Error: \(error)")
                    }
                }
                
                // Save Data
//                dispatch_async(dispatch_get_main_queue(), {
//                    CoreDataStackManager.sharedInstance().saveContext()
//                })
                
            default:
                return
            }
            
            print("long tapped end")
        }
    }
    
    @IBAction func clickEdit(sender: AnyObject) {
        if !editMode {
            editButton.setTitle("Done", forState: .Normal)
        } else {
            editButton.setTitle("Edit", forState: .Normal)
        }
        
        tabToDeleteLabel.hidden = editMode
        editMode = !editMode
    }
    
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // if no saving region before, set it true
        if(!NSUserDefaults.standardUserDefaults().boolForKey("hasSavingRegion")){
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasSavingRegion")
        }
        
        let userRegion = [
            "mapCenterLat": mapView.region.center.latitude,
            "mapCenterLng": mapView.region.center.longitude,
            "mapSpanLat": mapView.region.span.latitudeDelta,
            "mapSpanLng": mapView.region.span.longitudeDelta
        ]
        
        NSUserDefaults.standardUserDefaults().setObject(userRegion, forKey: "myMapRegion")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        chosenPin = view.annotation as! Pin
        
        if editMode {
            print("tap to delete")
            
            // Remove pin from map
            dispatch_async(dispatch_get_main_queue(), {
                mapView.removeAnnotation(self.chosenPin)
            })
            
            // Delete pin from Core Data
            sharedContext.deleteObject(chosenPin)
            dispatch_async(dispatch_get_main_queue()){
                CoreDataStackManager.sharedInstance().saveContext()
            }
            
        }else{
            print("tap to view photos")
            
            self.performSegueWithIdentifier("showPhotos", sender: self)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Pass the selected object to photo album view controller.
        if(segue.identifier == "showPhotos"){
            let photoAlbumVC:PhotoAlbumViewController = segue.destinationViewController as! PhotoAlbumViewController
            photoAlbumVC.selectedPin = self.chosenPin
        }
    }
}