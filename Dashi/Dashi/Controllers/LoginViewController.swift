//
//  LoginViewController.swift
//  Dashi
//
//  Created by Arslan Memon on 11/5/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftyJSON

class LoginViewController: UIViewController {
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraints()

        if DashiAPI.isLoggedIn() {
            dismiss(animated: true, completion: nil)
        }
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPushed(_: Any) {
        DashiAPI.loginWithPassword(username: email.text!, password: password.text!).then { _ -> Void in

            self.dismiss(animated: true, completion: nil)

        }.catch { error in
            if let e = error as? DashiServiceError {
                print(e.statusCode)
                print(JSON(e.body))
            }
        }
    }

    override func willTransition(to _: UITraitCollection, with _: UIViewControllerTransitionCoordinator) {

        updateConstraints()
    }

    // updates the hardcoded contraints associated with this view
    func updateConstraints() {
        // loop through view constraints
        for constraint in view.constraints {
            // the device is in landscape
            if UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight {
                // "Username" label above input
                if constraint.identifier == "usernameLabelMarginTop" {
                    constraint.constant = 10
                }
            } else {
                // "Username" label above input
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

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case email:
            password.becomeFirstResponder()
        default:
            password.resignFirstResponder()
        }

        return true
    }
}
