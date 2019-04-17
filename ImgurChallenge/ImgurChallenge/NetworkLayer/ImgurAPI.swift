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
    var container : NSPersistentContainer { return CoreDataStack.shared.persistentContainer }
    
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
            }
        }
        
        guard !rawItems.isEmpty
            else { self.postNoResultsNotification()
                debugPrint("No raw items.")
                return }
        
        // Create a private queue context.
        let taskContext = self.container.newBackgroundContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
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
    
        self.postFinishedNotification()
    }
    
    func importOneBatch(_ itemsBatch: [[String : Any]], taskContext: NSManagedObjectContext) -> Bool {
        
        var success = false
        
        // taskContext.performAndWait runs on the URLSession's delegate queue
        // so it won’t block the main thread.
        taskContext.performAndWait {
            // Create a new record for each item in the batch.
            for rawItem in itemsBatch {
                guard let link = rawItem["link"] as? String,
                    link != ""
                    else { return }
                
                let newItem = Item(context: taskContext)
                
                newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
                newItem.title = rawItem["title"] as? String ?? (rawItem["galleryTitle"] as? String ?? "no title")
                newItem.nsfw = rawItem["nsfw"] as? Bool ?? (rawItem["galleryNsfw"] as? Bool ?? false)
                newItem.imageLink = link
                newItem.imageData = nil
                
                let suffix = (link as NSString).pathExtension
                newItem.thumbnailLink = (link as NSString).deletingPathExtension + "t." + suffix
                newItem.thumbnailData = nil
            }
            
            do {
                try taskContext.save()
            } catch {
                debugPrint("Error: \(error)\nCould not save Core Data context.")
                return
            }
            // Reset the taskContext to free the cache and lower the memory footprint.
            taskContext.reset()
            
            success = true
        }
        return success
    }
    
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
    
    func postFinishedNotification() {
        NotificationCenter.default.post(name: .dataFetchFinished, object: self)
    }
}

