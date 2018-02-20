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


class VideosTableViewController: UITableViewController {
    var videos: [Video] = []
    var ids: [String] = []
     let geoCoder = CLGeocoder()
    let appDelegate =
        UIApplication.shared.delegate as? AppDelegate

    override func viewDidLoad() {
        super.viewDidLoad()
        getVidsFromLocal()
        getVidsFromCloud()
        // navigation bar and back button
        navigationController?.isNavigationBarHidden = false

        // Uncomment the following line to preserve selection between presentations
        //   self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
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

    func getVidsFromCloud() {
        DashiAPI.getAllVideoMetaData().then { value -> Void in
            for video in value{
                if let index = self.ids.index(of: video.getId()){
                    self.videos[index].changeStorageToBoth()
                }
                else{
                    self.videos.append(video)
                }
            }
            
            self.tableView.reloadData()
        }.catch {
            error in
            print(String(data: (error as! DashiServiceError).body, encoding: String.Encoding.utf8)!)
        }
    }

    func getVidsFromLocal() {
        var fetchedmeta: [NSManagedObject] = []

        let managedContext =
            appDelegate?.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["startDate", "length", "size", "thumbnail", "id", "startLat", "startLong", "endLat", "endLong"]
        // 3
        do {
            fetchedmeta = (try managedContext?.fetch(fetchRequest))!
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }

        for meta in fetchedmeta {

            let id = meta.value(forKey: "id") as! String
            let date = meta.value(forKey: "startDate") as! Date
            let thumbnailData = meta.value(forKey: "thumbnail") as! Data
            let size = meta.value(forKey: "size") as! Int
            let length = meta.value(forKey: "length") as! Int
            let startLat = meta.value(forKey: "startLat") as! CLLocationDegrees
            let startLong = meta.value(forKey: "startLong") as! CLLocationDegrees
            let endLat = meta.value(forKey: "endLat") as! CLLocationDegrees
            let endLong = meta.value(forKey: "endLong") as! CLLocationDegrees
            // dates.append(video.value(forKeyPath: "startDate") as! Date)
            let video = Video(started: date, imageData: thumbnailData, id: id, length: length, size: size, startLoc: CLLocationCoordinate2D( latitude:startLat,longitude: startLong), endLoc: CLLocationCoordinate2D( latitude:endLat,longitude: endLong))
            videos.append(video)
            //  videobytes.append(video.value(forKeyPath: "videoContent") as! NSData)
            ids.append(id)
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.row
        let cell = tableView.dequeueReusableCell(withIdentifier: "vidCell2", for: indexPath) as! VideoTableViewCell
        // !! check the error before proceeding
        // let imageView = UIImageView(image: uiImage)
        // let thumbnail = PhotoManager().getAssetThumbnail(asset: asset)
        // Configure the cell...
        let dateFormatter = DateFormatter()
        let endLoc = CLLocation(latitude: videos[row].getEndLat(), longitude: videos[row].getEndLong())
        
        geoCoder.reverseGeocodeLocation(endLoc) { placemarks, error in
            
            if let e = error {
                
               print(e)
                
            } else {
                
                let placeArray = placemarks as [CLPlacemark]!
                
                var placeMark: CLPlacemark!
                
                placeMark = placeArray![0]
                cell.location.text = placeMark.locality! + ", " + placeMark.country!
            }
            
            
        }
        
        // US English Locale (en_US)
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short // Jan 2, 2001
        cell.thumbnail.image = videos[row].getThumbnail()
        cell.date.text = dateFormatter.string(from: videos[row].getStarted()) // Jan 2, 2001
        cell.storageIcon.image = UIImage(named: videos[row].getStorageStat())
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
        if videos[row].getStorageStat() == "cloud" {
            DashiAPI.downloadVideoContent(video: videos[row]).then{ val in
                preview.fileLocation = self.getUrlForCloud(id: self.videos[row].getId(), data: val)
                
                }.catch { error in
                if let e = error as? DashiServiceError {
                    print(e.statusCode)
                    print(JSON(e.body))
                }
        } }
        else {
            preview.fileLocation = getUrlForLocal(id: videos[row].getId())
        }
    }

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

        var contentData = content[0].value(forKey: "videoContent") as! Data
        let manager = FileManager.default
        let filename = String(id) + "vid.mp4"
        let path = NSTemporaryDirectory() + filename
        manager.createFile(atPath: path, contents: contentData, attributes: nil)
        return URL(fileURLWithPath: path)
    }
    
    func getUrlForCloud(id: String, data: Data) -> URL? {
        
        let manager = FileManager.default
        let filename = String(id) + "vid.mp4"
        let path = NSTemporaryDirectory() + filename
        manager.createFile(atPath: path, contents: data, attributes: nil)
        return URL(fileURLWithPath: path)
    }
}
