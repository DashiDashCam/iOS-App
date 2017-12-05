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
    var isLoggedIn = false
    func initialSetup() {
        isLoggedIn = true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        performSegue(withIdentifier: "loginSegue", sender: self)

        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.isNavigationBarHidden = true
    }

    // updates the hardcoded contraints associated with this view
    func updateConstraints() {
        // loop through view constraints
        for constraint in view.constraints {
            // the device is in landscape
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                //
                if constraint.identifier == "loginMarginTop" {
                    constraint.constant = 0
                }
            } else {
                //
                if constraint.identifier == "signUpMarginTop" {
                    constraint.constant = 20
                }
            }
        }
    }
}
