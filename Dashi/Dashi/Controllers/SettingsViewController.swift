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

class SettingsViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var autoDeleteSwitch: UISwitch!
    @IBOutlet weak var wifiOnlyBackupSwitch: UISwitch!
    @IBOutlet weak var autoBackupSwitch: UISwitch!
    @IBOutlet weak var wifiOnlyBackupLabel: UILabel!
    
    @IBAction func autoDeleteChanged(_: Any) {
        settings["autoDelete"] = autoDeleteSwitch.isOn
        //retentionLocalDisplay.isEnabled = autoDeleteSwitch.isOn
        //retentionLocalLabel.isEnabled = autoDeleteSwitch.isOn
    }

    @IBAction func wifiOnlyChanged(_: Any) {
        settings["wifiOnlyBackup"] = wifiOnlyBackupSwitch.isOn
    }

    @IBAction func autoBackupChanged(_: Any) {
        settings["autoBackup"] = autoBackupSwitch.isOn
        wifiOnlyBackupSwitch.isEnabled = autoBackupSwitch.isOn
        wifiOnlyBackupLabel.isEnabled = autoBackupSwitch.isOn
    }

    func numberOfComponents(in _: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent _: Int) -> Int {
        if pickerView == retentionLocal {
            return retentionLocalSource.count
        } else if pickerView == storageLocal {
            return storageLocalSource.count
        } else if pickerView == retentionCloud {
            return retentionCloudSource.count
        } else {
            return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent _: Int) {
        if pickerView == retentionLocal {
            retentionLocalDisplay.text = retentionLocalSource[row]
            if retentionLocalSource[row] == "No Limit" {
                settings["localRetentionTime"] = -1
            } else {
                settings["localRetentionTime"] = Int(retentionLocalSource[row].split(separator: " ")[0])
            }
        } else if pickerView == storageLocal {
            storageLocalDisplay.text = storageLocalSource[row]
            if storageLocalSource[row] == "Max Available" {
                settings["maxLocalStorage"] = -1
            } else {
                settings["maxLocalStorage"] = Int(storageLocalSource[row].split(separator: " ")[0])
            }
        } else if pickerView == retentionCloud {
            retentionCloudDisplay.text = retentionCloudSource[row]
            if retentionCloudSource[row] == "No Limit" {
                settings["cloudRetentionTime"] = -1
            } else {
                settings["cloudRetentionTime"] = Int(retentionCloudSource[row].split(separator: " ")[0])
            }
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent _: Int) -> String? {
        if pickerView == retentionLocal {
            return retentionLocalSource[row]
        } else if pickerView == storageLocal {
            return storageLocalSource[row]
        } else if pickerView == retentionCloud {
            return retentionCloudSource[row]
        } else {
            return ""
        }
    }

    @IBOutlet weak var retentionLocalDisplay: UITextField!
    @IBOutlet weak var storageLocalDisplay: UITextField!
    @IBOutlet weak var retentionCloudDisplay: UITextField!

    let retentionLocal = UIPickerView()
    let storageLocal = UIPickerView()
    let retentionCloud = UIPickerView()

    var retentionLocalSource: [String] = [String]()
    var storageLocalSource: [String] = [String]()
    var retentionCloudSource: [String] = [String]()
    var settings: Dictionary<String, Any> = [:]
    override func viewDidLoad() {
        super.viewDidLoad()

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)

        navigationItem.hidesBackButton = false

        // connect pickers to view
        retentionLocal.delegate = self
        retentionLocal.dataSource = self
        retentionCloud.delegate = self
        retentionCloud.dataSource = self
        storageLocal.delegate = self
        storageLocal.dataSource = self

        retentionCloudSource = ["30 days", "60 days", "90 days", "No Limit"]
        storageLocalSource = ["5 GB", "10 GB", "15 GB", "20 GB", "Max Available"]
        retentionLocalSource = ["7 days", "14 days", "30 days", "No Limit"]

        // connect text fields to uipickers
        retentionLocalDisplay.inputView = retentionLocal
        storageLocalDisplay.inputView = storageLocal
        retentionCloudDisplay.inputView = retentionCloud

        // hide cursors on text fields
        retentionLocalDisplay.tintColor = .clear
        storageLocalDisplay.tintColor = .clear
        retentionCloudDisplay.tintColor = .clear

        // add done button to text field input views
        let ViewForDoneButtonOnKeyboard = UIToolbar()
        ViewForDoneButtonOnKeyboard.sizeToFit()
        let btnDoneOnKeyboard = UIBarButtonItem(title: "Done", style: .bordered, target: self, action: #selector(doneBtnFromKeyboardClicked))
        ViewForDoneButtonOnKeyboard.items = [btnDoneOnKeyboard]
        retentionLocalDisplay.inputAccessoryView = ViewForDoneButtonOnKeyboard
        storageLocalDisplay.inputAccessoryView = ViewForDoneButtonOnKeyboard
        retentionCloudDisplay.inputAccessoryView = ViewForDoneButtonOnKeyboard

        settings = (sharedAccount?.getSettings())!
        let autoBackupSwitchValue : Bool = settings["autoBackup"] as! Bool
        autoBackupSwitch.isOn = autoBackupSwitchValue
        autoDeleteSwitch.isOn = settings["autoDelete"] as! Bool
        wifiOnlyBackupSwitch.isOn = settings["wifiOnlyBackup"] as! Bool
        wifiOnlyBackupSwitch.isEnabled = autoBackupSwitchValue
        wifiOnlyBackupLabel.isEnabled = autoBackupSwitchValue
        
        let locRetent = settings["localRetentionTime"] as! Int
        let cloudRetent = settings["cloudRetentionTime"] as! Int
        let maxLocStorage = settings["maxLocalStorage"] as! Int
        if locRetent == -1 {
            retentionLocal.selectRow(retentionLocalSource.index(of: "No Limit")!, inComponent: 0, animated: true)
        } else {
            retentionLocal.selectRow(retentionLocalSource.index(of: String(locRetent) + " days")!, inComponent: 0, animated: true)
        }
        retentionLocalDisplay.text = retentionLocalSource[retentionLocal.selectedRow(inComponent: 0)]

        if cloudRetent == -1 {
            retentionCloud.selectRow(retentionCloudSource.index(of: "No Limit")!, inComponent: 0, animated: true)
        } else {
            retentionCloud.selectRow(retentionCloudSource.index(of: String(cloudRetent) + " days")!, inComponent: 0, animated: true)
        }
        retentionCloudDisplay.text = retentionCloudSource[retentionCloud.selectedRow(inComponent: 0)]

        if maxLocStorage == -1 {
            storageLocal.selectRow(storageLocalSource.index(of: "Max Available")!, inComponent: 0, animated: true)
        } else {
            storageLocal.selectRow(storageLocalSource.index(of: String(maxLocStorage) + " GB")!, inComponent: 0, animated: true)
        }
        storageLocalDisplay.text = storageLocalSource[storageLocal.selectedRow(inComponent: 0)]
    }

    @IBAction func doneBtnFromKeyboardClicked(sender _: Any) {
        print("Done Button Clicked.")
        // close uitextfield inputs
        //too lazy to figure out which one is actually displayed
        // so close them all
        retentionLocalDisplay.endEditing(true)
        storageLocalDisplay.endEditing(true)
        retentionCloudDisplay.endEditing(true)
    }

    override func viewWillDisappear(_: Bool) {
        sharedAccount?.updateSettingsVariables(settings: settings)
        sharedAccount?.saveCurrentSettingLocally()
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    }
}
