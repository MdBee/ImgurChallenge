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
        if let detail = detailItem {
            self.title = detail.title
            
            if detail.imageData != nil {
                self.imageView?.image = UIImage(data: detail.imageData!)
                self.activityIndicator?.isHidden = true
            } else {
                guard let link = detail.imageLink
                    else { debugPrint("no image link"); return}
                if let imgURL = URL.init(string: link) {
                    do {
                        let imageData = try Data(contentsOf: imgURL as URL);
                        let image = UIImage(data: imageData);
                        DispatchQueue.main.async {
                            self.imageView?.image = image
                            self.activityIndicator?.isHidden = true
                       
                        // Update Item with imageData.
                        detail.imageData = imageData
                        // Refault it for the next time it is accessed.
                        detail.managedObjectContext?.refresh(detail, mergeChanges: true)
                        }
                    } catch {
                        self.activityIndicator?.isHidden = true
                        debugPrint("Unable to load data: \(error)")
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        self.activityIndicator?.isHidden = true
        configureView()
    }
    
    var detailItem: Item? {
        didSet {
            self.activityIndicator?.isHidden = false
            self.view.bringSubviewToFront(self.activityIndicator)
            configureView()
        }
    }
}

extension DetailViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
}
