//
//  ImgurAPI.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/9/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import Foundation
import CoreData

enum Path {
    static let GallerySearch = "https://api.imgur.com/3/gallery/search/time/"
}

private let clientID = "Client-ID 126701cd8332f32"

class ImgurAPI: NSObject {
    var container : NSPersistentContainer { return CoreDataStack.shared.container }
    
    func persistData(_ jsonArray: [[String: Any]], searchTerm: String) {
        
        // Make sure the search term used is still the current one.
        guard searchTerm == MasterViewController.searchTerm
            else { self.postNoResultsNotification()
                debugPrint("searchTerm mismatch")
                return }
        
        // Because titles and nsfw (not safe for work) fields are more likely to be populated at the Gallery level in the JSON response we grab them here and use them with the photo if the photo does not specify a title and/or nsfw status.
        var galleryTitles = [String]()
        var galleryNsfw = [Bool]()
        jsonArray.forEach({
            galleryTitles.append($0["title"] as? String ?? "no gallery title")
            galleryNsfw.append($0["nsfw"] as? Bool ?? false)
        })
        
        let imageClusters = jsonArray.map({ $0["images"] })
        
        guard galleryTitles.count == imageClusters.count,
            galleryNsfw.count == imageClusters.count
            else { self.postNoResultsNotification()
                debugPrint("title or nsfw mismatch error")
                return }
        
        var rawItems = [[String : Any]]()
        for (index, cluster) in imageClusters.enumerated() {
            let galleryTitle = galleryTitles[index]
            let isNsfw = galleryNsfw[index]
            
            guard let validCluster = cluster as? [[String : Any]]
                else { continue }
            for imageItem in validCluster {
                var mutableItem = imageItem
                mutableItem["galleryTitle"] = galleryTitle
                mutableItem["galleryNsfw"] = isNsfw
                rawItems.append(mutableItem)
                //self.configureManagedObject(mutableItem)
            }
        }
        
        guard !rawItems.isEmpty
            else { self.postNoResultsNotification()
                debugPrint("No raw items.")
                return }
        
        // Create a private queue context.
        let taskContext = self.container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil // Just in case the default has changed for iOS.
        
        // Process records in batches to avoid a high memory footprint.
        let batchSize = 64
        let count = rawItems.count
        
        // Determine the total number of batches.
        var numBatches = count / batchSize
        numBatches += count % batchSize > 0 ? 1 : 0
        
        for batchNumber in 0 ..< numBatches {
            
            // Determine the range for this batch.
            let batchStart = batchNumber * batchSize
            let batchEnd = batchStart + min(batchSize, count - batchNumber * batchSize)
            let range = batchStart..<batchEnd
            
            // Create a batch for this range from the decoded JSON.
            let itemsBatch = Array(rawItems[range])
            
            // Stop the entire import if any batch is unsuccessful.
            if !importOneBatch(itemsBatch, taskContext: taskContext) {
                return
            }
        }
       // CoreDataStack.shared.saveContext()
    }
    
    func importOneBatch(_ itemsBatch: [[String : Any]], taskContext: NSManagedObjectContext) -> Bool {
        
        var success = false
        
        // taskContext.performAndWait runs on the URLSession's delegate queue
        // so it won’t block the main thread.
        taskContext.performAndWait {
            // Create a new record for each item in the batch.
            for rawItem in itemsBatch {
                
                // Create an Item managed object on the private queue context.
                //guard let newItem = NSEntityDescription.insertNewObject(forEntityName: "Item", into: taskContext) as? Item
                //    else { debugPrint("Error creating newItem"); return }
                
                // Populate the Item's properties using the raw data.
                guard let link = rawItem["link"] as? String,
                    link != ""
                    else { return }
//                guard link != ""
//                    else {return }
//                context.undoManager = nil
                let newItem = Item(context: taskContext)
                
                newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
                newItem.title = rawItem["title"] as? String ?? (rawItem["galleryTitle"] as? String ?? "no title")
                newItem.nsfw = rawItem["nsfw"] as? Bool ?? (rawItem["galleryNsfw"] as? Bool ?? false)
                newItem.imageLink = link
                newItem.imageData = nil
                
                let suffix = (link as NSString).pathExtension
                newItem.thumbnailLink = (link as NSString).deletingPathExtension + "t." + suffix
                newItem.thumbnailData = nil
//                do {
//                    try quake.update(with: quakeData)
//                } catch QuakeError.missingData {
//                    // Delete invalid Quake from the private queue context.
//                    print(QuakeError.missingData.localizedDescription)
//                    taskContext.delete(quake)
//                } catch {
//                    print(error.localizedDescription)
//                }
            }
            
            // Save all insertions and deletions from the context to the store.
            if taskContext.hasChanges {
                do {
                    try taskContext.save()
                } catch {
                    debugPrint("Error: \(error)\nCould not save Core Data context.")
                    return
                }
                // Reset the taskContext to free the cache and lower the memory footprint.
                taskContext.reset()
            }
            
            success = true
        }
        return success
    }
    
