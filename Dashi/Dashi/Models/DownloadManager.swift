// Copyright 2017, Ralf Ebert
// License   https://opensource.org/licenses/MIT
// Source    https://www.ralfebert.de/snippets/ios/urlsession-background-downloads/

import Foundation
import CoreData
import UIKit

class DownloadManager: NSObject, URLSessionDelegate, URLSessionDownloadDelegate {

    static var shared = DownloadManager()

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
        /* BEGIN MODIFIED PORTION [Author: Chris Henk] */
        let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background.download")
        config.httpAdditionalHeaders = ["Host": "api.dashidashcam.com"]
        /* END MODIFIED PORTION */

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
            updateDownloadProgress(id: downloadTask.taskDescription!, progress: Int(progress * 100))
        }
    }

    func urlSession(_: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        debugPrint("Download finished: \(location)")
        print(downloadTask.taskDescription!)
        updateDownloadProgress(id: downloadTask.taskDescription!, progress: 100)
        saveVideoToCoreDB(id: downloadTask.taskDescription!, file: location)
        try? FileManager.default.removeItem(at: location)
    }

    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        debugPrint("Task completed: \(task), error: \(error)")
    }

    private func updateDownloadProgress(id: String, progress: Int) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        // coredata context
        let managedContext =
            appDelegate.persistentContainer.viewContext

        let fetchRequest =
            NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id, (sharedAccount?.getId())!)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let video = result[0]

        video.setValue(progress, forKey: "downloadProgress")

        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }

    private func saveVideoToCoreDB(id: String, file: URL) {
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        let managedContext = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Videos")
        fetchRequest.predicate = NSPredicate(format: "id == %@  && accountID == %d", id, (sharedAccount?.getId())!)
        var result: [NSManagedObject] = []
        // 3
        do {
            result = (try managedContext.fetch(fetchRequest))
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.localizedDescription)")
        }
        let video = result[0]
        do {
            let val = try Data(contentsOf: file)
            // let string1 = String(data: val, encoding: String.Encoding.utf8) ?? "Data could not be printed"
            // print(string1)
            video.setValue(val, forKey: "videoContent")
            video.setValue(Date(), forKey: "downloaded")
            video.setValue("both", forKey: "storageStat")
            video.setValue(false, forKey: "downloadInProgress")
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        } catch let error as NSError {
            print("Could not load downloaded file. \(error), \(error.userInfo)")
        }
    }
}
