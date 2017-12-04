//
//  SignupViewController.swift
//  Dashi
//
//  Created by Arslan Memon on 11/5/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
import Alamofire
class SignupViewController: UIViewController {

    @IBOutlet weak var username: UITextField!
    @IBOutlet weak var email: UITextField!
    @IBOutlet var password: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func signUpPushed(_ sender: Any) {
        Alamofire.request(URL(string: "http://api.dashidashcam.com/Accounts")!,
                          method: .post,
                          parameters: ["email": email.text!,
                                       "password": password.text!])
            .responseJSON { response in
                
                if let JSON = response.result.value {
                    self.dismiss(animated: true, completion: nil)
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
