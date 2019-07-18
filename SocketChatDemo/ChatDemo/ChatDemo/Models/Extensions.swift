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
