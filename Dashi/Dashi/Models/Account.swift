//
//  Account.swift
//  Dashi
//
//  Created by Chris Henk on 1/25/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CoreData
import PromiseKit

var sharedAccount: Account?

class Account {

    // Protected members
    var created: Date
    var id: Int
    var wifiOnlyBackup: Bool
    var maxLocalStorage: Int
    var localRetentionTime: Int
    var cloudRetentionTime: Int
    var autoDelete: Bool
    var autoBackup: Bool
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var managedContext: NSManagedObjectContext

    // Public members
    public var fullName: String
    public var email: String

    init(account: JSON) {
        managedContext = (appDelegate?.persistentContainer.viewContext)!
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Settings")
        fullName = account["fullName"].stringValue
        created = DateConv.toDate(timestamp: account["created"].stringValue)
        id = account["id"].intValue
        email = account["email"].stringValue
        fetchRequest.predicate = NSPredicate(format: "accountID == %d", id)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        if result.isEmpty {
            wifiOnlyBackup = true
            maxLocalStorage = 5
            localRetentionTime = 7
            cloudRetentionTime = 30
            autoDelete = true
            autoBackup = true
            initializeSettings()
            initializeMetaData()
        } else {
            wifiOnlyBackup = result[0].value(forKeyPath: "wifiOnlyBackup") as! Bool
            maxLocalStorage = result[0].value(forKeyPath: "maxLocalStorage") as! Int
            localRetentionTime = result[0].value(forKeyPath: "localRetentionTime") as! Int
            cloudRetentionTime = result[0].value(forKeyPath: "cloudRetentionTime") as! Int
            autoDelete = result[0].value(forKeyPath: "autoDelete") as! Bool
            autoBackup = result[0].value(forKeyPath: "autoBackup") as! Bool
        }
    }

    func initializeSettings() {
        let entity =
            NSEntityDescription.entity(forEntityName: "Settings",
                                       in: managedContext)!
        let setting = NSManagedObject(entity: entity,
                                      insertInto: managedContext)
        setting.setValue(wifiOnlyBackup, forKey: "wifiOnlyBackup")
        setting.setValue(id, forKey: "accountID")
        setting.setValue(maxLocalStorage, forKey: "maxLocalStorage")
        setting.setValue(localRetentionTime, forKey: "localRetentionTime")
        setting.setValue(cloudRetentionTime, forKey: "cloudRetentionTime")
        setting.setValue(autoBackup, forKey: "autoBackup")
        setting.setValue(autoDelete, forKey: "autoDelete")
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    public func updateSettingsVariables(settings: Dictionary<String, Any>) {
        wifiOnlyBackup = settings["wifiOnlyBackup"] as! Bool
        maxLocalStorage = settings["maxLocalStorage"] as! Int
        localRetentionTime = settings["localRetentionTime"] as! Int
        cloudRetentionTime = settings["cloudRetentionTime"] as! Int
        autoBackup = settings["autoBackup"] as! Bool
        autoDelete = settings["autoDelete"] as! Bool
    }

    public func saveCurrentSettingLocally() {
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Settings")
        fetchRequest.predicate = NSPredicate(format: "accountID == %d", id)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let setting = result[0]

        setting.setValue(wifiOnlyBackup, forKey: "wifiOnlyBackup")
        setting.setValue(id, forKey: "accountID")
        setting.setValue(maxLocalStorage, forKey: "maxLocalStorage")
        setting.setValue(localRetentionTime, forKey: "localRetentionTime")
        setting.setValue(cloudRetentionTime, forKey: "cloudRetentionTime")
        setting.setValue(autoBackup, forKey: "autoBackup")
        setting.setValue(autoDelete, forKey: "autoDelete")
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    public func toParameters() -> Parameters {
        let parameters: Parameters = [
            "id": self.id,
            "fullName": self.fullName,
            "email": self.email,
        ]
        return parameters
    }

    public func getCreated() -> Date {
        return created
    }

    public func getId() -> Int {
        return id
    }

    func initializeMetaData() {
        let entity =
            NSEntityDescription.entity(forEntityName: "Videos",
                                       in: managedContext)!

        DashiAPI.getAllVideoMetaData().then { value -> Void in
            for currentVideo in value {
                let video = NSManagedObject(entity: entity,
                                            insertInto: self.managedContext)
                video.setValue(self.id, forKey: "accountID")
                video.setValue(currentVideo.getId(), forKeyPath: "id")
                video.setValue(currentVideo.getStarted(), forKeyPath: "startDate")
                video.setValue(currentVideo.getImageContent(), forKey: "thumbnail")
                video.setValue(currentVideo.getLength(), forKeyPath: "length")
                video.setValue(currentVideo.getSize(), forKey: "size")
                video.setValue(currentVideo.getStartLat(), forKey: "startLat")
                video.setValue(currentVideo.getStartLong(), forKey: "startLong")
                video.setValue(currentVideo.getEndLat(), forKey: "endLat")
                video.setValue(currentVideo.getEndLong(), forKey: "endLong")
                video.setValue(100, forKey: "uploadProgress")
                video.setValue("cloud", forKey: "storageStat")
                video.setValue(0, forKey: "downloadProgress")
                
                do {
                    try self.managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        }.catch {
            error in
            print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)
        }
    }

    public func getSettings() -> Dictionary<String, Any> {
        let settings = [
            "wifiOnlyBackup": wifiOnlyBackup,
            "maxLocalStorage": maxLocalStorage,
            "localRetentionTime": localRetentionTime,
            "cloudRetentionTime": cloudRetentionTime,
            "autoBackup": autoBackup,
            "autoDelete": autoDelete,
        ] as [String: Any]
        return settings
    }
}
