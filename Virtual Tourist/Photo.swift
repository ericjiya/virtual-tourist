//
//  Photo.swift
//  Virtual Tourist
//
//  Created by jiya on 8/23/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import UIKit
import CoreData

@objc(Photo)
class Photo : NSManagedObject {
    
    @NSManaged var filepath : String?
    @NSManaged var url : String
    
    @NSManaged var pin: Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], pin: Pin, context: NSManagedObjectContext) {
        
        // Core Data
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        self.url = dictionary[Constants.JSONResponseKeys.imageUrl] as! String
        
        self.pin = pin
    }
    
    var image: UIImage? {
        
        if let imageFilepath = filepath {
            print("building UIImage...")
            // File Path
            let filePath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
            
            // File Name
            let filePathURL = NSURL.fileURLWithPath(imageFilepath)
            let lastPathComponent = filePathURL.lastPathComponent!
            
            // File URL
            let pathArray = [filePath, lastPathComponent]
            let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
            
            return UIImage(contentsOfFile: fileURL.path!)
        }
        
        return nil
    }
}