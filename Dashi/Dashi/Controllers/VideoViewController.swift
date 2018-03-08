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
import CoreLocation
import CoreData

class VideoViewController: UIViewController, AVCaptureFileOutputRecordingDelegate, locationHandlerDelegate {
    func handleUpdate(coordinate: CLLocationCoordinate2D) {
        currentLoc = coordinate
    }

    @IBOutlet weak var previewView: UIView! // displays capture stream
    @IBOutlet weak var recordButton: UIButton! // stop/start recording
    @IBOutlet weak var toggleButton: UIButton! // switch camera
    @IBOutlet weak var backButton: UIButton! // custom back button

    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate

    let captureSession = AVCaptureSession()
    var videoCaptureDevice: AVCaptureDevice?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieFileOutput = AVCaptureMovieFileOutput()
    var allowSwitch = true
    var outputFileLocation: URL?
    var simulatorRecording = false
    let locationManager = LocationManager()
    var startLoc: CLLocationCoordinate2D!
    var endLoc: CLLocationCoordinate2D!
    var currentLoc: CLLocationCoordinate2D!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationManager.delegate = self
        locationManager.startLocUpdate()
        // hide navigation bar
        navigationController?.isNavigationBarHidden = true
        initializeCamera()

        // add observer for recognizing device rotation
        NotificationCenter.default.addObserver(self, selector: #selector(VideoViewController.deviceRotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // lock view orientation to portrait - doesn't lock video orientation
        AppUtility.lockOrientation(.portrait)
        setVideoOrientation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Unlock orientation
        AppUtility.lockOrientation(.all)
    }

    // hide status bar
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // adjust the orientation of the preview layer when device changes layout
    override func viewWillLayoutSubviews() {
        if allowSwitch {
            setVideoOrientation()
        }
    }

    // detect the rotation of the device
    @objc func deviceRotated() {
        // the device is in landscape, rotate the appropriate buttons
        if UIDeviceOrientationIsLandscape(UIDevice.current.orientation) {
            if UIDevice.current.orientation == .landscapeLeft {
                toggleButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
                backButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi / 2)
            } else if UIDevice.current.orientation == .landscapeRight {
                toggleButton.transform = CGAffineTransform(rotationAngle: -1 * (CGFloat.pi / 2))
                backButton.transform = CGAffineTransform(rotationAngle: -1 * (CGFloat.pi / 2))
            }
        }

