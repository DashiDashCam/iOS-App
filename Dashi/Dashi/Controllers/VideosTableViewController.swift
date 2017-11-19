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
    var videobytes: [NSData]=[]
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchAssets()

        // navigation bar and back button
        navigationController?.isNavigationBarHidden = false

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_: Bool) {
        //1
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        //2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        
        //3
        do {
            videos = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        for video in videos{
            videobytes.append(video.value(forKeyPath: "videoContent") as! NSData)
        }
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
        return videos.count;
    }

    func fetchAssets() {
        PhotoManager().fetchAssetsFromLibrary { success, assets in
            if success {
                self.assets = assets!
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "vidCell2", for: indexPath) as! VideoTableViewCell
        var URLS: [AVURLAsset]=[]
        let tempfp = NSTemporaryDirectory();
        let manager=FileManager.default
        
        for video in videobytes{
            manager.createFile(atPath: tempfp, contents: video as Data, attributes: nil)
            
        }

        let asset = assets[indexPath.row] as PHAsset
        
        let thumbnail = PhotoManager().getAssetThumbnail(asset: asset)
        // Configure the cell...
        cell.thumbnail.image = thumbnail
        cell.date.text = asset.creationDate?.description
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
    func getURL(ofPhotoWith mPhasset: PHAsset, completionHandler: @escaping ((_ responseURL: URL?) -> Void)) {

        if mPhasset.mediaType == .image {
            let options: PHContentEditingInputRequestOptions = PHContentEditingInputRequestOptions()
            options.canHandleAdjustmentData = { (_: PHAdjustmentData) -> Bool in
                true
            }
            mPhasset.requestContentEditingInput(with: options, completionHandler: { contentEditingInput, _ in
                completionHandler(contentEditingInput!.fullSizeImageURL)
            })
        } else if mPhasset.mediaType == .video {
            let options: PHVideoRequestOptions = PHVideoRequestOptions()
            options.version = .original
            PHImageManager.default().requestAVAsset(forVideo: mPhasset, options: options, resultHandler: { asset, _, _ in
                if let urlAsset = asset as? AVURLAsset {
                    let localVideoUrl = urlAsset.url
                    completionHandler(localVideoUrl)
                } else {
                    completionHandler(nil)
                }
            })
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let preview = segue.destination as! VideoPreviewViewController
        let x = assets[(tableView.indexPath(for: (sender as! UITableViewCell))?.row)!]
        getURL(ofPhotoWith: x, completionHandler: { URL in
            preview.fileLocation = URL

        })
    }
}
