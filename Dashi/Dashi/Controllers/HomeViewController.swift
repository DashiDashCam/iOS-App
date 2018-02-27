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
import PromiseKit
class HomeViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // Login automatically with stored refresh token if one exists
        if DashiAPI.fetchStoredRefreshToken() {
            DashiAPI.loginWithToken().then { value -> Void in
                print("Authenticated with stored refresh token")
            }
        }
        else {
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }

        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
    }

    @IBAction func unwindToMenu(segue _: UIStoryboardSegue) {}

    @IBAction func logout(_ sender: Any) {
        DashiAPI.logout().then{val -> Void in
            print(val)
            self.performSegue(withIdentifier: "loginSegue", sender: self)
        }
    }
    override func viewWillAppear(_: Bool) {
        navigationController?.isNavigationBarHidden = true

        /* if(!isLoggedIn){
         self.performSegue(withIdentifier: "loginSegue", sender: self)
         }*/
    }
}
