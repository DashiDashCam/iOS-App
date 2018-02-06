//
//  Video.swift
//  Dashi
//
//  Created by Chris Henk on 1/25/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation
import AVKit
import SwiftyJSON
import Arcane

class Video {

    // Protected members
    var asset: AVURLAsset?
    var started: Date
    var length: Int
    var size: Int
    var thumbnail: UIImage!
    var id: String?

    /**
     *  Initializes a Video object. Note that ID is initialized
     *  from the SHA256 hash of the content of the video
     */
    init(started: Date, asset: AVURLAsset) {
        do {
            // get the data associated with the video's content and convert it to a string
            let contentData = try Data(contentsOf: asset.url)
            let contentString = String(data: contentData, encoding: String.Encoding.ascii)
contentData.hashValue
            length = Int(Float((asset.duration.value)) / Float((asset.duration.timescale)))
            size = contentData.count

            // hash the video content to produce an ID
            id = Hash.SHA256(contentString!)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            
            let cgImage = try! imgGenerator.copyCGImage(at: CMTimeMake(0, 6), actualTime: nil)
            // !! check the error before proceeding
            thumbnail = UIImage(cgImage: cgImage)
        } catch let error {
            print("Could not create video object. \(error)")

            self.length = -1
            self.size = -1
        }

        // initialize other instances variables
        self.asset = asset
        self.started = started
    }
    
    init(video: JSON) {
        id = video["id"].stringValue
        started = DateConv.toDate(timestamp: video["started"].stringValue)
        length = video["length"].intValue
        size = video["size"].intValue
    }
    init(started: Date, imageData: Data, id:String, length: Int, size:Int){
        self.id = id
        self.started = started
        self.thumbnail = UIImage(data: imageData)
        self.length = length
        self.size = size
    }
    public func getContent() -> Data? {
        do {
            return try Data(contentsOf: asset!.url)
        } catch let error {
            print("Could not get video content. \(error)")
        }

        return nil
    }

    public func getImageContent() -> Data? {
            return UIImageJPEGRepresentation(thumbnail, 0.5)
        }
    public func setAsset(asset: AVURLAsset) {
        self.asset = asset
    }

    public func getAsset() -> AVURLAsset {
        return asset!
    }

    public func getStarted() -> Date {
        return started
    }

    public func getLength() -> Int {
        return length
    }

    public func getSize() -> Int {
        return size
    }

    public func getId() -> String {
        return id!
    }
    
    public func getThumbnail() -> UIImage {
        return thumbnail
    }
}
