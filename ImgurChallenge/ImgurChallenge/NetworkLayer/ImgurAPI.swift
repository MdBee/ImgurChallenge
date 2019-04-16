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
    class var container : NSPersistentContainer? { return CoreDataStack.shared.container }
    class func persistData(_ jsonArray: [[String: Any]], searchTerm: String) {
        
        // Make sure the search term used is still the current one.
        guard searchTerm == MasterViewController.searchTerm
            else { debugPrint("searchTerm mismatch"); return }
        
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
            else { debugPrint("title or nsfw mismatch error"); return }
        
        for (index, cluster) in imageClusters.enumerated() {
            let galleryTitle = galleryTitles[index]
            let isNsfw = galleryNsfw[index]
            
            guard let validCluster = cluster as? [[String : Any]]
                else { continue }
            for imageItem in validCluster {
                var mutableItem = imageItem
                mutableItem["galleryTitle"] = galleryTitle
                mutableItem["galleryNsfw"] = isNsfw
                self.configureManagedObject(mutableItem)
            }
        }
        CoreDataStack.shared.saveContext()
    }
    
    class func configureManagedObject(_ rawItem: [String: Any]) {
        guard let context = self.container?.viewContext,
            let link = rawItem["link"] as? String
            else { return }
        guard link != ""
            else {return }
        context.undoManager = nil
        let newItem = Item(context: context)
        
        newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
        newItem.title = rawItem["title"] as? String ?? (rawItem["galleryTitle"] as? String ?? "no title")
        newItem.nsfw = rawItem["nsfw"] as? Bool ?? (rawItem["galleryNsfw"] as? Bool ?? false)
        newItem.imageLink = link
        newItem.imageData = nil
        
        let suffix = (link as NSString).pathExtension
        newItem.thumbnailLink = (link as NSString).deletingPathExtension + "t." + suffix
        newItem.thumbnailData = nil
    }
    
    class func fetchFor(searchTerm: String = "", pageNumber: Int = 0) {
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
                            
                            // No results.
                            if jsonArray.count == 0 {
                                NotificationCenter.default.post(name: .noResults, object: self)
                                debugPrint("Posted no results notification")
                            }
                            self.persistData(jsonArray, searchTerm: searchTerm)
                        }
                    } else {
                        debugPrint("Bad response error 1")
                    }
                } else {
                    debugPrint("Error = " + String(describing: error))
                }
            } catch {
                debugPrint("Bad response error 2")
                debugPrint(error.localizedDescription)
            }
            }.resume()
    }
}

