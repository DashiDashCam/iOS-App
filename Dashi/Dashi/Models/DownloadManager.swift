// Copyright 2017, Ralf Ebert
// License   https://opensource.org/licenses/MIT
// Source    https://www.ralfebert.de/snippets/ios/urlsession-background-downloads/

import Foundation

class DownloadManager : NSObject, URLSessionDelegate, URLSessionDownloadDelegate {
    
    static var shared = DownloadManager()
    
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
        /* BEGIN MODIFIED PORTION [Author: Chris Henk] */
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background.download")
        config.httpAdditionalHeaders = ["Host": "api.dashidashcam.com"]
        /* END MODIFIED PORTION */
        
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
    
}


