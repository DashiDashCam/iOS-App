//
//  VideoPreviewViewController.swift
//  Dashi
//
//  Created by Eric Smith on 10/20/17.
//  Copyright © 2017 Dashi. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class VideoPreviewViewController: UIViewController {

    // keys to ensure playability of video
    static let assetKeysRequiredToPlay = ["playable", "hasProtectedContent"]

    //    let cloudURL = "http://api.dashidashcam.com/Videos/id/content"
    let cloudURL = "https://private-anon-1a08190e46-dashidashcam.apiary-mock.com/Videos/id"

    // player for playing the AV asset1
    @objc dynamic var player = AVPlayer()

    // the GMT timestamp of when the video ended
    var videoEndTimestamp = Date()

    /*
     * set the file location of the video being shown
     * Note: Setting this triggers a chain of reactions to load the media
     */
    var fileLocation: URL? {
        didSet {
            asset = AVURLAsset(url: fileLocation!)
        }
    }

    // set video asset and load it
    var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }
            loadURLAsset(newAsset)
        }
    }

    // the layer the player is on
    var playerLayer: AVPlayerLayer? {
        return playerView.playerLayer
    }

    // replace any item being played with the current item
    var playerItem: AVPlayerItem? {
        didSet {
            player.replaceCurrentItem(with: self.playerItem)
            player.actionAtItemEnd = .none
        }
    }

    @IBOutlet weak var playerView: PlayerView! // where video actually displays
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var playPauseButton: UIButton!
    @IBOutlet weak var pushToCloudButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        // observer for the status of the current item
        addObserver(self, forKeyPath: "player.currentItem.status", options: .new, context: nil)

        addObserver(self, forKeyPath: "player.rate", options: [.new, .initial], context: nil)

        // trigger notification if the video plays till the end
        NotificationCenter.default.addObserver(self, selector: #selector(playerReachedEnd(notification:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)

        // set the player layer to the AVPlayer object
        self.playerView.playerLayer.player = player
    }

    // remove the observers from viewDidLoad()
    override func viewWillDisappear(_: Bool) {
        removeObserver(self, forKeyPath: "player.currentItem.status", context: nil)
        removeObserver(self, forKeyPath: "player.rate", context: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Main

    // asynchrounous loading of asset file to prepare for playback
    func loadURLAsset(_ asset: AVURLAsset) {
        // load AVURLAsset
        asset.loadValuesAsynchronously(forKeys: VideoPreviewViewController.assetKeysRequiredToPlay) {
            DispatchQueue.main.async {
                guard asset == self.asset else { return }
                // check to ensure the asset can be played
                for key in VideoPreviewViewController.assetKeysRequiredToPlay {
                    var error: NSError?

                    // asset can't be played
                    if !asset.isPlayable || asset.hasProtectedContent {
                        let message = "Video is not playable."
                        self.showAlert(title: "Error", message: message, dismiss: false)

                        return
                    }

                    // asset couldn't load
                    if asset.statusOfValue(forKey: key, error: &error) == .failed {
                        let message = "Failed to load"
                        self.showAlert(title: "Error", message: message, dismiss: false)

                        return
                    }
                }

                self.playerItem = AVPlayerItem(asset: asset)
            }
        }
    }

    // MARK: Actions
    @IBAction func closePreview() {
        self.dismiss(animated: true, completion: nil)
    }

    @IBAction func saveToLibrary() {
        self.saveVideoToUserLibrary()
    }

    @IBAction func playPauseButtonPressed() {
        self.updatePlayPauseButton()
    }

    @IBAction func pushToCloud() {
        // set up the initial request: header information
        var request = URLRequest(url: URL(string: self.cloudURL)!)
        request.httpMethod = "PUT"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        // the duration of the video
        let movieLength = Float((asset?.duration.value)!) / Float((asset?.duration.timescale)!)

        // when the video started
        let movieStart = self.videoEndTimestamp.addingTimeInterval(TimeInterval(-1 * movieLength))

        print("duration: \(movieLength) seconds")
        print("size: \(asset?.fileSize ?? 0)")
        print("start: \(movieStart)")

        // convert the headers to JSON
        let headers: [String: Any] = [
            "started": String(describing: movieStart),
            "length": String(describing: movieLength),
            "size": String(describing: asset?.fileSize),
        ]

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: headers, options: .prettyPrinted)
            // here "jsonData" is the dictionary encoded in JSON data
            // nsdata.contentsof(url)

            print(jsonData)
        } catch {
            print(error.localizedDescription)
        }
    }

    // MARK: Callbacks

    // check for status of observers
    override func observeValue(forKeyPath keyPath: String?,
                               of _: Any?,
                               change _: [NSKeyValueChangeKey: Any]?,
                               context _: UnsafeMutableRawPointer?) {
        // player is ready
        if keyPath == "player.currentItem.status" {
            // make buttons visible to user
            playPauseButton.isHidden = false
            saveButton.isHidden = false
        }
    }

    // player made it to the end of the video
    @objc func playerReachedEnd(notification _: NSNotification) {
        // restart video
        self.asset = AVURLAsset(url: self.fileLocation!)
        self.updatePlayPauseButton()
    }

    // MARK: Helpers

    // save the video to the user's library
    func saveVideoToUserLibrary() {
        PhotoManager().saveVideoToUserLibrary(fileUrl: self.fileLocation!) { success, error in
            if success {
                self.showAlert(title: "Success", message: "Video saved.", dismiss: true)
            } else {
                self.showAlert(title: "Error", message: (error?.localizedDescription)!, dismiss: false)
            }
        }
    }

    // shows alert to user
    func showAlert(title: String, message: String, dismiss: Bool) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)

        if dismiss {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
        } else {
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        }

        self.present(controller, animated: true, completion: nil)
    }

    // update image in Play/Pause button, play and pause video
    func updatePlayPauseButton() {
        if player.rate > 0 {
            player.pause()
            playPauseButton.setImage(UIImage(named: "play"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(named: "pause"), for: .normal)
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

// returns the size in bytes of a AVURLAsset
extension AVURLAsset {
    var fileSize: Int? {
        let keys: Set<URLResourceKey> = [.totalFileSizeKey, .fileSizeKey]
        let resourceValues = try? url.resourceValues(forKeys: keys)

        return resourceValues?.fileSize ?? resourceValues?.totalFileSize
    }
}
