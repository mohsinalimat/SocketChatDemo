//
//  Extensions.swift
//  ChatDemo
//
//  Created by Vishal's iMac on 18/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    @IBInspectable
    var cornerRadiusView: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable
    var viewBorderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    @IBInspectable
    var viewBorderColor: UIColor {
        get {
            return self.viewBorderColor
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var ShadowColor:UIColor{
        get{
            return self.ShadowColor
        }
        set{
            self.layer.shadowColor = newValue.cgColor
            
        }
    }
    @IBInspectable var ShadowOffSet:CGSize{
        get{
            return self.ShadowOffSet
        }
        set{
            self.layer.shadowOffset = newValue
            
        }
    }
    @IBInspectable var ShadowOppacity:CGFloat{
        get{
            return self.ShadowOppacity
        }
        set{
            self.layer.shadowOpacity = Float(newValue)
            
        }
    }
    @IBInspectable var ShadowRadius:CGFloat{
        get{
            return self.ShadowRadius
        }
        set{
            self.layer.shadowRadius = newValue
            
        }
    }
    @IBInspectable var MaskToBound:Bool{
        get{
            return self.MaskToBound
        }
        set{
            self.layer.masksToBounds = newValue
            
        }
    }
}
extension String{
    func getLocalTime() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        
        let timeUTC = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "h:mm a"
        
        if timeUTC != nil {
            dateFormatter.timeZone = NSTimeZone.local
            
            let localTime = dateFormatter.string(from: timeUTC!)
            return localTime
        }
        return nil
    }
}
extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
