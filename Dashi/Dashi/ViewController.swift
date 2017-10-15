    import UIKit
    import AVFoundation
    
    class ViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
        
        @IBOutlet weak var camButton: UIButton!
        
        @IBAction func record(_ sender: Any) {
        startCapture()
        }
        
        @IBOutlet var camPreview: UIView!
        
        let cameraButton = UIView()
        
        let captureSession = AVCaptureSession()
        
        let movieOutput = AVCaptureMovieFileOutput()
        
        var previewLayer: AVCaptureVideoPreviewLayer!
        
        var activeInput: AVCaptureDeviceInput!
        
        var outputURL: URL!
        
        override func viewDidLoad() {
            super.viewDidLoad()
            
            if setupSession() {
                setupPreview()
                startSession()
            }
            func styleCaptureButton() {
                camButton.layer.borderColor = UIColor.black.cgColor
                camButton.layer.borderWidth = 2
                
                camButton.layer.cornerRadius = min(camButton.frame.width, camButton.frame.height) / 2
                camPreview.layer.addSublayer(camButton.layer)
            }
            
            styleCaptureButton()
        }
        
        func setupPreview() {
            // Configure previewLayer
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = camPreview.bounds
            previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            camPreview.layer.addSublayer(previewLayer)
        }
        
        //MARK:- Setup Camera
        
        func setupSession() -> Bool {
            
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
            
            // Setup Camera
            let camera = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            
            do {
                let input = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(input) {
                    captureSession.addInput(input)
                    activeInput = input
                }
            } catch {
                print("Error setting device video input: \(error)")
                return false
            }
            
            // Setup Microphone
            let microphone = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeAudio)
            
            do {
                let micInput = try AVCaptureDeviceInput(device: microphone)
                if captureSession.canAddInput(micInput) {
                    captureSession.addInput(micInput)
                }
            } catch {
                print("Error setting device audio input: \(error)")
                return false
            }
            
            
            // Movie output
            if captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            return true
        }
        
        func setupCaptureMode(_ mode: Int) {
            // Video Mode
            
        }
        
        //MARK:- Camera Session
        func startSession() {
            
            
            if !captureSession.isRunning {
                videoQueue().async {
                    self.captureSession.startRunning()
                }
            }
        }
        
        func stopSession() {
            if captureSession.isRunning {
                videoQueue().async {
                    self.captureSession.stopRunning()
                }
            }
        }
        
        func videoQueue() -> DispatchQueue {
            return DispatchQueue.main
        }
        
        
        
        func currentVideoOrientation() -> AVCaptureVideoOrientation {
            var orientation: AVCaptureVideoOrientation
            
            switch UIDevice.current.orientation {
            case .portrait:
                orientation = AVCaptureVideoOrientation.portrait
            case .landscapeRight:
                orientation = AVCaptureVideoOrientation.landscapeLeft
            case .portraitUpsideDown:
                orientation = AVCaptureVideoOrientation.portraitUpsideDown
            default:
                orientation = AVCaptureVideoOrientation.landscapeRight
            }
            
            return orientation
        }
        
        func startCapture() {
            
            startRecording()
            
        }
        
        //EDIT 1: I FORGOT THIS AT FIRST
        
        func tempURL() -> URL? {
            let directory = NSTemporaryDirectory() as NSString
            
            if directory != "" {
                let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
                return URL(fileURLWithPath: path)
            }
            
            return nil
        }
        
        
        func startRecording() {
            
            if movieOutput.isRecording == false {
                
                let connection = movieOutput.connection(withMediaType: AVMediaTypeVideo)
                if (connection?.isVideoOrientationSupported)! {
                    connection?.videoOrientation = currentVideoOrientation()
                }
                
                if (connection?.isVideoStabilizationSupported)! {
                    connection?.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto
                }
                
                let device = activeInput.device
                if (device?.isSmoothAutoFocusSupported)! {
                    do {
                        try device?.lockForConfiguration()
                        device?.isSmoothAutoFocusEnabled = false
                        device?.unlockForConfiguration()
                    } catch {
                        print("Error setting configuration: \(error)")
                    }
                    
                }
                camButton.backgroundColor=UIColor.red
                //EDIT2: And I forgot this
                outputURL = tempURL()
                movieOutput.startRecording(toOutputFileURL: outputURL, recordingDelegate: self)
                
            }
            else {
                stopRecording()
                camButton.backgroundColor=UIColor.white
            }
            
        }
        
        func stopRecording() {
            
            if movieOutput.isRecording == true {
                movieOutput.stopRecording()
            }
        }
        
        func capture(_ captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAt fileURL: URL!, fromConnections connections: [Any]!) {
           
            
        }
        
        func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
            if (error != nil) {
                print("Error recording movie: \(error!.localizedDescription)")
            } else {
                 UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.relativePath, self, nil, nil)
                _ = outputURL as URL
                
            }
            outputURL = nil
        }
        
        
        
    }
