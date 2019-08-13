//
//  BroadcastListVC.swift
//  ChatDemo
//
//  Created by Ravi Patel on 07/08/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import CoreData
import SDWebImage

class BroadcastListCell : UITableViewCell{
    
    @IBOutlet weak var imgBroadcastList: UIImageView!
    @IBOutlet weak var lblBroadcastName : UILabel!
    @IBOutlet weak var lblBroadcastRecepient : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
    }
}
class BroadcastListVC: UIViewController {

    @IBOutlet weak var broadcastTableView: UITableView!
    
    var channelType : String?
    var broadcastList : [ChatList]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.broadcastTableView.tableFooterView = UIView.init()
        self.checkDataAvailable()
    }
    @IBAction func btnBackAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnUserListAction(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "BroadcastListSegue", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? UserListViewController{
            destination.channelType = channelType
            
        }else if let destinatation = segue.destination as? ChatViewController{
            destinatation.chatObj = sender as? ChatList
        }else{}
        
    }
    func checkDataAvailable(){
        do{
            let context = appdelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatList")
            fetchRequest.predicate = NSPredicate(format: "channelType == '\(channelTypeCase.broadcast.rawValue)'")
            if let dataArray = try context.fetch(fetchRequest) as? [ChatList]{
                if dataArray.count == 0{
                    
                }else{
                    self.broadcastList = dataArray
                    self.broadcastTableView.reloadData()
                }
            }
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
}
extension BroadcastListVC : UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return broadcastList?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BroadcastListCell") as! BroadcastListCell
        let dictobj = self.broadcastList?[indexPath.row]
        
        cell.lblBroadcastName.text = dictobj?.channelName
        cell.lblBroadcastRecepient.text = dictobj?.last_message
        cell.imgBroadcastList.sd_setImage(with: URL.init(string: dictobj?.channelPic ?? ""), placeholderImage: #imageLiteral(resourceName: "user"))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let obj = broadcastList?[indexPath.row]
        performSegue(withIdentifier: "ChatConversation", sender: obj)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
}
