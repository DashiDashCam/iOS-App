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
    @IBOutlet weak var errorMessage: UILabel!

    @IBAction func exitPushed(_: Any) {
        dismiss(animated: true, completion: nil)
        //        performSegue(withIdentifier: "signupSegue", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraints()
        // Do any additional setup after loading the view.

        // done button above keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.doneClicked))

        toolBar.setItems([doneButton], animated: true)

        name.inputAccessoryView = toolBar
        email.inputAccessoryView = toolBar
        password.inputAccessoryView = toolBar
        confirm.inputAccessoryView = toolBar

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)
    }

    @objc func doneClicked() {
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func signUpPushed(_: Any) {
        errorMessage.text = ""
        if password.text! == confirm.text! {
            DashiAPI.createAccount(email: email.text!, password: password.text!, fullName: name.text!).then { _ -> Void in

                DashiAPI.loginWithPassword(username: self.email.text!, password: self.password.text!).then { _ -> Void in
                    self.performSegue(withIdentifier: "unwindFromSignUp", sender: self)
                }

            }.catch { error in
                if let e = error as? DashiServiceError {
                    let json = JSON(e.body)
                    if json["errors"].array != nil {
                        self.errorMessage.text = json["errors"].arrayValue[0]["message"].string
                    } else {
                        self.errorMessage.text = json["errors"]["message"].string
                    }
                }
            }
        } else {
            errorMessage.text = "Password and Confirm Password do not match"
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
