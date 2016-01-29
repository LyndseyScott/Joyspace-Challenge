//
//  MessageTableViewCell.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/28/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//

import UIKit

class MessageTableViewCell: UITableViewCell {

    @IBOutlet weak var bubbleImageView: UIImageView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageTrailingConstraint: NSLayoutConstraint!
    @IBOutlet weak var timeStampLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}
