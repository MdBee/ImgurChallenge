//
//  ImgurAPI.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/9/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import Foundation

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
    
    func persistData(_ jsonArray: [[String: Any]], searchTerm: String) {
        
        print(jsonArray.count)
        
        let imageClusters = jsonArray.map({ $0["images"] })
        
        print(imageClusters.count)
        
        //only persist if searchTerm is still the current one
        
        
        
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
                if let res = response as? HTTPURLResponse {
                    //print(res.debugDescription)
                    
                    //this works
                    let responseObject = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)
                    //print(responseObject)
                    
                    if let jsonArray = (responseObject as! [String:Any])["data"] as? [[String: Any]] {
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