 //   class func configureManagedObject(_ rawItem: [String: Any]) {
//        guard let context = self.container?.viewContext,
//            let link = rawItem["link"] as? String
//            else { return }
//        guard link != ""
//            else {return }
//        context.undoManager = nil
//        let newItem = Item(context: context)
//
//        newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
//        newItem.title = rawItem["title"] as? String ?? (rawItem["galleryTitle"] as? String ?? "no title")
//        newItem.nsfw = rawItem["nsfw"] as? Bool ?? (rawItem["galleryNsfw"] as? Bool ?? false)
//        newItem.imageLink = link
//        newItem.imageData = nil
//
//        let suffix = (link as NSString).pathExtension
//        newItem.thumbnailLink = (link as NSString).deletingPathExtension + "t." + suffix
//        newItem.thumbnailData = nil
 //   }
    
    func fetchFor(searchTerm: String = "", pageNumber: Int = 0) {
        guard let escapedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: Path.GallerySearch + "\(pageNumber)" + "?q=" + escapedSearchTerm)
            else { debugPrint("Bad URL error."); return }
        let request = NSMutableURLRequest(url: url)
        
        request.setValue(clientID, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            do {
                if error == nil {
                    if let _ = response as? HTTPURLResponse {
                        let responseObject = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)
                        if let jsonArray = (responseObject as! [String: Any])["data"] as? [[String: Any]] {
                            debugPrint(jsonArray.count)
                            
                            if jsonArray.count == 0 {
                                self.postNoResultsNotification()
                                debugPrint("Posted no results notification")
                            }
                            self.persistData(jsonArray, searchTerm: searchTerm)
                        }
                    } else {
                        self.postNoResultsNotification()
                        debugPrint("Bad response error 1")
                    }
                } else {
                    self.postNoResultsNotification()
                    debugPrint("Error = " + String(describing: error))
                }
            } catch {
                self.postNoResultsNotification()
                debugPrint("Bad response error 2")
                debugPrint(error.localizedDescription)
            }
            }.resume()
    }
    
    func postNoResultsNotification() {
        NotificationCenter.default.post(name: .noResults, object: self)
    }
    
    
    // MARK: - Fetched results controller
    
    
    weak var fetchedResultsControllerDelegate: NSFetchedResultsControllerDelegate?
    
    var fetchedResultsController: NSFetchedResultsController<Item> {
//        if _fetchedResultsController != nil {
//            return _fetchedResultsController!
//        }
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "dateTime", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        if MasterViewController.isFilteringOutNsfw {
            let predicate = NSPredicate(format: "nsfw == %d", Bool(false))
            fetchRequest.predicate = predicate
        }
        
        //let context = container.viewContext
        //context.undoManager = nil
        let controller = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: container.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        controller.delegate = fetchedResultsControllerDelegate
        //_fetchedResultsController = aFetchedResultsController
        
        do {
            try controller.performFetch()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
        return controller
    }
    
    //var _fetchedResultsController: NSFetchedResultsController<Item>? = nil
    
    
//    // MARK: - Fetched results controller updates
//
//    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.beginUpdates()
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
//        switch type {
//        case .insert:
//            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
//        case .delete:
//            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
//        default:
//            return
//        }
//    }
//
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            tableView.insertRows(at: [newIndexPath!], with: .fade)
//        case .delete:
//            guard indexPath != nil
//                else { debugPrint("nil indexPath"); return }
//            tableView.deleteRows(at: [indexPath!], with: .fade)
//        case .update:
//            guard self.tableView.indexPathsForVisibleRows?.contains(indexPath ?? IndexPath()) ?? false
//                else { debugPrint("indexPath out of visible."); return }
//            guard tableView.cellForRow(at: indexPath!) != nil
//                else { debugPrint("cell is nil."); return }
//            configureCell(tableView.cellForRow(at: indexPath!) as! ThumbnailTableViewCell, withItem: anObject as! Item)
//        case .move:
//            guard self.tableView.indexPathsForVisibleRows?.contains(indexPath ?? IndexPath()) ?? false
//                else { debugPrint("indexPath out of visible."); return }
//            configureCell(tableView.cellForRow(at: indexPath!) as! ThumbnailTableViewCell, withItem: anObject as! Item)
//            tableView.moveRow(at: indexPath!, to: newIndexPath!)
//        }
//    }
//
//    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        tableView.endUpdates()
//    }
//
//    // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
//    private func controllerDidChangeContent(controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        // In the simplest, most efficient, case, reload the table view.
//        tableView.reloadData()
//    }
    
}

