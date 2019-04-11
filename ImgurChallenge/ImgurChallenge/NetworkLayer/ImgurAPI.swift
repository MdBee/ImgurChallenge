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
    static let Image = ""
}

enum Error {
    case badURL
    case badResponse(Int)
}

private let clientID = "Client-ID 126701cd8332f32"

class ImgurAPI: NSObject, URLSessionDelegate {
    
    //let context = CoreDataStack.shared.persistentContainer.viewContext
    var container : NSPersistentContainer? { return CoreDataStack.shared.container }
    
    //@objc
    func persistData(_ jsonArray: [[String: Any]], searchTerm: String) {
        
        print(jsonArray.count)
        
        let imageClusters = jsonArray.map({ $0["images"] })
        //let imageClusters = jsonArray.compactMap({ $0["images"] })
        
        print(imageClusters.count)
        
        //guard...only persist if searchTerm is still the current one

        //let items = imageClusters.map({ self.configureManagedObject($0) })

        for cluster in imageClusters {
//            guard let rawItem = imageItem as? [String : Any]
//                else { continue }
           // _ = self.configureManagedObject(rawItem)
            guard let validCluster = cluster as? [[String : Any]]
                else { continue }
            for imageItem in validCluster {
                self.configureManagedObject(imageItem)
        }
        }
        
        //self.saveTheManagedObjects()
        CoreDataStack.shared.saveContext()
    }
    
    
    //move to ImgurGalleryDataModel?
    
    func configureManagedObject(_ rawItem: [String: Any]) {
        guard let context = self.container?.viewContext
            else { return }
        let newItem = Item(context: context)

        newItem.dateTime = Date(timeIntervalSince1970: rawItem["datetime"] as? TimeInterval ?? 0)
        newItem.title = rawItem["title"] as? String ?? ""
        newItem.nsfw = Bool(rawItem["nsfw"] as? Bool ?? false)
        newItem.thumbnailLink = (rawItem["link"] as? String ?? "") + "t." + self.extensionForMimeType(rawItem["type"] as? String)
        newItem.thumbnailData = nil
        newItem.imageLink = rawItem["link"] as? String ?? "" + self.extensionForMimeType(rawItem["type"] as? String)
        newItem.imageData = nil
        
        //return newItem
       // self.saveTheManagedObjects()
       // context.insert(newItem)
       // CoreDataStack.shared.saveContext()
    }
    
//    func saveTheManagedObjects() {
//        // Save the context.
//        do {
//            try context.save()
//        } catch {
//            // Replace this implementation with code to handle the error appropriately.
//            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
//            let nserror = error as NSError
//            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
//        }
//
//    }
    
    
    func extensionForMimeType(_ mimeType: String?) -> String {
        switch mimeType {
        case "image/gif":
            return "gif"
        case "image/jpeg":
            return "jpg"
        case "image/png":
            return "png"
        default:
            return ""
        }
    }
    
    
    
    
    func fetchPhotos(searchTerm: String = "", pageNumber: Int = 0) {
        guard let url = URL(string: Path.Search + "\(pageNumber)" + "?q=" + searchTerm)
            else { print(Error.badURL)
                    return }
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
                        
                        DispatchQueue.main.async {
                            self.persistData(jsonArray, searchTerm: searchTerm)
                        }
                        
                    }
                
                } else {
                   print(Error.badResponse(2))
                }
            } else {
                print("Error = " + String(describing: error))
            }
            } catch {
                print(Error.badResponse(1))
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

