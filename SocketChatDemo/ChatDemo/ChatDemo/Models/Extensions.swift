//
//  Extensions.swift
//  ChatDemo
//
//  Created by Vishal's iMac on 18/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MobileCoreServices

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
    func mimeTypeForPath() -> String {
        if self != "" {
            let url = URL(fileURLWithPath: self)
            let pathExtension = url.pathExtension
            if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue() {
                if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                    return mimetype as String
                }
            }
        }
        return "application/octet-stream"
    }

    func getLocalTime() -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm a"
        
        
        let timeUTC = dateFormatter.date(from: self)
        dateFormatter.dateFormat = "h:mm a"
        
        if timeUTC != nil {
            dateFormatter.timeZone = NSTimeZone.local
            
            let localTime = dateFormatter.string(from: timeUTC!)
            return localTime
        }
        return nil
    }
    
    func timeStampToLocalDate() -> String {
        let now = Date.init(milliseconds: Int64(Double(self)!))
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd hh:mm a"
        let dateString = formatter.string(from: now)
        return dateString
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

public extension CodingUserInfoKey {
    // Helper property to retrieve the context
    static let managedObjectContext = CodingUserInfoKey(rawValue: "managedObjectContext")
}
extension OutputStream {
    @discardableResult
    func write(_ string: String) -> Int {
        guard let data = string.data(using: .utf8) else { return -1 }
        return data.withUnsafeBytes { (buffer: UnsafePointer<UInt8>) -> Int in
            write(buffer, maxLength: data.count)
        }
    }
    
    @discardableResult
    func append(contentsOf url: URL) -> Int {
        guard let inputStream = InputStream(url: url) else { return -1 }
        inputStream.open()
        let bufferSize = 1_024 * 1_024
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        var bytes = 0
        var totalBytes = 0
        
        repeat {
            bytes = inputStream.read(&buffer, maxLength: bufferSize)
            if bytes > 0 {
                write(buffer, maxLength: bytes)
                totalBytes += bytes
            }
        } while bytes > 0
        
        inputStream.close()
        
        return bytes < 0 ? bytes : totalBytes
    }
}
extension FileManager {
    func clearTmpDirectory() {
        do {
            let tmpDirURL = FileManager.default.temporaryDirectory
            let tmpDirectory = try contentsOfDirectory(atPath: tmpDirURL.path)
            try tmpDirectory.forEach { file in
                let fileUrl = tmpDirURL.appendingPathComponent(file)
                try removeItem(atPath: fileUrl.path)
            }
        } catch {
            //catch the error somehow
        }
    }
    
}
func saveImageIntoDocumentDirectory(_ chosenImage:UIImage) -> String? {
    let fileManager = FileManager.default
    do {
        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
        let fileURL = documentDirectory.appendingPathComponent(UUID().uuidString + ".jpeg")
        let data = chosenImage.jpegData(compressionQuality: 0.1)
        try! data?.write(to: fileURL, options: .atomic)
        return fileURL.path
    }catch{
        return nil
    }
}
