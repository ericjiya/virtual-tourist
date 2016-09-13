//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by jiya on 8/19/16.
//  Copyright © 2016 jiya. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var noImageLabel: UILabel!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIBarButtonItem!
    
    var selectedPin: Pin!
    
    // Screen dimension
    var screenSize: CGRect!
    var screenWidth: CGFloat!
    var screenHeight: CGFloat!
    
    // The selected indexes array keeps all of the indexPaths for cells that are "selected". The array is
    // used inside cellForItemAtIndexPath to lower the alpha of selected cells.
    var selectedIndexes = [NSIndexPath]()
    
    var cellCreationCounter: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("Selected Pin is \(selectedPin)")
        
        setPinMap(true)
        
//        noImageLabel.text = "Testing"
//        noImageLabel.textColor = UIColor.redColor()
        
        fetchedResultsController.delegate = self
        // Fetch photos
        do{
            print("Perform Fetching...")
            try fetchedResultsController.performFetch()
        }catch let e as NSError{
            print("Error while trying to perform a search: \n\(e)\n\(fetchedResultsController)")
        }
        
        // check fetched photos
        print("Fetched \(fetchedResultsController.fetchedObjects)")
        if fetchedResultsController.fetchedObjects?.count == 0 {
            print("No photos fetched!")
            newCollectionBtn.enabled = true
            self.noImageLabel.hidden = false
        }
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //photoCollectionView.backgroundColor = UIColor.blueColor()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Get screen info of current device
        screenSize = UIScreen.mainScreen().bounds
        screenWidth = screenSize.width
        screenHeight = screenSize.height
        
        // Lay out the collection view so that cells take up 1/3 of the width,
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth / 3, height: screenWidth / 3)
        
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        
        let width = floor(self.photoCollectionView.frame.size.width/3)
        layout.itemSize = CGSize(width: width, height: width)
        photoCollectionView.collectionViewLayout = layout
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    var fetchedResultsController: NSFetchedResultsController {
        print("in fetchedResultsController...")
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.selectedPin)

        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    }
    
    func setPinMap(animated: Bool) {
        
        //Set Region
        let span = MKCoordinateSpan(latitudeDelta: 0.3, longitudeDelta: 0.3)
        let savedRegion = MKCoordinateRegion(center: selectedPin.coordinate, span: span)
        mapView.setRegion(savedRegion, animated: animated)
        
        self.mapView.addAnnotation(selectedPin)
        self.mapView.zoomEnabled = false
        self.mapView.scrollEnabled = false
        self.mapView.userInteractionEnabled = false
    }
    
    //MARK: Configure Cell
    func configureCell(cell: PhotoCell, indexPath: NSIndexPath) {
        
        //let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        cellCreationCounter = cellCreationCounter + 1
        print("cellCreationCounter:  \(cellCreationCounter)")
        
        // set alpha value of selected or unselected images
        if let _ = selectedIndexes.indexOf(indexPath) {
            cell.imageView.alpha = 0.3
        } else {
            cell.imageView.alpha = 1.0
        }
    }
    
    // MARK: CollectionView
    
    // Determine how many sections to display
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    // Determine how many images each section should contain
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section]
        
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        print("filling cells ... ")
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        // reset pevious images in the xell
        cell.imageView.image = nil
        
        cell.backgroundColor = UIColor.whiteColor()
        
        // makeing sure the activity indicator is animating
        cell.activityIndicator.startAnimating()
        
        // if there is an image, update the cell appropriately
        if photo.image != nil {
            
        
            //cell.imageView.alpha = 0.0
            cell.imageView.image = photo.image
            cell.activityIndicator.stopAnimating()
            
            //UIView.animateWithDuration(0.2, animations: { cell.imageView.alpha = 1.0 })
        }
        // modify the cell
        self.configureCell(cell, indexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is tapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, indexPath: indexPath)
        
        changeButtonTitle()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoCell
        
        // Whenever a cell is untapped we will toggle its presence in the selectedIndexes array
        if let index = selectedIndexes.indexOf(indexPath) {
            selectedIndexes.removeAtIndex(index)
        } else {
            selectedIndexes.append(indexPath)
        }
        
        // Then reconfigure the cell
        configureCell(cell, indexPath: indexPath)
        
        changeButtonTitle()
    }
    
    func changeButtonTitle() {
        // change button text based on what is selected in collection view
        if selectedIndexes.count > 0 {
            newCollectionBtn.title = "Remove Selected Pictures"
        } else {
            newCollectionBtn.title = "New Collection"
        }
    }
}