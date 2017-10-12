//
//  ViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/12/17.
//  Copyright © 2017 Eric Smith. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var captureSession: AVCaptureSession? // helps transfer data between one or more device inputs like mic or camera
    var videoPreviewLayer: AVCaptureVideoPreviewLayer? // helps render the camera view finder in ViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // initialize a
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            // Initialize the captureSession object
            captureSession = AVCaptureSession()
            
            // Set the input devcie on the capture session
            captureSession?.addInput(input)
            
            //Initialise the video preview layer and add it as a sublayer to the viewPreview view's layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            videoPreviewLayer?.frame = view.layer.bounds
            previewView.layer.addSublayer(videoPreviewLayer!)
            
            // start video capture
            captureSession?.startRunning()
            
        } catch {
            print(error)
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBOutlet weak var previewView: UIView!
    
}

