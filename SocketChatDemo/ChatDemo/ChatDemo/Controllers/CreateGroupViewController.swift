//
//  CreateGroupViewController.swift
//  ChatDemo
//
//  Created by vishal on 04/08/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit

class CreateGroupViewController: UIViewController {

    @IBOutlet weak var txtGroupName: UITextField!
    @IBOutlet weak var ImgGroupPic: UIImageView!
    
    @IBOutlet weak var lblNumbersOfParticipants: UILabel!
    @IBOutlet weak var tableParticipants: UITableView!
    var selectedUserList : [LoginUser]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblNumbersOfParticipants.text = "     PARTICIPANTS: \(selectedUserList?.count ?? 0) OF 10"
    }
    
    @IBAction func btnDoneAction(_ sender: UIBarButtonItem) {
        if txtGroupName.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            print("Please enter group name")
        }else{
            self.performSegue(withIdentifier: "ChatConversation", sender: self)
        }
    }
    
    @IBAction func btnBackAction(_ sender: UIBarButtonItem) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnChangeProfilePic(_ sender: UIButton) {
    }
}

extension CreateGroupViewController : UITableViewDelegate,UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.selectedUserList?.count ??  0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell") as! ChatListCell
        let objUser = self.selectedUserList?[indexPath.row]
        cell.lblChatName.text = objUser?.name
        cell.userProfilePic.sd_setImage(with: URL.init(string: objUser?.photo ?? "")!, placeholderImage: #imageLiteral(resourceName: "user"))
        return cell
    }
}
