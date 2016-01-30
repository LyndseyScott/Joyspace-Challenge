//
//  ChatViewController.swift
//  Joyspace Challenge
//
//  Created by Lyndsey Scott on 1/28/16.
//  Copyright © 2016 StandableInc. All rights reserved.
//

import UIKit
import CoreData

protocol ChatDelegate {
    func sendImage(image:UIImage)
    func closeImagePreview()
    func zoomImage(image:UIImage)
    func closeImageZoom()
}

class ChatViewController: UIViewController, ChatDelegate {
    
    @IBOutlet weak var chatTextField: UITextField!
    @IBOutlet weak var chatTableView: UITableView!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    
    let managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    var thread:JCThread?
    var socketIO:SRWebSocket?
    var socketConnected:Bool?
    var connectionLabel:UILabel?
    var imagePreviewView:ImagePreviewViewController?
    var zoomView:UIImageView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        chatTextField.frame = CGRectMake(60, 7, self.view.frame.size.width-120, 30)
        chatTableView.registerNib(UINib(nibName: "MessageTableViewCell", bundle: nil), forCellReuseIdentifier: "MessageTableViewCell")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "textFieldEndEditing:")
        chatTableView.addGestureRecognizer(tapGesture)
        
        socketConnect()
    }
    
    override func viewWillAppear(animated: Bool) {
        scrollTableToBottom(withAnimation: false)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        super.willMoveToParentViewController(parent)
        if parent == nil {
            socketIO?.close()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func sendMessage(sender: AnyObject) {
        view.endEditing(true)
        if let textMessage = self.chatTextField.text where textMessage.characters.count > 0 {
            let entity =  NSEntityDescription.entityForName("JCMessage",
                inManagedObjectContext:managedContext)
            let message = NSManagedObject(entity: entity!,
                insertIntoManagedObjectContext: managedContext) as! JCMessage
            message.text = textMessage
            message.timestamp = NSDate()
            message.isSender = true
            message.thread = thread
            
            thread!.messages?.mutableCopy().addObject(message)
            thread!.updatedAt = message.timestamp
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            chatTableView.reloadData()
            chatTextField.text = nil
            socketIO?.send(textMessage)
        }
    }
    
    @IBAction func textFieldEndEditing(sender: AnyObject) {
        view.endEditing(true)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        toolbarBottomConstraint.constant = keyboardFrame.size.height
        UIView.animateWithDuration(0.35, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
        scrollTableToBottom(withAnimation: true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        toolbarBottomConstraint.constant = 0
        UIView.animateWithDuration(0.35, animations: { () -> Void in
            self.view.layoutIfNeeded()
        })
    }
    
    func zoomImage(image: UIImage) {
        if zoomView == nil {
            view.endEditing(true)
            zoomView = UIImageView(frame: self.view.frame)
            zoomView?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
            zoomView?.contentMode = .ScaleAspectFit
            zoomView?.image = image
            zoomView?.alpha = 0
            
            if let keyWindow = UIApplication.sharedApplication().keyWindow {
                keyWindow.addSubview(self.zoomView!)
                UIView.animateWithDuration(0.5, animations: {
                    self.zoomView?.alpha = 1
                    }) { (complete) -> Void in
                }
            }
        }
    }
    
    func closeImageZoom() {
        if zoomView != nil {
            UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.BeginFromCurrentState, animations: {
                self.zoomView?.alpha = 0
                }) { (complete) -> Void in
                    self.zoomView?.removeFromSuperview()
                    self.zoomView = nil
            }
        }
    }
}

extension ChatViewController:SRWebSocketDelegate {
    
    func socketConnect() {
        socketIO = SRWebSocket(URLRequest: NSURLRequest(URL: NSURL(string: "ws://echo.websocket.org")!))
        socketIO!.delegate = self
        socketIO!.open()
    }
    
    func webSocketDidOpen(webSocket:SRWebSocket){
        print("Websocket Connected");
        socketConnected = true
        updateConnectionLabel()
    }
    
    func webSocket(webSocket:SRWebSocket, didFailWithError error:NSError){
        print("Websocket Failed With Error \(error)");
        socketConnected = false
        updateConnectionLabel()
    }
    
    func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        // All incoming messages ( socket.on() ) are received in this function. Parsed with JSON
        print("Message received: \(message)")
        if let textMessage = message as? String {
            let entity =  NSEntityDescription.entityForName("JCMessage",
                inManagedObjectContext:managedContext)
            let message = NSManagedObject(entity: entity!,
                insertIntoManagedObjectContext: managedContext) as! JCMessage
            message.text = textMessage
            message.timestamp = NSDate()
            message.isSender = false
            message.thread = thread
            
            thread!.messages?.mutableCopy().addObject(message)
            thread!.updatedAt = message.timestamp
            do {
                try managedContext.save()
            } catch let error as NSError  {
                print("Could not save \(error), \(error.userInfo)")
            }
            chatTableView.reloadData()
            chatTextField.text = nil
            
            scrollTableToBottom(withAnimation: true)
        }
    }
    
    func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        print("WebSocket closed")
        socketConnected = false
        updateConnectionLabel()
    }
}

