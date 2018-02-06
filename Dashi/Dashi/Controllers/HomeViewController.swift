//
//  HomeViewController.swift
//  Dashi
//
//  Created by Eric Smith on 11/4/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        performSegue(withIdentifier: "loginSegue", sender: self)

        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
    }
    
    @IBAction func unwindToMenu(segue: UIStoryboardSegue) {}

    override func viewWillAppear(_: Bool) {
        navigationController?.isNavigationBarHidden = true

        /* if(!isLoggedIn){
         self.performSegue(withIdentifier: "loginSegue", sender: self)
         }*/
    }
}