        // reset rotation of buttons when phone is portrait
        if UIDeviceOrientationIsPortrait(UIDevice.current.orientation) {
            toggleButton.transform = CGAffineTransform(rotationAngle: 0)
            backButton.transform = CGAffineTransform(rotationAngle: 0)
        }
    }

    // MARK: Button Actions

    // custom back button to leave this view
    @IBAction func backButtonPressed(sender _: AnyObject) {
        navigationController?.popViewController(animated: true)
    }

    // stop and start recording based off recording state
    @IBAction func recordVideoButtonPressed(sender _: AnyObject) {
        if movieFileOutput.isRecording || simulatorRecording {
            // stop recording
            movieFileOutput.stopRecording()
            endLoc = currentLoc
            // stop recording the simulator
            if TARGET_OS_SIMULATOR != 0 {
                // force seque to previousTrips
                performSegue(withIdentifier: "previousTrips", sender: nil)
                updateRecordButtonTitle()
            }
        } else {
            startLoc = currentLoc
            // not running simulator
            if TARGET_OS_SIMULATOR == 0 {
                // set video orientation of movie file output
                movieFileOutput.connection(with: AVMediaType.video)?.videoOrientation = videoOrientation()

                movieFileOutput.maxRecordedDuration = maxRecordedDuration()

                // start recording
                movieFileOutput.startRecording(to: URL(fileURLWithPath: videoFileLocation()), // output file
                                               recordingDelegate: self)
            } else {
                print("Recording in simulator")
                simulatorRecording = true
            }
        }

        updateRecordButtonTitle()
    }

    @IBAction func cameraTogglePressed(sender _: AnyObject) {
        switchCameraInput()
    }

    // MARK: Main
    func setVideoOrientation() {
        // if the preview layer has a connection
        if let connection = self.previewLayer?.connection {
            // if video orientation is supported, set it based off videoOrientation
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = videoOrientation()

                // set the frame of the preview based off the dimension of the device
                previewLayer?.frame = view.bounds
            }
        }
    }

    func initializeCamera() {
        captureSession.sessionPreset = AVCaptureSession.Preset.high

        // query device for all possible input devices
        let discovery = AVCaptureDevice.DiscoverySession(
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
                    videoCaptureDevice = device
                }
            }
        }

        // check to make sure a device was found
        if videoCaptureDevice != nil {
            do {
                // add the device as the input to the capture session
                try captureSession.addInput(AVCaptureDeviceInput(device: videoCaptureDevice!))

                // if audio is available, add the default device too
                if let audioInput = AVCaptureDevice.default(for: AVMediaType.audio) {
                    try captureSession.addInput(AVCaptureDeviceInput(device: audioInput))
                }

                // create preview layer
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)

                // set previewView's frame to device's dimensions
                previewView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)

                // add preview layer
                previewView.layer.addSublayer(previewLayer!)
                previewView.layer.frame = previewView.frame

                // ensure the preview layer will be displayed with correct orientation
                setVideoOrientation()

                // output of the capture session
                captureSession.addOutput(movieFileOutput)

                // start the capture session!
                captureSession.startRunning()

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

        var newCamera: AVCaptureDevice! // new camera to be added

        // determine newCamera based off position of oldCamera
        if let oldCamera = existingConnection {
            if oldCamera.device.position == .back {
                newCamera = self.cameraWithPosition(position: .front)
            } else {
                newCamera = self.cameraWithPosition(position: .back)
            }
        }

        var newInput: AVCaptureDeviceInput! // input to be based off newCamera

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
    func fileOutput(_: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL,
                    from _: [AVCaptureConnection], error _: Error?) {
        print("Finished recording: \(outputFileURL)")

        // set output file location
        self.outputFileLocation = outputFileURL

        // seque to videoPreview
        self.performSegue(withIdentifier: "videoPreview", sender: nil)
    }

    // MARK: Helpers

    // returns file location in the temporary directory
    func videoFileLocation() -> String {
        return NSTemporaryDirectory().appending("videoFile.mov")
    }

    // update record button based off recording state
    func updateRecordButtonTitle() {
        if !self.movieFileOutput.isRecording {
            self.allowSwitch = false
            recordButton.setImage(UIImage(named: "record on"), for: .normal)
        } else {
            self.allowSwitch = true
            recordButton.setImage(UIImage(named: "record off"), for: .normal)
        }
    }

    // sets the maximum time a session can be recorded for
    func maxRecordedDuration() -> CMTime {
        let seconds: Int64 = 10
        let preferredTimeScale: Int32 = 1
        return CMTimeMake(seconds, preferredTimeScale)
    }

    /*
     * Returns a video orientation instance based off the device's orientation
     * Note: the video orientation won't always be the current orientation of the device
     * because left and right are switched for the front and back cameras
     */
    func videoOrientation() -> AVCaptureVideoOrientation {

        var videoOrientation: AVCaptureVideoOrientation!

        // device's current orientation
        let orientation: UIDeviceOrientation = UIDevice.current.orientation

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

    // save the video to core data
    func saveVideoToCoreData() {
        let path = Bundle.main.path(forResource: "IMG_1800", ofType: "MOV")
        let asset = AVURLAsset(url: URL(fileURLWithPath: path!))

        let currentVideo = Video(started: Date(), asset: asset, startLoc: startLoc, endLoc: endLoc)

        let managedContext =
            appDelegate!.persistentContainer.viewContext

        let entity =
            NSEntityDescription.entity(forEntityName: "Videos",
                                       in: managedContext)!
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["videoContent"]
        fetchRequest.predicate = NSPredicate(format: "id == %@", currentVideo.getId())
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }

        if result.isEmpty {
            let video = NSManagedObject(entity: entity,
                                        insertInto: managedContext)

            video.setValue(currentVideo.getId(), forKeyPath: "id")
            video.setValue(currentVideo.getContent(), forKeyPath: "videoContent")
            video.setValue(currentVideo.getStarted(), forKeyPath: "startDate")
            video.setValue(currentVideo.getImageContent(), forKey: "thumbnail")
            video.setValue(currentVideo.getLength(), forKeyPath: "length")
            video.setValue(currentVideo.getSize(), forKey: "size")
            video.setValue(currentVideo.getStartLat(), forKey: "startLat")
            video.setValue(currentVideo.getStartLong(), forKey: "startLong")
            video.setValue(currentVideo.getEndLat(), forKey: "endLat")
            video.setValue(currentVideo.getEndLong(), forKey: "endLong")
            do {
                try managedContext.save()
                //                self.showAlert(title: "Success", message: "Your trip was saved locally.", dismiss: true)
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        } else {
            //            self.showAlert(title: "Already Saved", message: "Your trip has already been saved locally.", dismiss: true)
            print("already saved")
        }
    }

    // prepare to seque to another view
    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        let preview = segue.destination as! VideosTableViewController
        //        preview.startLoc = startLoc
        //        preview.endLoc = endLoc

        // let VideoPreviewController know where we are sequeing from
        //        preview.previousView = "VideoViewController"

        //        // not running simulator
        //        if TARGET_OS_SIMULATOR == 0 {
        //            preview.fileLocation = self.outputFileLocation // triggers loading of video
        //        } else {
        //            print("stopped recording")
        //            guard let path = Bundle.main.path(forResource: "IMG_1800", ofType: "MOV") else {
        //                debugPrint("Placeholder video not found")
        //                return
        //            }
        //            //            let player = AVPlayer(url: URL(fileURLWithPath: path))
        //            preview.fileLocation = URL(fileURLWithPath: path)
        //        }
    }
}

// additional struct for locking orientation
struct AppUtility {
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
}
