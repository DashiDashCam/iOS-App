//
//  VideosTableViewController.swift
//  Dashi
//
//  Created by Arslan Memon on 10/31/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import UIKit
import Photos
import CoreMedia
import CoreData
extension CMTime {
    var durationText: String {
        let totalSeconds = CMTimeGetSeconds(self)
        let seconds: Int = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        return String(format: "%02i sec", seconds)
    }
}

protocol MediaCollectionDelegateProtocol {
    func mediaSelected(selectedAssets: [String: PHAsset])
}

class VideosTableViewController: UITableViewController {
    var assets = [PHAsset]()
    var selectedAssets = [String: PHAsset]()
    var delegate: MediaCollectionDelegateProtocol!
    var videos: [NSManagedObject] = []
    var dates: [Date] = []
    var urls: [URL] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        getVids()

        // navigation bar and back button
        navigationController?.isNavigationBarHidden = false

        // Uncomment the following line to preserve selection between presentations
        //   self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_: Bool) {
        getVids()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return videos.count
    }

    func fetchAssets() {
        PhotoManager().fetchAssetsFromLibrary { success, assets in
            if success {
                self.assets = assets!
            }
        }
    }

    func getVids() {
        // 1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let manager = FileManager.default

        let managedContext =
            appDelegate.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")

        // 3
        do {
            videos = try managedContext.fetch(fetchRequest)
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        var i = 0
        for video in videos {
            let data = video.value(forKeyPath: "videoContent") as! Data
            dates.append(video.value(forKeyPath: "startDate") as! Date)

            // dates.append(video.value(forKeyPath: "startDate") as! Date)
            let filename = String(i) + "vid.mp4"
            let path = NSTemporaryDirectory() + filename
            manager.createFile(atPath: path, contents: data, attributes: nil)
            urls.append(URL(fileURLWithPath: path))
            i = i + 1
            //  videobytes.append(video.value(forKeyPath: "videoContent") as! NSData)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "vidCell2", for: indexPath) as! VideoTableViewCell
        let asset2 = AVAsset(url: urls[row])
        let imgGenerator = AVAssetImageGenerator(asset: asset2)

        let cgImage = try! imgGenerator.copyCGImage(at: CMTimeMake(0, 6), actualTime: nil)
        // !! check the error before proceeding
        let thumbnail = UIImage(cgImage: cgImage)
        // let imageView = UIImageView(image: uiImage)
        // let thumbnail = PhotoManager().getAssetThumbnail(asset: asset)
        // Configure the cell...
        let dateFormatter = DateFormatter()

        // US English Locale (en_US)
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium // Jan 2, 2001
        cell.thumbnail.image = thumbnail
        cell.date.text = dateFormatter.string(from: dates[row]) // Jan 2, 2001
        cell.location.text = "Location"

        return cell
    }

    /*
     // Override to support conditional editing of the table view.
     override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the specified item to be editable.
     return true
     }
     */

    /*
     // Override to support editing the table view.
     override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
     if editingStyle == .delete {
     // Delete the row from the data source
     tableView.deleteRows(at: [indexPath], with: .fade)
     } else if editingStyle == .insert {
     // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
     }
     }
     */

    /*
     // Override to support rearranging the table view.
     override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

     }
     */

    /*
     // Override to support conditional rearranging of the table view.
     override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
     // Return false if you do not want the item to be re-orderable.
     return true
     }
     */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let preview = segue.destination as! VideoPreviewViewController
        let row = (tableView.indexPath(for: (sender as! UITableViewCell))?.row)!
        let fileURL = urls[row]
        preview.fileLocation = fileURL
    }
}
