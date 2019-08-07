//
//  BroadcastListVC.swift
//  ChatDemo
//
//  Created by Ravi Patel on 07/08/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit


class BroadcastListCell : UITableViewCell{
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.broadcastTableView.tableFooterView = UIView.init()
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
        }
        
    }
}
extension BroadcastListVC : UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BroadcastListCell") as! BroadcastListCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}
