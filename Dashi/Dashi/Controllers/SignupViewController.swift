//
//  SignupViewController.swift
//  Dashi
//
//  Created by Arslan Memon on 11/5/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
import PromiseKit
import SwiftyJSON

class SignupViewController: UIViewController {

    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var confirm: UITextField!
    @IBOutlet weak var signUpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraints()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signUpPushed(_: Any) {
        if password.text! == confirm.text! {
            DashiAPI.createAccount(email: email.text!, password: password.text!, fullName: name.text!).then { _ -> Void in
                self.performSegue(withIdentifier: "unwindFromSignUp", sender: self)
            }.catch { error in
                if let e = error as? DashiServiceError {
                    print(e.statusCode)
                    print(JSON(e.body))
                }
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
                // margin above sign up button
                if constraint.identifier == "signUpMarginTop" {
                    constraint.constant = 0
                    signUpButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
                }
            } else {
                // margin above sign up button
                if constraint.identifier == "signUpMarginTop" {
                    constraint.constant = 20
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

extension SignupViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case name:
            email.becomeFirstResponder()
        case email:
            password.becomeFirstResponder()
        case password:
            confirm.becomeFirstResponder()
        default:
            confirm.resignFirstResponder()
        }

        return true
    }
}
