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

class SettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        <#code#>
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        <#code#>
    }
    
    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var retentionLocalPicker: UIPickerView!
    var retentionLocalPickerData: [String] = [String]()
    @IBOutlet weak var storageLocalPicker: UIPickerView!
    var storageLocalPickerData: [String] = [String]()
    @IBOutlet weak var retentionCloudPicker: UIPickerView!
    var retentionCloudPickerData: [String] = [String]()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.hidesBackButton = false;
        
        //connect pickers to data
        //I think this works by associating the picker name
        //with the array (pickerName)Data automatically
        
        self.retentionLocalPicker.delegate = self
        self.retentionLocalPicker.dataSource = self
        
        // create tap gesture recognizer for when user taps thumbnail
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoDetailViewController.imageTapped(gesture:)))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        //         Get the new view controller using segue.destinationViewController.
        //         Pass the selected object to the new view controller.
        let preview = segue.destination as! SettingsViewController
    }
    
}
