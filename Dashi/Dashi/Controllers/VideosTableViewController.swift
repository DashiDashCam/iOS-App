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
import PromiseKit
import SwiftyJSON
import MapKit
import SVGKit

class VideosTableViewController: UITableViewController {
    var videos: [Video] = []
    
    var timer: Timer?
    
    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate
    // get's video metadata from local db and cloud
    override func viewDidLoad() {
        super.viewDidLoad()
        getMetaData()
        // navigation bar and back button
        navigationController?.isNavigationBarHidden = false

        // override back button to ensure it always returns to the home screen
        if let rootVC = navigationController?.viewControllers.first {
            navigationController?.viewControllers = [rootVC, self]
        }

        // Uncomment the following line to preserve selection between presentations
        //   self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewWillAppear(_: Bool) {

        self.tableView.reloadData()

        // set orientation
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        // lock orientation
        AppUtility.lockOrientation(.portrait)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true){_ in
            let cells = self.tableView.visibleCells as! Array<VideoTableViewCell>
            self.tableView.beginUpdates()
            var indexToRemove : IndexPath? = nil
            for cell in cells{
                let indexPath = self.tableView.indexPath(for: cell)
                let row = indexPath?.row
                //prevent code from firing if video was deleted in videoDetail
                if(!self.videos[row!].wasDeleted()){
                    cell.storageIcon.image = UIImage(named: self.videos[row!].getStorageStat()) // idk why, but don't delete this
                    
                    // set storage image based off stat
                    var storageImage: SVGKImage
                    let storageStat = self.videos[row!].getStorageStat()
                    cell.location.text = self.videos[row!].getLocation()
                    // video hasn't been uploaded
                    if storageStat == "local" {
                        storageImage = SVGKImage(named: "local")
                    } else {
                        storageImage = SVGKImage(named: "cloud")
                    }
                    cell.storageIcon.image = storageImage.uiImage
                    if self.videos[row!].getDownloadInProgress() {
                        var namSvgImgVar: SVGKImage = SVGKImage(named: "download")
                        cell.uploadDownloadIcon.image = namSvgImgVar.uiImage
                        cell.uploadDownloadIcon.isHidden = false
                        
                    } else if self.videos[row!].getUploadInProgress() {
                        var namSvgImgVar: SVGKImage = SVGKImage(named: "upload")
                        cell.uploadDownloadIcon.image = namSvgImgVar.uiImage
                        cell.uploadDownloadIcon.isHidden = false
                        
                    } else {
                        cell.uploadDownloadIcon.isHidden = true
                    }
                }
                else{
                    indexToRemove = indexPath
                }
            }
            //I am assuming it is impossible for a user to be able to delete more than one video
            //in under 0.5 seconds, so only 1 cell will ever need to be removed at a time
            if(indexToRemove != nil){
                self.videos.remove(at: (indexToRemove?.row)!)
                self.tableView.deleteRows(at: [indexToRemove!], with: .automatic)
            }
            self.tableView.endUpdates()
        }
        timer?.fire()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    // returns the number of sections(types of cells) that are going to be in the table to the table view controller
    override func numberOfSections(in _: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    // returns how many of each type of cell the table has
    override func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return videos.count
    }
    
    // allows a row to be deleted
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func getMetaData() {
        var fetchedmeta: [NSManagedObject] = []

        let managedContext =
            appDelegate?.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "accountID == %d", (sharedAccount?.getId())!)
        fetchRequest.propertiesToFetch = ["startDate", "length", "size", "thumbnail", "id", "startLat", "startLong", "endLat", "endLong", "locationName"]
        // 3
        do {
            fetchedmeta = (try managedContext?.fetch(fetchRequest))!
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }

        for meta in fetchedmeta {
            var video: Video
            let id = meta.value(forKey: "id") as! String
            let date = meta.value(forKey: "startDate") as! Date
            let thumbnailData = meta.value(forKey: "thumbnail") as! Data
            let size = meta.value(forKey: "size") as! Int
            let length = meta.value(forKey: "length") as! Int
            let startLat = meta.value(forKey: "startLat") as! CLLocationDegrees?
            let startLong = meta.value(forKey: "startLong") as! CLLocationDegrees?
            let endLat = meta.value(forKey: "endLat") as! CLLocationDegrees?
            let endLong = meta.value(forKey: "endLong") as! CLLocationDegrees?
            let locationName = meta.value(forKey: "locationName") as! String?
            if let lat1 = startLat, let lat2 = endLat, let long1 = startLong, let long2 = endLong{
            // dates.append(video.value(forKeyPath: "startDate") as! Date)
                 video = Video(started: date, imageData: thumbnailData, id: id, length: length, size: size, startLoc: CLLocationCoordinate2D(latitude: lat1, longitude: long1), endLoc: CLLocationCoordinate2D(latitude: lat2, longitude: long2), locationName: locationName )
                
            }
            else{
                video = Video(started: date, imageData: thumbnailData, id: id, length: length, size: size, startLoc: nil, endLoc: nil, locationName: locationName )
            }
            videos.append(video)
        }
        videos.sort(by: { $0.getStarted() > $1.getStarted() })
    }

    // sets cell data for each video
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "vidCell2", for: indexPath) as! VideoTableViewCell

        let dateFormatter = DateFormatter()
        
        // US English Locale (en_US)

        dateFormatter.dateFormat = "MMMM dd"
        //        dateFormatter.timeStyle = .short
        cell.thumbnail.image = videos[row].getThumbnail()
        cell.date.text = dateFormatter.string(from: videos[row].getStarted())
        cell.location.text = videos[row].getLocation()
        // set time
        dateFormatter.dateFormat = "hh:mm a"
        cell.time.text = dateFormatter.string(from: videos[row].getStarted())
        cell.id = videos[row].getId()
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
        let preview = segue.destination as! VideoDetailViewController
        let row = (tableView.indexPath(for: (sender as! UITableViewCell))?.row)!

        let selectedVideo = videos[row]

        preview.selectedVideo = selectedVideo
    }

    // pass the id of a desired video to delete it from core data
    func deleteLocal(id: String) {
        var content: [NSManagedObject]
        let managedContext =
            appDelegate?.persistentContainer.viewContext

        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["videoContent"]
        fetchRequest.predicate = NSPredicate(format: "id == %@ && accountID == %d", id, (sharedAccount?.getId())!)

        do {

            content = (try managedContext?.fetch(fetchRequest))!
            managedContext?.delete(content[0])

            do {
                // commit changes to context
                try managedContext!.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
            return
        }
    }
}
