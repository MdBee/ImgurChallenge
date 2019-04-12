//
//  DetailViewController.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/8/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
//            if let label = detailDescriptionLabel {
//                label.text = detail.dateTime?.description
//            }
            self.title = detail.title
            //self.activityIndicator.isHidden = false
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

