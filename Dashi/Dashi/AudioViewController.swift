//
//  ViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/20/17.
//  Copyright © 2017 Dashi. All rights reserved.
//
import UIKit
import AVFoundation

class AudioViewController: UIViewController {

    @IBOutlet weak var recordButton:UIButton!
    @IBOutlet weak var playButton:UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func recordButtonPressed(sender:AnyObject) {
        
    }
    
    @IBAction func playButtonPressed(sender:AnyObject) {

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
