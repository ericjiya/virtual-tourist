//
//  FlickerConstants.swift
//  Virtual Tourist
//
//  Created by jiya on 9/10/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import UIKit

struct Constants{
    struct FLICKR {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
    }
    
    struct BBox{
        
        static let HalfWidth = 1.0
        static let HalfHeight = 1.0
        static let LatRange = (-90.0, 90.0)
        static let LonRange = (-180.0, 180.0)
    }
    
    struct RequestParamKeys{
        static let Method = "method"
        static let APIKey = "api_key"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let BoundingBox = "bbox"
        static let PerPage = "per_page"
        static let PageNumber = "page"
    }
    
    struct RequestParamValues{
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "0c8af0a07640516837b0cdb8eeee00e7"
        static let UseSafeSearch = "1"
        static let Extras = "url_m"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let PerPage = "21"
        static let Page = 1
        
    }
    
    struct JSONResponseKeys {
        static let photos = "photos"
        static let photo = "photo"
        static let pages = "pages"
        static let total = "total"
        static let imageUrl = "url_m"
    }
}
