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
    var content: AVURLAsset?
    var started: Date
    var length: Int
    var size: Int
    var id: String?

    /**
     *  Initializes a Video object. Note that ID is initialized
     *  from the SHA256 hash of the content of the video
     */
    init(started: Date, content: AVURLAsset) {
        do {
            // get the data associated with the video's content and convert it to a string
            let contentData = try Data(contentsOf: content.url)
            let contentString = String(data: contentData, encoding: String.Encoding.ascii)

            length = Int(Float((content.duration.value)) / Float((content.duration.timescale)))
            size = contentData.count

            // hash the video content to produce an ID
            id = Hash.SHA256(contentString!)

        } catch let error {
            print("Could not create video object. \(error)")

            self.length = -1
            self.size = -1
        }

        // initialize other instances variables
        self.content = content
        self.started = started
    }

    init(video: JSON) {
        self.id = video["id"].intValue
        self.started = DateConv.toDate(timestamp: video["started"].stringValue)
        self.length = video["length"].intValue
        self.size = video["size"].intValue
    }

    public func setContent(content: AVURLAsset) {
        self.content = content
    }

    public func getContent() -> AVURLAsset {
        return content!
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
}
