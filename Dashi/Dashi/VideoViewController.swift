//
//  VideoViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/20/17.
//  Copyright © 2017 Dashi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreMedia

class VideoViewController: UIViewController,  AVCaptureFileOutputRecordingDelegate {
    
    
    @IBOutlet weak var previewView:UIView! // displays capture stream
    @IBOutlet weak var recordButton:UIButton! // stop/start recording
    @IBOutlet weak var toggleButton:UIButton! // switch camera
    
    let captureSession = AVCaptureSession()
    var videoCaptureDevice:AVCaptureDevice?
    var previewLayer:AVCaptureVideoPreviewLayer?
    var movieFileOutput = AVCaptureMovieFileOutput()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.initializeCamera()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // adjust the orientation of the preview layer when device changes layout
    override func viewWillLayoutSubviews() {
        self.setVideoOrientation()
    }
    
    // MARK: Button Actions
    
    // stop and start recording based off recording state
    @IBAction func recordVideoButtonPressed(sender:AnyObject) {
        if self.movieFileOutput.isRecording {
            // stop recording
            self.movieFileOutput.stopRecording()
        } else {
            // start recording
            
            // set video orientation of movie file output
            self.movieFileOutput.connection(with: AVMediaType.video)?.videoOrientation = self.videoOrientation()
            
            self.movieFileOutput.maxRecordedDuration = self.maxRecordedDuration()
            
            // start recording
            self.movieFileOutput.startRecording(to: URL(fileURLWithPath:self.videoFileLocation()), // output file
                                                recordingDelegate: self)
        }
        
        self.updateRecordButtonTitle()
    }
    
    @IBAction func cameraTogglePressed(sender:AnyObject) {
        self.switchCameraInput()
    }
    
    // MARK: Main
    func setVideoOrientation() {
        // if the preview layer has a connection
        if let connection = self.previewLayer?.connection {
            // if video orientation is supported, set it based off videoOrientation
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = self.videoOrientation()
                
                // set the frame of the preview based off the dimension of the device
                self.previewLayer?.frame = self.view.bounds
            }
        }
    }
    
    func initializeCamera() {
        self.captureSession.sessionPreset = AVCaptureSession.Preset.high
        
        // query device for all possible input devices
        let discovery = AVCaptureDevice.DiscoverySession.init(
                deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], // default cameras found on all devices
                mediaType: AVMediaType.video, // type of capture allowed
                position: .unspecified // back or front
            ) as AVCaptureDevice.DiscoverySession
        
        // foreach device that was found
        for device in discovery.devices as [AVCaptureDevice] {
            // if the device supports video
            if device.hasMediaType(AVMediaType.video) {
                // if the device is the back camera, set it as the device
                if device.position == AVCaptureDevice.Position.back {
                    self.videoCaptureDevice = device
                }
            }
        }
        
        // check to make sure a device was found
        if videoCaptureDevice != nil {
            do {
                // add the device as the input to the capture session
                try self.captureSession.addInput(AVCaptureDeviceInput(device: self.videoCaptureDevice!))
                
                // if audio is available, add the default device too
                if let audioInput = AVCaptureDevice.default(for: AVMediaType.audio) {
                    try self.captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
                }
                
                // create preview layer
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                
                // set previewView's frame to device's dimensions
                self.previewView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
                
                // add preview layer
                self.previewView.layer.addSublayer(self.previewLayer!)
                self.previewView.layer.frame = self.previewView.frame
                
                // ensure the preview layer will be displayed with correct orientation
                self.setVideoOrientation()
                
                // output of the capture session
                self.captureSession.addOutput(self.movieFileOutput)
                
                // start the capture session!
                self.captureSession.startRunning()
                
            } catch {
                print(error)
            }
        }
    }
    
    /*
     * switches which device camera acts as the input to the captureSession
     * NOTE: When an AVCaptureSession is active, its inputs/outputs can't be modified directly
     * the configuration of the session must be changed and committed
     */
    func switchCameraInput() {
        // unlock the configuration so that it may be modified
        self.captureSession.beginConfiguration()
        
        // existing camera input connection
        var existingConnection: AVCaptureDeviceInput!
        
        // find the device that's currently in use
        for connection in self.captureSession.inputs {
            let input = connection as! AVCaptureDeviceInput
            
            // if the device takes video (only one is allowed)
            if input.device.hasMediaType(AVMediaType.video) {
                existingConnection = input
            }
        }
        
        // remove camera from capture session
        self.captureSession.removeInput(existingConnection)
        
        var newCamera:AVCaptureDevice! // new camera to be added
        
        // determine newCamera based off position of oldCamera
        if let oldCamera = existingConnection {
            if oldCamera.device.position == .back {
                newCamera = self.cameraWithPosition(position: .front)
            } else {
                newCamera = self.cameraWithPosition(position: .back)
            }
        }
        
        var newInput:AVCaptureDeviceInput! // input to be based off newCamera
        
        do {
            // turn the camera into an input
            newInput = try AVCaptureDeviceInput(device: newCamera)
            // add it to the session
            self.captureSession.addInput(newInput)
        } catch {
            print(error)
        }
        
        // close the configuration of the captureSession
        self.captureSession.commitConfiguration()
    }
    
    // MARK: AVCaptureFileOutputDelegate
    
    /*
     * once recording stops, print the file url
     * NOTE: overriding this function allows the VideoViewController
     * to adhere to the delegate protocol: AVCaptureFileOutputRecordingDelegate
     */
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording: \(outputFileURL)")
    }

    // MARK: Helpers
    
    // returns file location in the temporary directory
    func videoFileLocation() -> String {
        return NSTemporaryDirectory().appending("videoFile.mov")
    }
    
    // update record button based off recording state
    func updateRecordButtonTitle() {
        if !self.movieFileOutput.isRecording {
            recordButton.setTitle("Recording..", for: .normal)
        } else {
            recordButton.setTitle("Record", for: .normal)
        }
    }
    
    // sets the maximum time a session can be recorded for
    func maxRecordedDuration() -> CMTime {
        let seconds : Int64 = 10
        let preferredTimeScale : Int32 = 1
        return CMTimeMake(seconds, preferredTimeScale)
    }
    
    /*
     * Returns a video orientation instance based off the device's orientation
     * Note: the video orientation won't always be the current orientation of the device
     * because left and right are switched for the front and back cameras
     */
    func videoOrientation() -> AVCaptureVideoOrientation {
        
        var videoOrientation:AVCaptureVideoOrientation!
        
        // device's current orientation
        let orientation:UIDeviceOrientation = UIDevice.current.orientation
        
        switch orientation {
            case .portrait:
                videoOrientation = .portrait
            case .landscapeRight:
                videoOrientation = .landscapeLeft
            case .landscapeLeft:
                videoOrientation = .landscapeRight
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
            default:
                videoOrientation = .portrait
        }
        
        return videoOrientation
    }

    // finds the camera with the given position and returns it as an AVCaptureDevice, otherwise nil
    func cameraWithPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        // create an additional DiscoverySession
        let discover = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                                        mediaType: AVMediaType.video,
                                                        position: .unspecified) as AVCaptureDevice.DiscoverySession
        // return the device if it has the desired position
        for device in discover.devices as [AVCaptureDevice] {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }

}