extension ChatViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let messageText = thread?.messages![indexPath.row].text where messageText?.isEmpty == false {
            let rect = self.calculateChatRect(messageText!)
            return rect.height
        } else if let messageImageData = (thread?.messages![indexPath.row] as? JCMessage)?.image {
            let image = UIImage(data: messageImageData)
            return (self.view.frame.size.width/2-20)*(image!.size.height/image!.size.width)
        } else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return thread?.messages?.count ?? 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageTableViewCell", forIndexPath: indexPath) as! MessageTableViewCell
        cell.chatDelegate = self
        cell.addZoomGestureToImage()
        if let message = thread?.messages![indexPath.row] as? JCMessage {
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            if message.isSender == true {
                cell.messageTextView.textAlignment = .Right
                cell.timeStampLabel.textAlignment = .Right
                cell.bubbleImageView.image = UIImage(named: "Right_bubble.png")
                cell.messageLeadingConstraint.active = false
                cell.messageTrailingConstraint.active = true
            } else {
                cell.messageTextView.textAlignment = .Left
                cell.timeStampLabel.textAlignment = .Left
                cell.bubbleImageView.image = UIImage(named: "Left_bubble.png")
                cell.messageLeadingConstraint.active = true
                cell.messageTrailingConstraint.active = false
            }
            if let messageText = message.text {
                let rect = self.calculateChatRect(messageText)
                cell.messageWidthConstraint.constant = rect.width
                cell.messageTextView.text = messageText
                cell.messageTextView.hidden = false
                cell.messageImageView.hidden = true
            } else if let messageImageData = message.image {
                cell.messageWidthConstraint.constant = self.view.frame.size.width/2
                cell.messageImageView?.image = UIImage(data: messageImageData)
                cell.messageTextView.hidden = true
                cell.messageImageView.hidden = false
            }
            cell.timeStampLabel.text = nil
            if let timestamp = message.timestamp {
                if indexPath.row == 0 || (thread?.messages![indexPath.row-1] as! JCMessage).timestamp!.minutesFrom(timestamp) < -5 {
                    cell.timeStampLabel.text = timestamp.stringFromDate()
                }
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        connectionLabel = UILabel()
        connectionLabel!.textAlignment = NSTextAlignment.Center
        connectionLabel!.font = UIFont.italicSystemFontOfSize(13)
        connectionLabel!.textColor = UIColor.whiteColor()
        connectionLabel?.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        
        updateConnectionLabel()
        
        return connectionLabel
    }
    
    func updateConnectionLabel() {
        if socketConnected == true {
            connectionLabel!.text = "Connected."
        } else if socketConnected == false {
            connectionLabel!.text = "Disconnected."
        }
    }
    
    func calculateChatRect(text:String) -> CGRect {
        let style = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        let attributes = [NSFontAttributeName: UIFont.systemFontOfSize(14), NSParagraphStyleAttributeName: style]
        let rect = text.boundingRectWithSize(CGSize(width: UIScreen.mainScreen().bounds.size.width*(2/3), height: CGFloat.max), options: [NSStringDrawingOptions.UsesLineFragmentOrigin, NSStringDrawingOptions.UsesFontLeading], attributes: attributes, context: nil)
        let paddedRect = CGRectMake(0, 0, rect.width+90, rect.height+90)
        return paddedRect
    }
    
    func scrollTableToBottom(withAnimation animated:Bool) {
        if let count = thread?.messages?.count where count > 0 && chatTableView.numberOfRowsInSection(0) > count-1 {
            chatTableView.scrollToRowAtIndexPath(NSIndexPath(forRow: count-1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: animated)
        }
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBAction func addPhoto(sender: AnyObject) {
        let imagePickerActionSheet = UIAlertController(title: "Snap/Upload Photo",
            message: nil, preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            let cameraButton = UIAlertAction(title: "Take Photo",
                style: .Default) { (alert) -> Void in
                    let imagePicker = UIImagePickerController()
                    imagePicker.delegate = self
                    imagePicker.sourceType = .Camera
                    self.presentViewController(imagePicker,
                        animated: true,
                        completion: nil)
            }
            imagePickerActionSheet.addAction(cameraButton)
        }
        
        let libraryButton = UIAlertAction(title: "Choose Existing",
            style: .Default) { (alert) -> Void in
                let imagePicker = UIImagePickerController()
                imagePicker.delegate = self
                imagePicker.sourceType = .PhotoLibrary
                self.presentViewController(imagePicker,
                    animated: true,
                    completion: nil)
        }
        imagePickerActionSheet.addAction(libraryButton)
        
        let cancelButton = UIAlertAction(title: "Cancel",
            style: .Cancel) { (alert) -> Void in
        }
        imagePickerActionSheet.addAction(cancelButton)
        
        presentViewController(imagePickerActionSheet, animated: true,
            completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        if let pickedImage = (info[UIImagePickerControllerOriginalImage] as? UIImage)?.normalizedImage() {
            dismissViewControllerAnimated(true, completion: {
                self.imagePreviewView = ImagePreviewViewController()
                
                if let keyWindow = UIApplication.sharedApplication().keyWindow {
                    keyWindow.addSubview(self.imagePreviewView!.view)
                    
                    self.imagePreviewView?.chatDelegate = self
                    self.imagePreviewView?.previewImageView.image = pickedImage
                    self.imagePreviewView?.topConstraint.constant = self.view.frame.size.height
                    keyWindow.layoutIfNeeded()
                    
                    self.imagePreviewView?.topConstraint.constant = 0
                    UIView.animateWithDuration(0.75, delay: 0.0, usingSpringWithDamping:0.8, initialSpringVelocity:0.0, options: [], animations: { () -> Void in
                        keyWindow.layoutIfNeeded()
                        }) { (complete) -> Void in
                    }
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func sendImage(image:UIImage) {
        closeImagePreview()
        
        let entity =  NSEntityDescription.entityForName("JCMessage",
            inManagedObjectContext:self.managedContext)
        let message = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext: self.managedContext) as! JCMessage
        message.image = UIImagePNGRepresentation(image)
        message.timestamp = NSDate()
        message.isSender = true
        message.thread = self.thread
        
        thread!.messages?.mutableCopy().addObject(message)
        thread!.updatedAt = message.timestamp
        do {
            try self.managedContext.save()
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
        }
        self.chatTableView.reloadData()
        self.chatTextField.text = nil
        
        self.scrollTableToBottom(withAnimation: true)
    }
    
    func closeImagePreview() {
        if let keyWindow = UIApplication.sharedApplication().keyWindow {
            self.imagePreviewView?.topConstraint.constant = self.view.frame.size.height
            UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping:0.8, initialSpringVelocity:0.0, options: [], animations: { () -> Void in
                keyWindow.layoutIfNeeded()
                }) { (complete) -> Void in
                    self.imagePreviewView!.view.removeFromSuperview()
                    self.imagePreviewView = nil
            }
        }
    }
}

extension UIImage {
    
    func normalizedImage() -> UIImage {
        if self.imageOrientation == UIImageOrientation.Up {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        self.drawInRect(rect)
        
        let normalizedImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalizedImage
    }
}

extension NSDate {
    func minutesFrom(date:NSDate) -> Int {
        return NSCalendar.currentCalendar().components(NSCalendarUnit.Minute, fromDate: date, toDate: self, options: []).minute
    }
}