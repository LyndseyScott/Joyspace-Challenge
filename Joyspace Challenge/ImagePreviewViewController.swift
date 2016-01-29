//
//  ImagePreviewViewController.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/29/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//

import UIKit
import CoreData

class ImagePreviewViewController: UIViewController {

    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var topConstraint: NSLayoutConstraint!
    var chatDelegate:ChatDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func sendImage(sender: AnyObject) {
        if self.chatDelegate != nil {
            self.chatDelegate?.sendImage(self.previewImageView.image!)
        }
    }
    
    @IBAction func cancel(sender: AnyObject) {
        if self.chatDelegate != nil {
            self.chatDelegate?.closeImagePreview()
        }
    }
}
