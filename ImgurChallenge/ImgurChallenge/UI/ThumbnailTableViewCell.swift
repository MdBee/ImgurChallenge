//
//  ThumbnailTableViewCell.swift
//  ImgurChallenge
//
//  Created by Matt Bearson on 4/11/19.
//  Copyright © 2019 Matt Bearson. All rights reserved.
//

import Foundation
import UIKit

class ThumbnailTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func prepareForReuse() {
        self.thumbnailImageView.image = UIImage()
        self.titleLabel.text = nil
        self.backgroundColor = UIColor.white
    }
    
}
