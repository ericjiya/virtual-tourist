//
//  Pin.swift
//  Virtual Tourist
//
//  Created by jiya on 8/20/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import UIKit
import CoreData
import MapKit

@objc(Pin)

class Pin: NSManagedObject, MKAnnotation {
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    var locCoordinate: CLLocationCoordinate2D? = nil
    
    var coordinate: CLLocationCoordinate2D {
        return locCoordinate!
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        //print(entity)
        latitude = dictionary[Keys.latitude] as! Double
        longitude = dictionary[Keys.longitude] as! Double
        
        locCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
    }
    
}