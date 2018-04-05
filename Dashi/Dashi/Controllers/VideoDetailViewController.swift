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

    var id: String!

    @IBOutlet weak var uploadProgress: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        loadVideoContent()

        // create tap gesture recognizer for when user taps thumbnail
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(VideoDetailViewController.imageTapped(gesture:)))
        uploadProgress.text = (selectedVideo.getProgress()).description

        // add it to the image view;
        videoThumbnail.addGestureRecognizer(tapGesture)
        // make sure imageView can be interacted with by user
        videoThumbnail.isUserInteractionEnabled = true
    }

    override func viewWillAppear(_: Bool) {
        super.viewWillAppear(true)

        var uploadStatus = selectedVideo.getStorageStat()

        if uploadStatus == "local" {
            print("local")
        } else  {
            // hide Upload to Cloud if video is in cloud
            uploadToCloud.isHidden = true

            // replace with statusbar
        }
    }

    // called when user taps thumbnail
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            performSegue(withIdentifier: "viewVideoSegue", sender: self)
        }
    }

    @IBAction func pushToCloud(_: Any) {
        // select video content from CoreData
        selectedVideo.changeStorageToBoth()
        selectedVideo.asset = AVURLAsset(url: getUrlForLocal(id: selectedVideo.getId())!)

        DashiAPI.uploadVideoMetaData(video: selectedVideo).then { _ -> Void in
            self.initProgress(id: self.selectedVideo.getId())
            DashiAPI.uploadVideoContent(video: self.selectedVideo).then { _ -> Void in
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

    func initProgress(id: String) {
        let managedContext =
            appDelegate!.persistentContainer.viewContext

        let entity =
            NSEntityDescription.entity(forEntityName: "Videos",
                                       in: managedContext)!
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["videoContent"]
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        var result: [NSManagedObject] = []
        let video = NSManagedObject(entity: entity,
                                    insertInto: managedContext)

        video.setValue(id, forKeyPath: "id")
        video.setValue(0.0, forKeyPath: "uploadProgress")

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
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

        // the video is in the cloud
        if selectedVideo.getStorageStat() == "cloud" {
            // download video content from cloud
            DashiAPI.downloadVideoContent(video: selectedVideo).then { val in
                preview.fileLocation = self.getUrlForCloud(id: self.selectedVideo.getId(), data: val)

            }.catch { error in
                if let e = error as? DashiServiceError {
                    print(e.statusCode)
                    print(JSON(e.body))
                }
        } }
        else {
            // get the video content from CoreData
            preview.fileLocation = getUrlForLocal(id: selectedVideo.getId())
        }
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

        let contentData = content[0].value(forKey: "videoContent") as! Data
        let manager = FileManager.default
        let filename = String(id) + "vid.mp4"
        let path = NSTemporaryDirectory() + filename
        manager.createFile(atPath: path, contents: contentData, attributes: nil)
        return URL(fileURLWithPath: path)
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
