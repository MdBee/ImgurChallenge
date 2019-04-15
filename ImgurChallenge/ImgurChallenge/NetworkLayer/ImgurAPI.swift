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
    static let Search = "https://api.imgur.com/3/gallery/search/time/"
}

private let clientID = "Client-ID 126701cd8332f32"

class ImgurAPI: NSObject, URLSessionDelegate {
    class var container : NSPersistentContainer? { return CoreDataStack.shared.container }
    class func persistData(_ jsonArray: [[String: Any]], searchTerm: String) {
        
        print(jsonArray.count)
        
        // Make sure the search term used is still the current one.
        guard searchTerm == MasterViewController.searchTerm
            else { print("searchTerm mismatch"); return }
        
        //        let galleryTitles: [String] = jsonArray.map({ $0["title"] as? String ?? "no gallery title" })
        //        let galleryNsfw: [Bool] = jsonArray.map({ $0["nsfw"] as? Bool ?? false })
        
        // Because titles and nsfw (not safe for work) fields are more likely to be populated at the Gallery level in the JSON response we grab them here and use them with the photo if the photo does not specify a title and/or nsfw status.
        var galleryTitles = [String]()
        var galleryNsfw = [Bool]()
        jsonArray.forEach({
            galleryTitles.append($0["title"] as? String ?? "no gallery title")
            galleryNsfw.append($0["nsfw"] as? Bool ?? false) })
        
        let imageClusters = jsonArray.map({ $0["images"] })
        
        print(imageClusters.count)
        
        guard galleryTitles.count == imageClusters.count,
            galleryNsfw.count == imageClusters.count
            else { print("title or nsfw mismatch error"); return }
        
        
        //for cluster in imageClusters {
        for (index, cluster) in imageClusters.enumerated() {
            
            let galleryTitle = galleryTitles[index]
            let isNsfw = galleryNsfw[index]
            
            guard let validCluster = cluster as? [[String : Any]]
                else { continue }
            for imageItem in validCluster {
                var mutableItem = imageItem
                mutableItem["galleryTitle"] = galleryTitle
                mutableItem["nsfw"] = isNsfw
                self.configureManagedObject(mutableItem)
            }
        }
        
        //self.saveTheManagedObjects()
        CoreDataStack.shared.saveContext()
    }
    
    
    //move to ImgurGalleryDataModel?
    
    class func configureManagedObject(_ rawItem: [String: Any]) {
        guard let context = self.container?.viewContext,
            //let title = rawItem["title"] as? String,
            let link = rawItem["link"] as? String
            else { return }
        guard link != ""
            else {return }
        
        let newItem = Item(context: context)
        
        newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
        newItem.title = rawItem["title"] as? String ?? (rawItem["galleryTitle"] as? String ?? "no title")
        //newItem.title = title
        //        newItem.nsfw = Bool(rawItem["nsfw"] as? Bool ?? false)
        //let isNsfw = NSNumber(booleanLiteral: <#T##Bool#>)
        newItem.nsfw = rawItem["nsfw"] as? Bool ?? false
        // if let isNsfw = rawItem["nsfw"] as? Int {
        //newItem.nsfw = Bool(isNsfw == 1 ? true : false)
        //} else {
        //    newItem.nsfw = false
        //}
        //newItem.nsfw = rawItem["nsfw"] as? Int == 1 ? true : false
        newItem.imageLink = link
        newItem.imageData = nil
        
        let suffix = (link as NSString).pathExtension
        newItem.thumbnailLink = (link as NSString).deletingPathExtension + "t." + suffix
        newItem.thumbnailData = nil
    }
    
    
    
    
    
    
    class func fetchFor(searchTerm: String = "", pageNumber: Int = 0) {
        guard let escapedSearchTerm = searchTerm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: Path.Search + "\(pageNumber)" + "?q=" + escapedSearchTerm)
            else { print("Bad URL error."); return }
        let request = NSMutableURLRequest(url: url)
        
        request.setValue(clientID, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        //request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        
        URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            do {
                if error == nil {
                    if let _ = response as? HTTPURLResponse {
                        //print(res.debugDescription)
                        
                        //this works
                        let responseObject = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)
                        //print(responseObject)
                        
                        //ng
                        if let jsonArray = (responseObject as! [String: Any])["data"] as? [[String: Any]] {
                            print(jsonArray.count)
                            
                            
                            //                        let compact = jsonArray.compactMap({ $0 })
                            //                        print(compact.count)
                            //                        print(compact)
                            
                            //DispatchQueue.main.async {
                            self.persistData(jsonArray, searchTerm: searchTerm)
                            //}
                            
                        }
                        
                    } else {
                        print("Bad response error 1")
                    }
                } else {
                    print("Error = " + String(describing: error))
                }
            } catch {
                print("Bad response error 2")
                print(error.localizedDescription)
            }
            }.resume()
    }
    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        //downloadTask = nil
        if (error != nil) {
            print(error.debugDescription)
        }else{
            print("The task finished transferring data successfully")
        }
    }
}
