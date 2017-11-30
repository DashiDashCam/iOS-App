//
//  LoginViewController.swift
//  Dashi
//
//  Created by Arslan Memon on 11/5/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
protocol loggedIn {
    func initialSetup()
}

class LoginViewController: UIViewController {
    var delegate: loggedIn?
    @IBOutlet weak var usernameLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPushed(_: Any) {
        dismiss(animated: true, completion: nil)
        delegate?.initialSetup()
    }

    override func willTransition(to _: UITraitCollection, with _: UIViewControllerTransitionCoordinator) {

        for constraint in view.constraints {
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                if constraint.identifier == "usernameLabelMarginTop" {
                    constraint.constant = 10
                }
            } else {
                if constraint.identifier == "usernameLabelMarginTop" {
                    constraint.constant = 45
                }
            }
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
