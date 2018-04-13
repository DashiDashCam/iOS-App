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
    @IBOutlet weak var downloadProgress: UILabel!
    
    @IBOutlet weak var downloadFromCloud: UIButton!
    var id: String!
    var i = 0
    var updateDownloadProgressTimer: RepeatingTimer!
    @IBOutlet weak var uploadProgress: UILabel!
    override func viewDidLoad() {
        
        super.viewDidLoad()
        loadVideoContent()
        updateDownloadProgressTimer = RepeatingTimer( repeating: .seconds(1)){
            DispatchQueue.main.async {
                self.updateDownloadProgressText()
            }
            if(self.selectedVideo.getDownloadProgress() >= 100){
                self.updateDownloadProgressTimer.suspend()
            }
        }
        // create tap gesture recognizer for when user taps thumbnail
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoDetailViewController.imageTapped(gesture:)))
        uploadProgress.text = (selectedVideo.getUploadProgress()).description
        downloadProgress.text = (selectedVideo.getDownloadProgress()).description
        // add it to the image view;
        videoThumbnail.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        videoThumbnail.isUserInteractionEnabled = true
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)
        updateDownloadProgressTimer.resume()
        let uploadStatus = selectedVideo.getStorageStat()
       
        if uploadStatus == "local" { 
            print("local")
            uploadProgress.isHidden = true
            
            // show Upload to Cloud
            uploadToCloud.isHidden = false
             downloadProgress.text = String(format: "%d", selectedVideo.getDownloadProgress()) + " % downloaded"
            downloadFromCloud.isHidden = true

        }
        else if uploadStatus == "cloud"{
            downloadFromCloud.isHidden = false
            downloadProgress.isHidden = true
            uploadToCloud.isHidden = true
            uploadProgress.text = String(format: "%d", selectedVideo.getUploadProgress()) + " % uploaded"
        }
        else  {
            // hide Upload to Cloud if video is in cloud
            uploadToCloud.isHidden = true
            downloadFromCloud.isHidden = true
            // TODO: replace with statusbar
            uploadProgress.text = String(format: "%1d", selectedVideo.getUploadProgress()) + " % uploaded"
             downloadProgress.text = String(format: "%1d", selectedVideo.getDownloadProgress()) + " % downloaded"
        }
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        updateDownloadProgressTimer.suspend()
    }
    // called when user taps thumbnail
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            performSegue(withIdentifier: "viewVideoSegue", sender: self)
        }
    }
    
    
    @IBAction func downloadVideo(_ sender: Any) {
      
       downloadFromCloud.isEnabled = false
        DashiAPI.downloadVideoContent(video: selectedVideo).then { val -> Void in
            
            let managedContext =
                self.appDelegate?.persistentContainer.viewContext
            
            let fetchRequest =
                NSFetchRequest<NSManagedObject>(entityName: "Videos")
            fetchRequest.predicate = NSPredicate(format: "id == %@", self.selectedVideo.getId())
            var result: [NSManagedObject] = []
            // 3
            do {
                result = (try managedContext?.fetch(fetchRequest))!
            } catch let error as NSError {
                print("Could not fetch. \(error), \(error.localizedDescription)")
            }
            let video = result[0]
            video.setValue(val, forKey: "videoContent")
            do {
                try managedContext?.save()
                self.selectedVideo.changeStorageToBoth()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }}.catch { error in
                if let e = error as? DashiServiceError {
                    print(e.statusCode)
                    print(JSON(e.body))
                }
                print(error)
        }
    }
    @IBAction func pushToCloud(_: Any) {
        // select video content from CoreData
        uploadToCloud.isEnabled = true
        selectedVideo.asset = AVURLAsset(url: getUrlForLocal(id: selectedVideo.getId())!)

        DashiAPI.uploadVideoMetaData(video: selectedVideo).then { _ -> Void in
            DashiAPI.uploadVideoContent(video: self.selectedVideo).then { _ -> Void in
                self.selectedVideo.changeStorageToBoth()
                self.showAlert(title: "Success", message: "Your trip was saved in the cloud.", dismiss: true)
                self.uploadToCloud.isHidden = true

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
    
    private func updateDownloadProgressText(){
        downloadProgress.text = String(format: "%1d", selectedVideo.getDownloadProgress()) + " % downloaded"
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
        if let url =  getUrlForLocal(id: selectedVideo.getId()){
               preview.fileLocation = url
        }
        else{
            // download video content from cloud
            DashiAPI.downloadVideoContent(video: selectedVideo).then { val in
                preview.fileLocation = self.getUrlForCloud(id: self.selectedVideo.getId(), data: val)

            }.catch { error in
                if let e = error as? DashiServiceError {
                    print(e.statusCode)
                    print(JSON(e.body))
                }
                print(error)
        } }
        
    }

    ////creates url for video content in cloud db given id
    func getUrlForCloud(id: String, data: Data) -> URL? {

        let manager = FileManager.default
        let filename = String(id) + "vid.mp4"
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
        fetchRequest.propertiesToFetch = ["videoContent"]
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        // 3
        do {
            content = (try managedContext?.fetch(fetchRequest))!
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
            return nil
        }

        if  let contentData = content[0].value(forKey: "videoContent") as! Data?{
            let manager = FileManager.default
            let filename = String(id) + "vid.mp4"
            let path = NSTemporaryDirectory() + filename
            manager.createFile(atPath: path, contents: contentData, attributes: nil)
            return URL(fileURLWithPath: path)
        }
        return nil
        
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
