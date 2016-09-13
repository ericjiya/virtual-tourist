//
//  FlickerClient.swift
//  Virtual Tourist
//
//  Created by jiya on 9/10/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient: NSObject {
    // shared session
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func taskForGettingImages(selectedPin: Pin!, pageNumber: Int=1, completionHandlerForGET: (result: [[String:AnyObject]]?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        /* 1. Set the parameters */
        let methodParameters = [
            Constants.RequestParamKeys.Method: Constants.RequestParamValues.SearchMethod,
            Constants.RequestParamKeys.APIKey : Constants.RequestParamValues.APIKey,
            Constants.RequestParamKeys.BoundingBox : bboxString(selectedPin.latitude, longitude: selectedPin.longitude),
            Constants.RequestParamKeys.SafeSearch : Constants.RequestParamValues.UseSafeSearch,
            Constants.RequestParamKeys.Extras : Constants.RequestParamValues.Extras,
            Constants.RequestParamKeys.Format : Constants.RequestParamValues.ResponseFormat,
            Constants.RequestParamKeys.NoJSONCallback : Constants.RequestParamValues.DisableJSONCallback,
            Constants.RequestParamKeys.PerPage : Constants.RequestParamValues.PerPage,
            Constants.RequestParamKeys.PageNumber : pageNumber
        ]
        
        /* 2/3. Build the URL, Configure the request */
        let request = NSMutableURLRequest(URL: parseURLFromParameters(methodParameters as! [String : AnyObject]))
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                let userInfo = [NSLocalizedDescriptionKey: "There was an error with your request: \(error)"]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGettingImages", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                let userInfo = [NSLocalizedDescriptionKey: "Your request returned a status code other than 2xx!"]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGettingImages", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request!"]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGettingImages", code: 1, userInfo: userInfo))
                return
            }
            
            //print("The data is \(data)")
            
            /* 5. Parse the data */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                let userInfo = [NSLocalizedDescriptionKey: "Could not parse the data as JSON: '\(data)'"]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGettingImages", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Is the "results" key in parsedResult? */
            guard let imagesDictionary = parsedResult.valueForKey(Constants.JSONResponseKeys.photos) as? [String:AnyObject] else {
                let userInfo = [NSLocalizedDescriptionKey: "Cannot find key '\(Constants.JSONResponseKeys.photos)' in \(parsedResult)"]
                completionHandlerForGET(result: nil, error: NSError(domain: "taskForGettingImages", code: 1, userInfo: userInfo))
                return
            }
            
            // check how many images are there
            var totalImagesCount = 0
            if let totalImages = imagesDictionary[Constants.JSONResponseKeys.total] as? String {
                totalImagesCount = (totalImages as NSString).integerValue
            }
            
            if totalImagesCount > 0 {
                if let imagesArray = imagesDictionary[Constants.JSONResponseKeys.photo] as? [[String: AnyObject]] {
                    
                    completionHandlerForGET(result: imagesArray, error: nil)
                    
                } else {
                    print("Cant find key 'photo' in \(imagesDictionary)")
                }
                
            } else {
                
                completionHandlerForGET(result: nil, error: NSError(domain: "Results from Flickr", code: 0, userInfo: [NSLocalizedDescriptionKey: "This pin has no images."]))
            }
        }
        
        task.resume()
        
        return task
    }
    
    func getPhotoByImageURL(photo : Photo, completionHandler: (fileSavedPath: String, error: NSError?) -> Void){
        // 1. Build the URL
        let urlString = photo.url
        let url = NSURL(string: urlString)!
        
        // 2. Build the request
        let request = NSMutableURLRequest(URL: url)
        
        // 3. Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                let userInfo = [NSLocalizedDescriptionKey: "There was an error with your request: \(error)"]
                completionHandler(fileSavedPath: "", error: NSError(domain: "getPhotoByImageURL", code: 1, userInfo: userInfo))
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                let userInfo = [NSLocalizedDescriptionKey: "Your request returned a status code other than 2xx!"]
                completionHandler(fileSavedPath: "", error: NSError(domain: "getPhotoByImageURL", code: 1, userInfo: userInfo))
                return
            }
            
            // 4. Parse the data
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                let userInfo = [NSLocalizedDescriptionKey: "No data was returned by the request!"]
                completionHandler(fileSavedPath: "", error: NSError(domain: "getPhotoByImageURL", code: 1, userInfo: userInfo))
                return
            }
            
            // 5. Save file to a file system path
            let filePath = self.getFilePath(urlString)
            //print("file path is \(filePath)")
            NSFileManager.defaultManager().createFileAtPath(filePath, contents: data, attributes: nil)
            
            // Update the Photo managed object with the file path.
//            dispatch_async(dispatch_get_main_queue()){
//                photo.filepath = filePath
//            }
            completionHandler(fileSavedPath: filePath, error: nil)
        }
        
        // 6. Start the request
        task.resume()
    }
    
    func getFilePath(imageUrl: String) -> String {
        let fileName = NSURL.fileURLWithPath(imageUrl).lastPathComponent!
        //print("fileName = \(fileName)")
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
        //print("dirPath = \(dirPath)")
        let pathArray = [dirPath, fileName]
        let fileURL = NSURL.fileURLWithPathComponents(pathArray)!
        //print("fileURL = \(fileURL)")
        
        return fileURL.path!
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by minimum and maximums
            let minimumLon = max(longitude - Constants.BBox.HalfWidth, Constants.BBox.LonRange.0)
            let minimumLat = max(latitude - Constants.BBox.HalfHeight, Constants.BBox.LatRange.0)
            let maximumLon = min(longitude + Constants.BBox.HalfWidth, Constants.BBox.LonRange.1)
            let maximumLat = min(latitude + Constants.BBox.HalfHeight, Constants.BBox.LatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    func parseURLFromParameters(parameters: [String:AnyObject], withPathExtension: String? = nil) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.FLICKR.ApiScheme
        components.host = Constants.FLICKR.ApiHost
        components.path = Constants.FLICKR.ApiPath + (withPathExtension ?? "")
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
}