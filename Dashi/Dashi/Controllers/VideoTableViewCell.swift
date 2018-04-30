//
//  VideoTableViewCell.swift
//  Dashi
//
//  Created by Arslan Memon on 11/9/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit

class VideoTableViewCell: UITableViewCell {

    @IBOutlet weak var uploadDownloadIcon: UIImageView!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var thumbnail: UIImageView!
    @IBOutlet weak var storageIcon: UIImageView!
    var id: String!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        layer.borderWidth = 7

        layer.borderColor = UIColor(red: 238 / 255, green: 238 / 255, blue: 238 / 255, alpha: 1).cgColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
