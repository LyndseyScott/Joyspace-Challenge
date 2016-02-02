//
//  ThreadTableViewCell.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/28/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//

import UIKit
import CoreData

class ThreadTableViewCell: UITableViewCell {

    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var lastMessageImageView: UIImageView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    private let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var threadDelegate:ThreadDelegate?
    var thread:JCThread?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    @IBAction func titleFinished(sender: AnyObject?) {
        if titleField.text?.characters.count > 0 {
            self.endEditing(true)
            if thread?.title?.isEmpty == false {
                titleField.userInteractionEnabled = false
                thread?.title = titleField.text
                do {
                    try managedContext.save()
                } catch let error as NSError  {
                    print("Could not save \(error), \(error.userInfo)")
                }
            } else if threadDelegate != nil {
                threadDelegate!.createdNewThread(withTitle: titleField.text)
            }
        } else if threadDelegate != nil {
            threadDelegate!.noTitleEntered()
        }
    }
}
