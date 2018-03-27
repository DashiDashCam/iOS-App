//
//  FileManager.swift
//  Dashi
//
//  Created by Chris Henk on 3/27/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation

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
        print("BACKGROUND TASK: Beginning Retentsion Check...")
        
    }
    
    private static func uploadCheck(settings: Dictionary<String, Any>) {
        print("BACKGROUND TASK: Beginning Upload Check...")
    }
    
    static func performBackgroundTasks() {
        if DashiAPI.isLoggedIn() {
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
}


