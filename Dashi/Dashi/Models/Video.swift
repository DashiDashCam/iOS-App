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

class Video {
    
    // Protected members
    var content: AVURLAsset?
    var started: Date
    var length: Int
    var size: Int
    var id: Int
    
    init(id: Int, started: Date, length: Int, size: Int, content: AVURLAsset? = nil) {
        self.id = id
        self.started = started
        self.length = length
        self.size = size
        self.content = content!
    }
    
    init(video: JSON) {
<<<<<<< Updated upstream
        self.id = video["id"].intValue
        self.started = Date().addingTimeInterval(video["started"].doubleValue)
=======
        self.id = video["id"].string
        self.started = DateConv.toDate(timestamp: video["started"].stringValue)
>>>>>>> Stashed changes
        self.length = video["length"].intValue
        self.size = video["size"].intValue
    }
    
    public func setContent(content: AVURLAsset) {
        self.content = content
    }
    
    public func getContent() -> AVURLAsset {
        return self.content!
    }
    
    public func getStarted() -> Date {
        return self.started
    }
    
    public func getLength() -> Int {
        return self.length
    }
    
    public func getSize() -> Int {
        return self.size
    }
    
    public func getId() -> Int {
        return self.id
    }
}
