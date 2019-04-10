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

private let clientID = "126701cd8332f32"

class ImgurAPI: NSObject {
    
    func fetchPhotos(searchTerm: String = "", pageNumber: Int = 0) {
        guard let url = URL(string: Path.Search + "\(pageNumber)" + "?q=" + searchTerm)
            else { print(Error.badURL)
                    return }
        let request = NSMutableURLRequest(url: url)
        
        request.setValue(clientID, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let session = URLSession.shared
        
        let dataFetch = session.dataTask(with: request as URLRequest) { (data, response, error) -> Void in
            if let res = response as? HTTPURLResponse {
                
            } else {
                print("Error = " + String(describing: error))
            }
        }
        dataFetch.resume()
    }
}

