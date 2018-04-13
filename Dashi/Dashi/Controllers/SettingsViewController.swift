//
//  SettingsViewController.swift
//  Dashi
//
//  Created by Michael Gilbert on 3/22/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia
import CoreLocation

class SettingsViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    @IBOutlet weak var autoDeleteSwitch: UISwitch!
    @IBOutlet weak var wifiOnlyBackupSwitch: UISwitch!
    @IBOutlet weak var autoBackupSwitch: UISwitch!
    
    @IBAction func autoDeleteChanged(_ sender: Any) {
        settings["autoDelete"] = autoDeleteSwitch.isOn
    }
    
    @IBAction func wifiOnlyChanged(_ sender: Any) {
        settings["wifiOnlyBackup"] = wifiOnlyBackupSwitch.isOn
    }
    @IBAction func autoBackupChanged(_ sender: Any) {
        settings["autoBackup"] = autoBackupSwitch.isOn
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if(pickerView == retentionLocal){
            return retentionLocalSource.count
        }
        else if(pickerView == storageLocal){
            return storageLocalSource.count
        }
        else if(pickerView == retentionCloud){
            return retentionCloudSource.count
        }
        else{
            return 0
        }
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if(pickerView == retentionLocal){
            if(retentionLocalSource[row] == "No Limit"){
                settings["localRetentionTime"] = -1
            }
            else{
                settings["localRetentionTime"] = Int(retentionLocalSource[row].split(separator: " ")[0])
            }
        }
        else if(pickerView == storageLocal){
            if(storageLocalSource[row] == "Max Available"){
                settings["maxLocalStorage"] = -1
            }
            else{
                settings["maxLocalStorage"] = Int(storageLocalSource[row].split(separator: " ")[0])
            }
        }
        else if(pickerView == retentionCloud){
            if(retentionCloudSource[row] == "No Limit"){
                settings["cloudRetentionTime"] = -1
            }
            else{
                settings["cloudRetentionTime"] = Int(retentionCloudSource[row].split(separator: " ")[0])
            }
           
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if(pickerView == retentionLocal){
            return retentionLocalSource[row]
        }
        else if(pickerView == storageLocal){
            return storageLocalSource[row]
        }
        else if(pickerView == retentionCloud){
            return retentionCloudSource[row]
        }
        else{
            return ""
        }
    }
    
    @IBOutlet weak var retentionLocal: UIPickerView!
    @IBOutlet weak var storageLocal: UIPickerView!
    @IBOutlet weak var retentionCloud: UIPickerView!
    
    var retentionLocalSource: [String] = [String]()
    var storageLocalSource: [String] = [String]()
    var retentionCloudSource: [String] = [String]()
    var settings: Dictionary<String, Any> = [:]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = false;
        
        //connect pickers to view
        retentionLocal.delegate = self
        retentionLocal.dataSource = self
        retentionCloud.delegate = self
        retentionCloud.dataSource = self
        storageLocal.delegate = self
        storageLocal.dataSource = self
        
        retentionCloudSource = ["30 days","60 days", "90 days", "No Limit"]
        storageLocalSource = ["5 GB","10 GB", "15 GB", "20 GB", "Max Available"]
        retentionLocalSource = ["7 days", "14 days", "30 days", "No Limit"]
       
        settings = (sharedAccount?.getSettings())!
        self.autoBackupSwitch.isOn = settings["autoBackup"] as! Bool
        self.autoDeleteSwitch.isOn = settings["autoDelete"] as! Bool
        self.wifiOnlyBackupSwitch.isOn = settings["wifiOnlyBackup"] as! Bool
       let locRetent = settings["localRetentionTime"] as! Int
        let cloudRetent = settings["cloudRetentionTime"] as! Int
        let maxLocStorage = settings["maxLocalStorage"] as! Int
        if locRetent ==  -1 {
            retentionLocal.selectRow(retentionLocalSource.index(of: "No Limit")!, inComponent: 0, animated: true)
        }
        else {
          retentionLocal.selectRow(retentionLocalSource.index(of: String(locRetent) + " days")!, inComponent: 0, animated: true)
        }
        
        if cloudRetent ==  -1 {
            retentionCloud.selectRow(retentionCloudSource.index(of: "No Limit")!, inComponent: 0, animated: true)
        }
        else {
            retentionCloud.selectRow(retentionCloudSource.index(of: String(cloudRetent) + " days")!, inComponent: 0, animated: true)
        }
        
        if maxLocStorage ==  -1 {
            storageLocal.selectRow(storageLocalSource.index(of: "Max Available")!, inComponent: 0, animated: true)
        }
        else {
            storageLocal.selectRow(storageLocalSource.index(of: String(maxLocStorage) + " GB")!, inComponent: 0, animated: true)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        sharedAccount?.updateSettingsVariables(settings: settings)
        sharedAccount?.saveCurrentSettingLocally()
    }
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    }
    
}
