//
//  VideoDetailViewController.swift
//  Dashi
//
//  Created by Eric Smith on 2/23/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import UIKit

class VideoDetailViewController: UIViewController {
    var selectedVideo: Video!

    override func viewDidLoad() {
        super.viewDidLoad()
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