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
    
    private var longPress:UILongPressGestureRecognizer?
    var chatDelegate:ChatDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func addZoomGestureToImage() {
        if longPress == nil {
            longPress = UILongPressGestureRecognizer(target: self, action: "imageLongPressed:")
            longPress?.minimumPressDuration = 0.25
            messageImageView.addGestureRecognizer(longPress!)
        }
    }
    
    @IBAction func imageLongPressed(gesture: UILongPressGestureRecognizer) {
        if chatDelegate != nil && messageImageView.image != nil {
            if gesture.state == UIGestureRecognizerState.Began {
                chatDelegate!.zoomImage(messageImageView.image!)
            } else if gesture.state == .Ended || gesture.state == .Cancelled {
                chatDelegate!.closeImageZoom()
            }
        }
    }
}
