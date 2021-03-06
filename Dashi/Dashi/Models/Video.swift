//
//  Video.swift
//  Dashi
//
//  Created by Chris Henk on 1/25/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import AVKit
import SwiftyJSON
import Arcane
import CoreLocation
import MapKit
import CoreData

class Video {

    // Protected members
    var asset: AVURLAsset?
    var started: Date
    var length: Int
    var size: Int
    var thumbnail: UIImage!
    var id: String?
    var storageStat: String! // "cloud", "local", or "both"
    var startLat: CLLocationDegrees?
    var endLat: CLLocationDegrees?
    var startLong: CLLocationDegrees?
    var endLong: CLLocationDegrees?
    var uploadProgress: Int!
    var downloadProgress: Int!
    var uploadInProgress: Bool!
    var downloadInProgress: Bool!

    var locationName: String?
    var deleted: Bool! = false
    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate
    var managedContext: NSManagedObjectContext
    /**
     *  Initializes a Video object. Note that ID is initialized
     *  from the SHA256 hash of the content of the video
     */
    init(started: Date, asset: AVURLAsset, startLoc: CLLocationCoordinate2D?, endLoc: CLLocationCoordinate2D?) {
        managedContext = (appDelegate?.persistentContainer.viewContext)!
        do {
            // get the data associated with the video's content and convert it to a string
            let contentData = try Data(contentsOf: asset.url)
            let contentString = String(data: contentData, encoding: String.Encoding.ascii)
            length = Int(Float((asset.duration.value)) / Float((asset.duration.timescale)))
            size = contentData.count
            startLat = startLoc?.latitude
            startLong = startLoc?.longitude
            endLat = endLoc?.latitude
            endLong = endLoc?.longitude
            // hash the video content to produce an ID
            id = Hash.SHA256(contentString!)
            let imgGenerator = AVAssetImageGenerator(asset: asset)

            let cgImage = try! imgGenerator.copyCGImage(at: CMTimeMake(0, 6), actualTime: nil)
            // !! check the error before proceeding
            if UIDevice.current.orientation == .portrait {
                thumbnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: .right)
            } else if UIDevice.current.orientation == .landscapeLeft {
                thumbnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            } else if UIDevice.current.orientation == .landscapeRight {
                thumbnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: .down)
            } else if UIDevice.current.orientation == .portraitUpsideDown {
                thumbnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: .left)
            } else {
                thumbnail = UIImage(cgImage: cgImage, scale: 1.0, orientation: .up)
            }
        } catch let error {
            print("Could not create video object. \(error)")

            self.length = -1
            self.size = -1
        }

        // initialize other instances variables
        self.asset = asset
        self.started = started
    }

    init(video: JSON) {
        managedContext = (appDelegate?.persistentContainer.viewContext)!
        id = video["id"].stringValue
        started = DateConv.toDate(timestamp: video["started"].stringValue)
        length = video["length"].intValue
        size = video["size"].intValue
        thumbnail = UIImage(data: Data(base64Encoded: video["thumbnail"].stringValue)!)
        startLat = video["startLat"].doubleValue
        startLong = video["startLong"].doubleValue
        endLat = video["endLat"].doubleValue
        endLong = video["endLong"].doubleValue
    }

    init(started: Date, imageData: Data, id: String, length: Int, size: Int, startLoc: CLLocationCoordinate2D?, endLoc: CLLocationCoordinate2D?, locationName: String? = "") {
        self.id = id
        self.started = started
        thumbnail = UIImage(data: imageData)
        self.length = length
        self.size = size
        startLat = startLoc?.latitude
        startLong = startLoc?.longitude
        endLat = endLoc?.latitude
        endLong = endLoc?.longitude
        managedContext = (appDelegate?.persistentContainer.viewContext)!
        if let name = locationName{
        self.locationName = name
            
        }
        else{
            if let _ = startLoc, let _ = endLoc{
                setLocation()
            }
        }
    }

    public func getUploadProgress() -> Int {
        updateProgressFromCoreData()
        return uploadProgress
    }

    public func getDownloadProgress() -> Int {
        updateProgressFromCoreData()
        return downloadProgress
    }

    public func getUploadInProgress() -> Bool {
        updateProgressFromCoreData()
        return uploadInProgress
    }

    public func getDownloadInProgress() -> Bool {
        updateProgressFromCoreData()
        return downloadInProgress
    }

    public func getContent() -> Data? {
        do {
            return try Data(contentsOf: asset!.url)
        } catch let error {
            print("Could not get video content. \(error)")
        }

        return nil
    }

    public func getImageContent() -> Data? {
        return UIImageJPEGRepresentation(thumbnail, 0.5)
    }

    public func setAsset(asset: AVURLAsset) {
        self.asset = asset
    }

    public func getAsset() -> AVURLAsset {
        return asset!
    }

    public func getStarted() -> Date {
        return started
    }

    public func getLength() -> Int {
        return length
    }

    public func getSize() -> Int {
        return size
    }

    public func getId() -> String {
        return id!
    }

    public func getThumbnail() -> UIImage {
        return thumbnail
    }

    public func getStorageStat() -> String {
        getStorageStatFromCore()

        return storageStat!
    }

    public func setLocation(){
        if let lat = endLat, let long = endLong{
        let endLoc = CLLocation(latitude: lat, longitude: long)
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(endLoc) { placemarks, error in
            
            if let e = error {
                
                print(e)
                
            } else {
                
                let placeArray = placemarks as [CLPlacemark]!
                
                var placeMark: CLPlacemark!
                
                placeMark = placeArray![0]
                self.updateFieldViaCoreDB(key: "locationName", value: placeMark.locality!)
                DispatchQueue.main.async {
                    
                self.locationName = placeMark.locality!
                }
            }
        }
        }
        
    }
    public func changeStorageToBoth() {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id!, (sharedAccount?.getId())!)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let setting = result[0]

        setting.setValue("both", forKey: "storageStat")

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        storageStat = "both"
    }

    public func getStartLat() -> CLLocationDegrees? {
        return startLat
    }

    public func getStartLong() -> CLLocationDegrees? {
        return startLong
    }

    public func getEndLat() -> CLLocationDegrees? {
        return endLat
    }

    public func getEndLong() -> CLLocationDegrees? {
        return endLong
    }
    
    public func getLocation() -> String{
        if let loc = locationName{
            return loc
        }
        else{
            return ""
        }
    }

    public func wasDeleted() -> Bool {
        var content: [NSManagedObject]
        let managedContext =
            appDelegate?.persistentContainer.viewContext
        
        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["id"]
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id!, (sharedAccount?.getId())!)
        // 3
        do {
            content = (try managedContext?.fetch(fetchRequest))!
            if(content.count > 0){
                return false
            }
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        return true
    }
    
    func getStorageStatFromCore() {
        var content: [NSManagedObject]
        let managedContext =
            appDelegate?.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["storageStat"]
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id!, (sharedAccount?.getId())!)
        // 3
        do {
            content = (try managedContext?.fetch(fetchRequest))!
            storageStat = content[0].value(forKey: "storageStat") as! String
            // print(storageStat)
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
    }

    // gets progress from core data
    func updateProgressFromCoreData() {

        var content: [NSManagedObject]
        let managedContext =
            appDelegate?.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["uploadProgress", "downloadProgress", "uploadInProgress", "downloadInProgress"]
        fetchRequest.predicate = NSPredicate(format: "id == %@", id!)
        // 3
        do {
            content = (try managedContext?.fetch(fetchRequest))!
            var uProg = content[0].value(forKey: "uploadProgress") as? Int
            if uProg == nil {
                uProg = 0
            }
            var dProg = content[0].value(forKey: "downloadProgress") as? Int
            if dProg == nil {
                dProg = 0
            }
            uploadProgress = uProg!
            downloadProgress = dProg!
            uploadInProgress = content[0].value(forKey: "uploadInProgress") as! Bool
            downloadInProgress = content[0].value(forKey: "downloadInProgress") as! Bool
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
    }

    // helper function for converting seconds to hours
    func secondsToHoursMinutesSeconds() -> (Int, Int, Int) {
        return (length / 3600, (length % 3600) / 60, (length % 3600) % 60)
    }

    func updateUploadProgress(progress: Int) {
        updateFieldViaCoreDB(key: "uploadProgress", value: progress)
    }

    func updateUploadInProgress(status: Bool) {
        updateFieldViaCoreDB(key: "uploadInProgress", value: status)
    }

    func updateDownloadProgress(progress: Int) {
        updateFieldViaCoreDB(key: "downloadProgress", value: progress)
    }

    func updateDownloadInProgress(status: Bool) {
        updateFieldViaCoreDB(key: "downloadInProgress", value: status)
    }

    private func updateFieldViaCoreDB(key: String, value: Any) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id!, (sharedAccount?.getId())!)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let video = result[0]

        video.setValue(value, forKey: key)

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
}
