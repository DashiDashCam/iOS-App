//
//  VideoDetailViewController.swift
//  Dashi
//
//  Created by Eric Smith on 2/23/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import SwiftyJSON
import CoreData
import PromiseKit
import AVFoundation
import AVKit

class VideoDetailViewController: UIViewController {
    var selectedVideo: Video!
    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate
    @IBOutlet weak var videoThumbnail: UIImageView!
    @IBOutlet weak var videoLocation: UILabel!
    @IBOutlet weak var videoTime: UILabel!
    @IBOutlet weak var videoDate: UILabel!
    @IBOutlet weak var videoLength: UILabel!
    @IBOutlet weak var uploadToCloud: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var downloadFromCloud: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    var id: String!
    var updateDownloadProgressTimer: Timer!

    @IBOutlet weak var localIcon: UIImageView!
    @IBOutlet weak var cloudIcon: UIImageView!
    var updateUploadProgressTimer: Timer?

    var checkStatusTimer: Timer?

    var lastStatus: String?

    var uploadProgDisplayed: Bool = false

    var downloadProgDisplayed: Bool = false

    override func viewDidLoad() {

        super.viewDidLoad()
        loadVideoContent()

        // create tap gesture recognizer for when user taps thumbnail
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoDetailViewController.imageTapped(gesture:)))
        // add it to the image view;
        videoThumbnail.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        videoThumbnail.isUserInteractionEnabled = true

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        progressBar.isHidden = true
        let uploadStatus = selectedVideo.getStorageStat()
        if selectedVideo.getDownloadInProgress() {
            showDownloadProgress()
        }
        if selectedVideo.getUploadInProgress() {
            showUploadProgress()
        }
        localIcon.image = UIImage(named: "local")
        cloudIcon.image = UIImage(named: "cloud")
        checkStatusTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.viewUpdater()
        })

        if uploadStatus == "local" {
            print("local")

            // show Upload to Cloud
            uploadToCloud.isHidden = false
            shareButton.isHidden = true
            localIcon.isHidden = false
            cloudIcon.isHidden = true
            downloadFromCloud.isHidden = true

        } else if uploadStatus == "cloud" {
            cloudIcon.isHidden = false
            shareButton.isHidden = false
            localIcon.isHidden = true
            uploadToCloud.isHidden = true
        } else {
            // hide Upload to Cloud if video is in cloud
            shareButton.isHidden = false
            uploadToCloud.isHidden = true
            downloadFromCloud.isHidden = true
            // TODO: replace with statusbar
            localIcon.isHidden = false
            cloudIcon.isHidden = false
        }
        lastStatus = uploadStatus
        
        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        // lock orientation
        AppUtility.lockOrientation(.portrait)
    }

    override func viewWillDisappear(_: Bool) {
        updateUploadProgressTimer?.invalidate()
        updateDownloadProgressTimer?.invalidate()
        checkStatusTimer?.invalidate()
    }

    // called when user taps thumbnail
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            if selectedVideo.getStorageStat() == "cloud" {
                let alert = UIAlertController(title: "Video not downloaded", message: "Would you like to download it?", preferredStyle: .alert)
                let yes = UIAlertAction(title: "Yes", style: .default) { _ in
                    self.downloadVideo(self)
                }
                let no = UIAlertAction(title: "No", style: .cancel)
                alert.addAction(yes)
                alert.addAction(no)
                present(alert, animated: true, completion: nil)
            } else {
                performSegue(withIdentifier: "viewVideoSegue", sender: self)
            }
        }
    }

    @IBAction func downloadVideo(_: Any) {
        selectedVideo.updateDownloadInProgress(status: true)
        showDownloadProgress()
        DashiAPI.downloadVideoContent(video: selectedVideo)
        // self.selectedVideo.changeStorageToBoth()
    }

    @IBAction func pushToCloud(_: Any) {
        selectedVideo.updateUploadInProgress(status: true)
        showUploadProgress()
        // select video content from CoreData
        DashiAPI.uploadVideoMetaData(video: selectedVideo).then { _ -> Void in
            DashiAPI.uploadVideoContent(video: self.selectedVideo).then { _ -> Void in
                self.selectedVideo.changeStorageToBoth()
                self.selectedVideo.updateUploadInProgress(status: false)
                self.uploadToCloud.setTitle("Upload Complete", for: .normal)
                Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                    self.progressBar.isHidden = true
                    self.uploadToCloud.isHidden = true
                })
            }.catch { error in
                if let e = error as? DashiServiceError {
                    print(String(data: e.body, encoding: String.Encoding.utf8)!)
                }
            }
        }.catch { error in
            print("CATCH")
            if let e = error as? DashiServiceError {
                print(String(data: e.body, encoding: String.Encoding.utf8)!)
            }
        }
    }

    // shows alert to user
    func showAlert(title: String, message: String, dismiss: Bool) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if dismiss {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
        } else {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }

        present(controller, animated: true, completion: nil)
    }

    func loadVideoContent() {
        // set thumbmail image
        videoThumbnail.image = selectedVideo.getThumbnail()

        id = selectedVideo.getId()

        // get length of video
        let (h, m, s) = selectedVideo.secondsToHoursMinutesSeconds()
        var lengthString: String

        // format length as necessary
        if m > 0 {
            lengthString = String(format: "%02d", h) + ":" + String(format: "%02d", m)
        } else {
            lengthString = String(s) + " seconds"
        }

        // set the length label
        videoLength.text = lengthString

        // ending location
        let endLoc = CLLocation(latitude: selectedVideo.getEndLat(), longitude: selectedVideo.getEndLong())

        // lookup location based off ending cordinates
        CLGeocoder().reverseGeocodeLocation(endLoc) { placemarks, error in
            if let e = error {
                print(e)
            } else {
                let placeArray = placemarks as [CLPlacemark]!
                var placeMark: CLPlacemark!
                placeMark = placeArray![0]

                // format location and set label
                self.videoLocation.text = placeMark.locality!
            }
        }

        // format the date and set label
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM dd, yyyy"
        let dateString = formatter.string(from: selectedVideo.getStarted())
        videoDate.text = dateString

        // format the time and set label
        formatter.dateFormat = "hh:mm a"
        let timeString = formatter.string(from: selectedVideo.getStarted())
        videoTime.text = timeString
    }

    override func prepare(for segue: UIStoryboardSegue, sender _: Any?) {
        //         Get the new view controller using segue.destinationViewController.
        //         Pass the selected object to the new view controller.
        let preview = segue.destination as! VideoPreviewViewController
        if let url = getUrlForLocal(id: selectedVideo.getId()) {
            preview.fileLocation = url
        }
        //        else{
        //            // download video content from cloud
        //            DashiAPI.downloadVideoContent(video: selectedVideo).then { val in
        //                preview.fileLocation = self.getUrlForCloud(id: self.selectedVideo.getId(), data: val)
        //
        //            }.catch { error in
        //                if let e = error as? DashiServiceError {
        //                    print(e.statusCode)
        //                    print(JSON(e.body))
        //                }
        //                print(error)
        //            }
        //        }
    }

    ////creates url for video content in cloud db given id
    func getUrlForCloud(id: String, data: Data) -> URL? {

        let manager = FileManager.default
        let filename = String(id) + "vid.MOV"
        let path = NSTemporaryDirectory() + filename
        manager.createFile(atPath: path, contents: data, attributes: nil)
        return URL(fileURLWithPath: path)
    }

    // creates url for video content in local db given id
    func getUrlForLocal(id: String) -> URL? {

        var content: [NSManagedObject]
        let managedContext =
            appDelegate?.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["videoContent", "id"]
        fetchRequest.predicate = NSPredicate(format: "id == %@ && accountID == %d", id, (sharedAccount?.getId())!)
        // 3
        do {
            content = (try managedContext?.fetch(fetchRequest))!
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
            return nil
        }

        if let contentData = content[0].value(forKey: "videoContent") as! Data? {
            let manager = FileManager.default
            let filename = String(id) + "vid.mp4"
            let path = NSTemporaryDirectory() + filename
            manager.createFile(atPath: path, contents: contentData, attributes: nil)
            return URL(fileURLWithPath: path)
        }
        return nil
    }

    private func showUploadProgress() {
        progressBar.isHidden = false
        uploadToCloud.isEnabled = true
        uploadProgDisplayed = true
        selectedVideo.asset = AVURLAsset(url: getUrlForLocal(id: selectedVideo.getId())!)
        uploadToCloud.setTitle("Uploading", for: .normal)
        updateUploadProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.uploadProgTask()
        })
        uploadProgTask()
    }

    private func uploadProgTask() {
        let progress = Float(selectedVideo.getUploadProgress()) / 100.0
        if progress >= 1.0 {
            updateUploadProgressTimer?.invalidate()
            uploadToCloud.setTitle("Upload Complete", for: .normal)
            updateUploadProgressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                self.progressBar.isHidden = true
                self.uploadToCloud.isHidden = true
                self.shareButton.isHidden = false
                if self.selectedVideo.getStorageStat() == "cloud" {
                    self.downloadFromCloud.isHidden = false
                }
            })
        }
        DispatchQueue.main.async {
            self.progressBar.progress = progress
        }
    }

    private func showDownloadProgress() {
        progressBar.isHidden = false
        downloadFromCloud.isEnabled = false
        downloadProgDisplayed = true
        downloadFromCloud.setTitle("Downloading", for: .normal)
        updateDownloadProgressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.downloadProgTask()
        })
        downloadProgTask()
    }

    private func downloadProgTask() {
        let progress = Float(selectedVideo.getDownloadProgress()) / 100.0
        if progress >= 1.0 {
            updateDownloadProgressTimer?.invalidate()
            downloadFromCloud.setTitle("Download Complete", for: .normal)
            updateDownloadProgressTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false, block: { _ in
                self.progressBar.isHidden = true
                self.downloadFromCloud.isHidden = true
            })
            progressBar.isHidden = true
        }
        DispatchQueue.main.async {
            self.progressBar.progress = progress
        }
    }

    private func viewUpdater() {
        if !uploadProgDisplayed && selectedVideo.getUploadInProgress() {
            showUploadProgress()
        } else if !downloadProgDisplayed && selectedVideo.getDownloadInProgress() {
            showDownloadProgress()
        }
        let uploadStatus = selectedVideo.getStorageStat()
        if lastStatus != uploadStatus {
            if uploadStatus == "local" {
                // show Upload to Cloud
                uploadToCloud.isHidden = false
                shareButton.isHidden = true
                localIcon.isHidden = false
                cloudIcon.isHidden = true
                downloadFromCloud.isHidden = true

            } else if uploadStatus == "cloud" {
                cloudIcon.isHidden = false
                shareButton.isHidden = false
                localIcon.isHidden = true
                uploadToCloud.isHidden = true

                // if uploadToCloud hasn't been hidden yet, let the upload to cloud progress timer handle
                // showing the download button
                if uploadToCloud.isHidden {
                    downloadFromCloud.isHidden = false
                }
            } else {
                // hide Upload to Cloud if video is in cloud
                shareButton.isHidden = false
                uploadToCloud.isHidden = true
                downloadFromCloud.isHidden = true
                // TODO: replace with statusbar
                localIcon.isHidden = false
                cloudIcon.isHidden = false
            }
            lastStatus = uploadStatus
        }
    }

    @IBAction func shareVideoLink() {
        let this = self
        DashiAPI.createDownloadLink(id: id).then { videoLink -> Void in
            print(videoLink)
            let activityViewController = UIActivityViewController(activityItems: [videoLink as NSString], applicationActivities: nil)
            this.present(activityViewController, animated: true)
        }
    }
}
