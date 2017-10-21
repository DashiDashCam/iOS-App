//
//  ExportViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/20/17.
//  Copyright © 2017 Dashi. All rights reserved.
//
import UIKit
import AVFoundation
import Photos

class ExportViewController: UIViewController, MediaCollectionDelegateProtocol {
    
    @IBOutlet weak var exportButton:UIButton!
    
    var assets = [PHAsset]()
    var fileUrl:URL?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func selectButtonPressed(sender:AnyObject) {
        
    }
    
    @IBAction func exportButtonPressed(sender:AnyObject) {
        
    }
    
    func mediaSelected(selectedAssets:[String:PHAsset]){
        
    }
    
    
    
    func fileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMddyyhhmmss"
        return formatter.string(from: Date()) + ".mp4"
    }
    
    func presentShareViewForFileAtUrl(url:URL) {
        let controller = UIActivityViewController.init(activityItems: [url],
                                                       applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
    }
    
    
    func fetchAsset(){
        PhotoManager().fetchAssetsFromLibrary { (success, assets) in
            if success {
                self.assets = assets!
                self.performSegue(withIdentifier: "mediaPicker", sender: nil)
            }
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mediaPicker" {
            let picker = segue.destination as! MediaCollectionViewController
            picker.delegate = self
            picker.assets = self.assets
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
