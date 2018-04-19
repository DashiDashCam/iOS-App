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
    @IBOutlet weak var errorMessage: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateConstraints()

        // Do any additional setup after loading the view.

        // done button above keyboard
        let toolBar = UIToolbar()
        toolBar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(self.doneClicked))

        toolBar.setItems([doneButton], animated: true)

        email.inputAccessoryView = toolBar
        password.inputAccessoryView = toolBar

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)
    }

    @objc func doneClicked() {
        view.endEditing(true)
    }

    override func viewWillAppear(_: Bool) {
        navigationController?.isNavigationBarHidden = true
    }

    override func viewWillDisappear(_: Bool) {
        navigationController?.isNavigationBarHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginPushed(_: Any) {
        // hide keyboard
        doneClicked()

        errorMessage.text = ""
        DashiAPI.loginWithPassword(username: email.text!, password: password.text!).then { json -> Void in
            if json["error"] == JSON.null {
                self.dismiss(animated: true, completion: nil)
            }

        }.catch { error in
            if let e = error as? DashiServiceError {
                // prints a more detailed error message from slim
                //                print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)

                print(e.statusCode)
                print(JSON(e.body))
                let json = JSON(e.body)
                if json["errors"].array != nil {
                    self.errorMessage.text = json["errors"].arrayValue[0]["message"].string
                } else {
                    self.errorMessage.text = json["errors"]["message"].string
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
