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

class HomeViewController: UIViewController, loggedIn {
   var isLoggedIn=false
    func initialSetup() {
        isLoggedIn=true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
         self.performSegue(withIdentifier: "loginSegue", sender: self)

        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
    }
    override func viewDidAppear(_ animated: Bool) {
       /* if(!isLoggedIn){
        self.performSegue(withIdentifier: "loginSegue", sender: self)
        }*/
    }
}
