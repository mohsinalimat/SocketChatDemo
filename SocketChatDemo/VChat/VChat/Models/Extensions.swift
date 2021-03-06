//
//  Extensions.swift
//  ChatDemo
//
//  Created by Vishal's iMac on 18/07/19.
//  Copyright © 2019 vishal. All rights reserved.
//

import Foundation
import CoreData
import AVFoundation
import AVKit

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
    func clearDocumentDirectory() {
        let fileManager = FileManager.default
        let myDocuments = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            try fileManager.removeItem(at: myDocuments)
            self.clearTmpDirectory()
        } catch {
            return
        }
    }
}
//func saveImageIntoDocumentDirectory(_ chosenImage:NSImage) -> String? {
//    let fileManager = FileManager.default
//    do {
//        let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor:nil, create:false)
//        let fileURL = documentDirectory.appendingPathComponent(UUID().uuidString + ".jpeg")
//        let data = chosenImage.jpegData(compressionQuality: 0.1)
//        try data?.write(to: fileURL, options: .atomic)
//        return fileURL.path
//    }catch{
//        return nil
//    }
//}

extension String {
    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}


extension UserDefaults {
    var userID : Int64? {
        get{
            return self.value(forKey: "userID") as? Int64 ?? nil
        }
        set {
            self.set(newValue, forKey: "userID")
        }
    }
    var userName : String? {
        get{
            return self.value(forKey: "userName") as? String ?? nil
        }
        set {
            self.set(newValue, forKey: "userName")
        }
    }
    var userPhoto : String? {
        get{
            return self.value(forKey: "userPhoto") as? String ?? nil
        }
        set {
            self.set(newValue, forKey: "userPhoto")
        }
    }
}

extension Array {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}

extension Dictionary {
    func toData() throws -> Data {
        return try JSONSerialization.data(withJSONObject: self, options: JSONSerialization.WritingOptions(rawValue: 0))
    }
}
extension AVAsset {
    func generateThumbnail(completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.global().async {
            let imageGenerator = AVAssetImageGenerator(asset: self)
            imageGenerator.appliesPreferredTrackTransform = true
            let time = CMTime(seconds: 0.0, preferredTimescale: 600)
            let times = [NSValue(time: time)]
            imageGenerator.generateCGImagesAsynchronously(forTimes: times, completionHandler: { _, image, _, _, _ in
                if let image = image {
                    completion(NSImage.init(cgImage: image, size: NSSize.init(width: 200, height: 200)))
                } else {
                    completion(nil)
                }
            })
        }
    }
}

func clearDeepObjectEntity(_ entity: String) throws {
    let context = appdelegate.persistentContainer.viewContext
    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
    try context.execute(deleteRequest)
    appdelegate.saveContext()
}

func getCurrentDateTime() -> String{
    let dateFormatter : DateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let date = Date()
    return dateFormatter.string(from: date)
}

func moveFile(filepath : URL) -> URL? {
    if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
        let oldPath = filepath
        let newPath = dir.appendingPathComponent(filepath.lastPathComponent)
        let fileManager = FileManager.default
        do{
            if fileManager.fileExists(atPath: newPath.path) {
                try fileManager.removeItem(at: newPath)
            }
            
            try fileManager.copyItem(at: oldPath, to: newPath)
            return newPath
        }catch{
            print(error.localizedDescription)
            return nil
        }
    }
    return nil
}

enum channelTypeCase : String{
        case privateChat = "1"
        case group = "2"
        case broadcast = "3"
}

extension NSTableView{
    func scrollToBottom(index : Int){
        DispatchQueue.main.async {
            if index > 0{
                self.scrollRowToVisible(index)
            }
        }
    }
}


extension NSBox {
    @IBInspectable
    var cornerRadiusView: CGFloat {
        get {
            return self.layer?.cornerRadius ?? 5.0
        }
        set {
            self.layer?.cornerRadius = newValue
            self.layer?.masksToBounds = newValue > 0
        }
    }
}
