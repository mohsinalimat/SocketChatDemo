//
//  ImgDocumentOpenViewController.swift
//  ChatDemo
//
//  Created by Ravi Patel on 02/08/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import UIKit
import WebKit

class ImgDocumentOpenViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    var imgDocUrl : String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.load(URLRequest(url: URL(string: imgDocUrl!)!))// for web URL

    }

}
