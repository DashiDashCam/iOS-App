//
//  FileManager.swift
//  Dashi
//
//  Created by Chris Henk on 3/27/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import CoreData
import UIKit
import MapKit

class VideoManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    static var shared = VideoManager()

    typealias ProgressHandler = (Float) -> Void

    var onProgress: ProgressHandler? {
        didSet {
            if onProgress != nil {
                _ = activate()
            }
        }
    }

    private override init() {
        super.init()
    }

    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")

        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }

    private func calculateProgress(session: URLSession, completionHandler: @escaping (Float) -> Void) {
        session.getTasksWithCompletionHandler { _, _, downloads in
            let progress = downloads.map({ (task) -> Float in
                if task.countOfBytesExpectedToReceive > 0 {
                    return Float(task.countOfBytesReceived) / Float(task.countOfBytesExpectedToReceive)
                } else {
                    return 0.0
                }
            })
            completionHandler(progress.reduce(0.0, +))
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData _: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {

        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
        }
    }

    func urlSession(_: URLSession, downloadTask _: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        try? FileManager.default.removeItem(at: location)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(error)")
    }

    private static func retensionCheck(settings: Dictionary<String, Any>) {
        print("BACKGROUND TASK: Beginning Retension Check...")

        // If auto delete is enabled, simply flush cache
        if settings["autoDelete"] as! Bool {
            VideoManager.flushCache(ignoreDownloaded: false)
        }

        // Pull meta data for stored videos
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["id", "startDate", "downloaded", "uploadProgress", "size"]
        fetchRequest.predicate = NSPredicate(format: "videoContent != nil  && accountID == %d", (sharedAccount?.getId())!)
        var videos: [NSManagedObject] = []
        do {
            videos = (try managedContext.fetch(fetchRequest))
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }

        var totalSize: Int64 = 0

        // Remove videos according to retension time policy
        for video in videos {
            let now = Date()

            // Calculate start date based cutoff
            let startDate = video.value(forKey: "startDate") as! Date
            var dayComp = DateComponents()
            dayComp.day = (settings["localRetentionTime"] as! Int)
            let startCutoffDate = Calendar.current.date(byAdding: dayComp, to: Date())
            Calendar.current.component(.weekday, from: startCutoffDate!)

            // Calculate downloaded date based cutoff
            let downloadDate = video.value(forKey: "downloaded") as? Date
            dayComp = DateComponents()
            dayComp.day = (settings["localRetentionTime"] as! Int)
            let downloadedCutoffDate = Calendar.current.date(byAdding: dayComp, to: Date())
            Calendar.current.component(.weekday, from: downloadedCutoffDate!)

            // Old video that hasn't been manually downloaded recently
            if startCutoffDate! < now && (downloadDate == nil || downloadedCutoffDate! < now) {
                // Delete the cached video content
                video.setValue(nil, forKey: "videoContent")
                video.setValue(nil, forKey: "downloaded")
                video.setValue(nil, forKey: "downloadProgress")
                video.setValue("cloud", forKey: "storageStat")
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.localizedDescription)")
                }
            } else {
                totalSize += (video.value(forKey: "size") as! Int64)
            }
        }

        // Enforce max file size
        if totalSize > ((settings["maxLocalStorage"] as! Int) * 1024 * 1024 * 1024) {
            VideoManager.flushCache()
        }
    }

    private static func uploadCheck(settings: Dictionary<String, Any>) {
        print("BACKGROUND TASK: Beginning Upload Check...")

        // Only needs to be scheduled when autoBackup is enabled
        if settings["autoBackup"] as! Bool {
            // Find videos that need to be uploaded
            guard let appDelegate =
                UIApplication.shared.delegate as? AppDelegate else {
                return
            }

            // Get coredata context
            let managedContext = appDelegate.persistentContainer.viewContext

            // Load video dates and upload status
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Videos")
            fetchRequest.propertiesToFetch = ["id", "uploadProgress"]
            fetchRequest.predicate = NSPredicate(format: "uploadProgress == 0  && accountID == %d", (sharedAccount?.getId())!)

            var videos: [NSManagedObject] = []
            do {
                videos = (try managedContext.fetch(fetchRequest))
            } catch let error as Error {
                print("Could not fetch. \(error), \(error.localizedDescription)")
            }

            // Schedule upload tasks
            for video in videos {
                let id = video.value(forKey: "id") as! String
                let date = video.value(forKey: "startDate") as! Date
                let thumbnailData = video.value(forKey: "thumbnail") as! Data
                let size = video.value(forKey: "size") as! Int
                let length = video.value(forKey: "length") as! Int
                let startLat = video.value(forKey: "startLat") as! CLLocationDegrees
                let startLong = video.value(forKey: "startLong") as! CLLocationDegrees
                let endLat = video.value(forKey: "endLat") as! CLLocationDegrees
                let endLong = video.value(forKey: "endLong") as! CLLocationDegrees

                let obj = Video(started: date, imageData: thumbnailData, id: id, length: length, size: size, startLoc: CLLocationCoordinate2D(latitude: startLat, longitude: startLong), endLoc: CLLocationCoordinate2D(latitude: endLat, longitude: endLong))
                obj.updateUploadInProgress(status: true)
                DashiAPI.uploadVideoMetaData(video: obj).then { _ -> Void in
                    DashiAPI.uploadVideoContent(id: id, url: getUrlForLocal(id: id)!).then { _ -> Void in
                        obj.changeStorageToBoth()
                        obj.updateUploadInProgress(status: false)
                    }
                }
            }
        }
    }

    // creates url for video content in local db given id
    private static func getUrlForLocal(id: String) -> URL? {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }

        // Get coredata context
        let managedContext = appDelegate.persistentContainer.viewContext

        // 2
        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["videoContent", "id"]
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id, (sharedAccount?.getId())!)

        // 3
        var content: [NSManagedObject]
        do {
            content = (try managedContext.fetch(fetchRequest))
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

    static func performBackgroundTasks() {
        if sharedAccount != nil {
            var settings = sharedAccount!.getSettings()
            print("BACKGROUND TASK: Beginning...")
            print("BACKGROUND TASK: Loading User Settings...")
            VideoManager.retensionCheck(settings: settings)
            VideoManager.uploadCheck(settings: settings)
            print("BACKGROUND TASK: Finished...")
        } else {
            print("BACKGROUND TASK: Not logged in, nothing to process")
        }
    }

    static func getBackgroundTaskTimer() -> RepeatingTimer {
        return RepeatingTimer(repeating: .seconds(15)) {
            VideoManager.performBackgroundTasks()
        }
    }

    // Handle max storage case by flushing all or auto
    static func flushCache(ignoreDownloaded: Bool = true) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // Get coredata context
        let managedContext = appDelegate.persistentContainer.viewContext

        // Load video dates and upload status
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.propertiesToFetch = ["id", "uploadProgress", "size", "downloaded"]
        fetchRequest.predicate = NSPredicate(format: "videoContent != nil  && accountID == %d", (sharedAccount?.getId())!)

        var videos: [NSManagedObject] = []
        do {
            videos = (try managedContext.fetch(fetchRequest))
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }

        for video in videos {
            // If completely uploaded, delete cached content
            let temp = video.value(forKey: "downloaded") as? Date
            if (video.value(forKey: "uploadProgress") as! Int32) == 100 &&
                (ignoreDownloaded || (video.value(forKey: "downloaded") as? Date) == nil) {
                
                // Calculate uploaded date based cutoff
                let downloadDate = video.value(forKey: "uploadDate") as? Date
                var dayComp = DateComponents()
                dayComp.second = 30
                let downloadedCutoffDate = Calendar.current.date(byAdding: dayComp, to: downloadDate!)
                //Calendar.current.component(.weekday, from: downloadedCutoffDate!)
                
                let now = Date()
                if(downloadedCutoffDate! < now) {
                    // Delete the cached video content
                    video.setValue(nil, forKey: "videoContent")
                    video.setValue(nil, forKey: "downloaded")
                    video.setValue(nil, forKey: "downloadProgress")
                    video.setValue("cloud", forKey: "storageStat")
                    do {
                        try managedContext.save()
                    } catch let error as NSError {
                        print("Could not fetch. \(error), \(error.localizedDescription)")
                    }
                }
            }
        }
    }
}
