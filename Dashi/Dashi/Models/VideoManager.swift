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

class VideoManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    static var shared = VideoManager()
    
    typealias ProgressHandler = (Float) -> ()
    
    var onProgress : ProgressHandler? {
        didSet {
            if onProgress != nil {
                let _ = activate()
            }
        }
    }
    
    override private init() {
        super.init()
    }
    
    func activate() -> URLSession {
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
        
        // Warning: If an URLSession still exists from a previous download, it doesn't create a new URLSession object but returns the existing one with the old delegate object attached!
        return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())
    }
    
    private func calculateProgress(session : URLSession, completionHandler : @escaping (Float) -> ()) {
        session.getTasksWithCompletionHandler { (tasks, uploads, downloads) in
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
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        
        if totalBytesExpectedToWrite > 0 {
            if let onProgress = onProgress {
                calculateProgress(session: session, completionHandler: onProgress)
            }
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            debugPrint("Progress \(downloadTask) \(progress)")
            
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        try? FileManager.default.removeItem(at: location)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
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
        fetchRequest.predicate = NSPredicate(format: "videoContent != nil")
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
            if startCutoffDate! < now && (downloadDate == nil || downloadedCutoffDate! < now)  {
                // Delete the cached video content
                video.setValue(nil, forKey: "videoContent")
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.localizedDescription)")
                }
            }
            else {
                totalSize += (video.value(forKey: "size") as! Int64)
            }
        }
        
        // Enforce max file size
        if totalSize > (settings["maxLocalStorage"] as! Int) {
            VideoManager.flushCache()
        }
    }
    
    private static func uploadCheck(settings: Dictionary<String, Any>) {
        print("BACKGROUND TASK: Beginning Upload Check...")
        
        //        // Find videos that need to be uploaded
        //        guard let appDelegate =
        //            UIApplication.shared.delegate as? AppDelegate else {
        //                return
        //        }
        //
        //        // Get coredata context
        //        let managedContext = appDelegate.persistentContainer.viewContext
        //
        //        // Load video dates and upload status
        //        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Videos")
        //        fetchRequest.propertiesToFetch = ["id", "uploadProgress", "size", "downloaded"]
        //        fetchRequest.predicate = NSPredicate(format: "videoContent != nil")
        //
        //        var videos: [NSManagedObject] = []
        //        do {
        //            videos = (try managedContext.fetch(fetchRequest))
        //        } catch let error as Error {
        //            print("Could not fetch. \(error), \(error.localizedDescription)")
        //        }
        //
        //        // Schedule upload tasks
        //        for video in videos {
        //
        //        }
    }
    
    static func performBackgroundTasks() {
        if sharedAccount != nil {
            var settings = sharedAccount!.getSettings()
            print("BACKGROUND TASK: Beginning...")
            print("BACKGROUND TASK: Loading User Settings...")
            VideoManager.retensionCheck(settings: settings)
            VideoManager.uploadCheck(settings: settings)
            print("BACKGROUND TASK: Finished...")
        }
        else {
            print("BACKGROUND TASK: Not logged in, nothing to process")
        }
    }
    
    static func getBackgroundTaskTimer() -> RepeatingTimer {
        return RepeatingTimer(repeating: .seconds(1)) {
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
        fetchRequest.predicate = NSPredicate(format: "videoContent != nil")
        
        var videos: [NSManagedObject] = []
        do {
            videos = (try managedContext.fetch(fetchRequest))
        } catch let error as Error {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        
        for video in videos {
            // If completely uploaded, delete cached content
            if (video.value(forKey: "size") as! Int32) - (video.value(forKey: "uploadProgress") as! Int32) == 0 &&
                (ignoreDownloaded || (video.value(forKey: "downloaded") as? Date) != nil) {
                // Delete the cached video content
                video.setValue(nil, forKey: "videoContent")
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not fetch. \(error), \(error.localizedDescription)")
                }
            }
        }
    }
}


