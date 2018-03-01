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

class VideoDetailViewController: UIViewController {
    var selectedVideo: Video!

    @IBOutlet weak var videoThumbnail: UIImageView!
    @IBOutlet weak var videoLocation: UILabel!
    @IBOutlet weak var videoTime: UILabel!
    @IBOutlet weak var videoDate: UILabel!
    @IBOutlet weak var videoLength: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        loadVideoContent()
    }

    func loadVideoContent() {
        // set thumbmail image
        videoThumbnail.image = selectedVideo.getThumbnail()

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

    //        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    //            // Get the new view controller using segue.destinationViewController.
    //            // Pass the selected object to the new view controller.
    //            let preview = segue.destination as! VideoPreviewViewController
    //            let row = (tableView.indexPath(for: (sender as! UITableViewCell))?.row)!
    //            if videos[row].getStorageStat() == "cloud" {
    //                DashiAPI.downloadVideoContent(video: videos[row]).then{ val in
    //                    preview.fileLocation = self.getUrlForCloud(id: self.videos[row].getId(), data: val)
    //
    //                    }.catch { error in
    //                        if let e = error as? DashiServiceError {
    //                            print(e.statusCode)
    //                            print(JSON(e.body))
    //                        }
    //                } }
    //            else {
    //                preview.fileLocation = getUrlForLocal(id: videos[row].getId())
    //            }
    //        }
}
