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
        
        retentionLocalSource = ["hi","bye"]
        storageLocalSource = ["hi2","bye2"]
        retentionCloudSource = ["hi3","my","bye3"]
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
    }
    
}
