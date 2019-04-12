//
//  DetailViewController.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
//            if let label = detailDescriptionLabel {
//                label.text = detail.dateTime?.description
//            }
            self.title = detail.title
            //self.activityIndicator.isHidden = false
            
            
            if detail.imageData != nil {
                self.imageView?.image = UIImage(data: detail.imageData!)
            } else {
                
                guard let link = detail.imageLink
                    else { print("no image link")
                        return
                }
                if let imgURL = URL.init(string: link) {
                    do {
                        let imageData = try Data(contentsOf: imgURL as URL);
                        let image = UIImage(data: imageData);
                        self.imageView?.image = image
                        
                        //update Item with imageData
                        detail.imageData = imageData
                    } catch {
                        self.imageView?.image = UIImage(named: "JohnWayne")
                        print("Unable to load data: \(error)")
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }

    var detailItem: Item? {
        didSet {
            // Update the view.
            configureView()
        }
    }


}

