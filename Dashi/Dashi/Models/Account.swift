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

var sharedAccount: Account? = nil

class Account {
    
    // Protected members
    var created: Date
    var id: Int
    var wifiOnlyBackup: Bool
    var maxLocalStorage:Int
    var localRetentionTime: Int
    var cloudRetentionTime: Int
    var autoDelete: Bool
    var autoBackUp: Bool
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    var managedContext:NSManagedObjectContext
    
    
    // Public members
    public var fullName: String
    public var email: String
    
    init(account: JSON) {
        fullName = account["fullName"].stringValue
        created = DateConv.toDate(timestamp: account["created"].stringValue)
        id = account["id"].intValue
        email = account["email"].stringValue
        
//        var result: [NSManagedObject] = []
//        do {
            managedContext = (appDelegate?.persistentContainer.viewContext)!
//            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Settings")
//            fetchRequest.predicate = NSPredicate(format: "id == %@", id)
//            result = (try managedContext.fetch(fetchRequest))
//        } catch let error as Error {
//            print("Could not fetch. \(error), \(error.localizedDescription)")
//        }
//        if result.isEmpty{
            wifiOnlyBackup = true
            maxLocalStorage = 5;
            localRetentionTime = 7;
            cloudRetentionTime = 30;
            autoDelete = true;
            autoBackUp = true;
//            initializeSettings()
//        }
//        else{
//             wifiOnlyBackup = result[0].value(forKeyPath: "wifiOnlyBackup") as! Bool
//             maxLocalStorage = result[0].value(forKeyPath: "maxLocalStorage") as! Int
//             localRetentionTime = result[0].value(forKeyPath: "localRetentionTime") as! Int
//             cloudRetentionTime = result[0].value(forKeyPath: "cloudRetentionTime") as! Int
//             autoDelete = result[0].value(forKeyPath: "autoDelete") as! Bool
//             autoBackUp = result[0].value(forKeyPath: "autoBackUp") as! Bool
//        }
    }
    func initializeSettings(){
        let entity =
            NSEntityDescription.entity(forEntityName: "Settings",
                                       in: managedContext)!
        let setting = NSManagedObject(entity: entity,
                                    insertInto: managedContext)
        setting.setValue(wifiOnlyBackup, forKey: "wifiOnlyBackup")
        setting.setValue(id, forKey: "id")
        setting.setValue(maxLocalStorage, forKey: "maxLocalStorage")
        setting.setValue(localRetentionTime, forKey: "localRetentionTime")
        setting.setValue(cloudRetentionTime, forKey: "cloudRetentionTime")
        setting.setValue(autoBackUp, forKey: "autoBackUp")
        setting.setValue(autoDelete, forKey: "autoDelete")
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    public func saveCurrentSettingLocally(){
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Settings")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let setting = result[0]
        
        setting.setValue(wifiOnlyBackup, forKey: "wifiOnlyBackup")
        setting.setValue(id, forKey: "id")
        setting.setValue(maxLocalStorage, forKey: "maxLocalStorage")
        setting.setValue(localRetentionTime, forKey: "localRetentionTime")
        setting.setValue(cloudRetentionTime, forKey: "cloudRetentionTime")
        setting.setValue(autoBackUp, forKey: "autoBackUp")
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
    
    public func getSettings() -> Dictionary<String, Any>{
        let settings = [
            "wifiOnlyBackup": wifiOnlyBackup,
            "maxLocalStorage":maxLocalStorage,
            "localRetentionTime":localRetentionTime,
            "cloudRetentionTime":cloudRetentionTime,
            "autoBackUp":autoBackUp,
            "autoDelete": autoDelete] as [String : Any]
        return settings
    }
}
