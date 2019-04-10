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

class ImgurAPI: NSObject {
    
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
                    print(res.debugDescription)
                    
                    let jsonDictionary = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments)
                    
                //let jsonDictionary = try JSONDecoder().decode(ImgurGalleryDataModel.self, from: data ?? Data())
                print(jsonDictionary)
                } else {
                   print(Error.badResponse(2))
                }
            } else {
                print("Error = " + String(describing: error))
            }
            } catch {
                print(Error.badResponse(1))
            }
        }.resume()
    }
}

