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
import SVGKit

class HomeViewController: UIViewController {
    @IBOutlet weak var starttrip: UIImageView!
    @IBOutlet weak var previoustrips: UIImageView!
    @IBOutlet weak var settings: UIImageView!
    @IBOutlet weak var logout: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Login automatically with stored refresh token if one exists
        if DashiAPI.fetchStoredRefreshToken() {
            DashiAPI.loginWithToken().then { _ -> Void in
                print("Authenticated with stored refresh token")
            }
        } else {
            performSegue(withIdentifier: "loginSegue", sender: self)
        }

        // hide navigation bar
        navigationController?.isNavigationBarHidden = true

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)

        // start trip icon
        var namSvgImgVar: SVGKImage = SVGKImage(named: "start trip")
        starttrip.image = namSvgImgVar.uiImage

        // previous trips icon
        namSvgImgVar = SVGKImage(named: "history")
        previoustrips.image = namSvgImgVar.uiImage

        // settings icon
        namSvgImgVar = SVGKImage(named: "settings")
        settings.image = namSvgImgVar.uiImage

        // logout icon
        namSvgImgVar = SVGKImage(named: "exit")
        logout.image = namSvgImgVar.uiImage
    }

    @IBAction func unwindToMenu(segue _: UIStoryboardSegue) {}

    @IBAction func logout(_: Any) {
        DashiAPI.logout().then { val -> Void in
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

    override func viewWillDisappear(_: Bool) {
        navigationController?.isNavigationBarHidden = false
    }
}
