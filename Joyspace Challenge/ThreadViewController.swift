//
//  ThreadViewController.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/28/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//

import UIKit
import CoreData

protocol ThreadDelegate {
    func createdNewThread(withTitle title:String?)
    func noTitleEntered()
}

class ThreadViewController: UIViewController, ThreadDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    private var threads:[JCThread] = []
    private var selectedThread:JCThread?
    let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.registerNib(UINib(nibName: "ThreadTableViewCell", bundle: nil), forCellReuseIdentifier: "ThreadTableViewCell")
    }
    
    override func viewWillAppear(animated: Bool) {
        let fetchRequest = NSFetchRequest(entityName: "JCThread")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            threads = results as! [JCThread]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func createNewThread(sender: AnyObject) {
        if threads.count == 0 || threads[0].title != nil {
            let entity =  NSEntityDescription.entityForName("JCThread", inManagedObjectContext:managedContext)
            if let selectedThread = NSManagedObject(entity: entity!,
                insertIntoManagedObjectContext: managedContext) as? JCThread {
                    self.selectedThread = selectedThread
                    threads.insert(selectedThread, atIndex: 0)
                    tableView.reloadData()
                    if let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as? ThreadTableViewCell {
                        cell.thread = selectedThread
                        cell.titleField.becomeFirstResponder()
                    }
            }
        }
    }
    
    func createdNewThread(withTitle title:String?) {
        selectedThread!.title = title
        selectedThread!.createdAt = NSDate()
        do {
            try managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        performSegueWithIdentifier("goToChat", sender: self)
    }
    
    func noTitleEntered() {
        let alert = UIAlertController(title: "Uh-Oh",
            message: "The title must be at least 1 character long.", preferredStyle: UIAlertControllerStyle.Alert)
        let yesButton = UIAlertAction(title: "OK",
            style: .Default) { (alert) -> Void in
        }
        alert.addAction(yesButton)
        
        presentViewController(alert, animated: true,
            completion: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let chatController = segue.destinationViewController as? ChatViewController {
            chatController.thread = selectedThread
            if let title = selectedThread?.title {
                chatController.title = title
            }
        }
    }
}

extension ThreadViewController: UITableViewDelegate, UITableViewDataSource {
        
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 120
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ThreadTableViewCell", forIndexPath: indexPath) as! ThreadTableViewCell
        cell.threadDelegate = self
        if let title = threads[indexPath.row].title {
            cell.titleField.text = title
            cell.titleField.userInteractionEnabled = false
        } else {
            cell.titleField.text = nil
            cell.titleField.userInteractionEnabled = true
        }
        cell.dateLabel.text = " "
        if threads[indexPath.row].messages?.count > 0 {
            if let message = threads[indexPath.row].messages?.lastObject as? JCMessage {
                if let messageText = message.text {
                    cell.lastMessageImageView.image = nil
                    cell.lastMessageLabel.text = messageText
                } else if let messageImageData = message.image {
                    cell.lastMessageImageView.image = UIImage(data: messageImageData)
                    cell.lastMessageLabel.text = nil
                }
                if let timeStamp = message.timestamp {
                    cell.dateLabel.text = timeStamp.stringFromDate()
                }
            }
        } else {
            cell.lastMessageImageView.image = nil
            cell.lastMessageLabel.text = nil
            if let timeStamp = threads[indexPath.row].createdAt {
                cell.dateLabel.text = timeStamp.stringFromDate()
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if (threads.count == 0 || threads[0].title != nil) && (selectedThread?.title != nil || selectedThread == nil) {
            selectedThread = threads[indexPath.row]
            performSegueWithIdentifier("goToChat", sender: self)
        }
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let renameAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Rename" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            self.selectedThread = self.threads[indexPath.row]
            tableView.setEditing(false, animated: true)
            if let cell = tableView.cellForRowAtIndexPath(indexPath) as? ThreadTableViewCell {
                cell.thread = self.selectedThread
                cell.titleField.userInteractionEnabled = true
                cell.titleField.becomeFirstResponder()
            }
            self.selectedThread = nil
        })
        renameAction.backgroundColor = UIColor.blueColor()
        
        let deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            let thread = self.threads.removeAtIndex(indexPath.row)
            tableView.reloadData()
            self.managedContext.deleteObject(thread)
            do {
                try self.managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: UITableViewRowAnimation.Automatic)
            self.selectedThread = nil
        })

        return [deleteAction, renameAction]
    }
}

extension NSDate {
    func stringFromDate() -> String? {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy, HH:mm:ss"
        let dateString = dateFormatter.stringFromDate(self)
        return dateString
    }
}
