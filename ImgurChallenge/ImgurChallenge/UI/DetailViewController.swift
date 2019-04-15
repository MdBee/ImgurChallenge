//
//  DetailViewController.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            self.title = detail.title
            self.activityIndicator?.isHidden = false
            
            if detail.imageData != nil {
                self.imageView?.image = UIImage(data: detail.imageData!)
                self.activityIndicator?.isHidden = true
            } else {
                guard let link = detail.imageLink
                    else { print("no image link"); return}
                if let imgURL = URL.init(string: link) {
                    do {
                        let imageData = try Data(contentsOf: imgURL as URL);
                        let image = UIImage(data: imageData);
                        DispatchQueue.main.async {
                        self.imageView?.image = image
                        self.activityIndicator?.isHidden = true
                        }
                        
                        //update Item with imageData
                        detail.imageData = imageData
                    } catch {
                        print("Unable to load data: \(error)")
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        configureView()
    }
    
    var detailItem: Item? {
        didSet {
            configureView()
        }
    }
}

extension DetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
