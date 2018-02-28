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
import CoreLocation
import MapKit

class Video {

    // Protected members
    var asset: AVURLAsset?
    var started: Date
    var length: Int
    var size: Int
    var thumbnail: UIImage!
    var id: String?
    var storageStat: String!
    var startLat: CLLocationDegrees!
    var endLat: CLLocationDegrees!
    var startLong: CLLocationDegrees!
    var endLong: CLLocationDegrees!

    /**
     *  Initializes a Video object. Note that ID is initialized
     *  from the SHA256 hash of the content of the video
     */
    init(started: Date, asset: AVURLAsset, startLoc: CLLocationCoordinate2D, endLoc: CLLocationCoordinate2D) {
        do {
            // get the data associated with the video's content and convert it to a string
            let contentData = try Data(contentsOf: asset.url)
            let contentString = String(data: contentData, encoding: String.Encoding.ascii)
            length = Int(Float((asset.duration.value)) / Float((asset.duration.timescale)))
            size = contentData.count
            startLat = startLoc.latitude
            startLong = startLoc.longitude
            endLat = endLoc.latitude
            endLong = endLoc.longitude
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
        thumbnail = UIImage(data: Data(base64Encoded: video["thumbnail"].stringValue)!)
        startLat = video["startLat"].doubleValue
        startLong = video["startLong"].doubleValue
        endLat = video["endLat"].doubleValue
        endLong = video["endLong"].doubleValue
        storageStat = "cloud"
    }

    init(started: Date, imageData: Data, id: String, length: Int, size: Int, startLoc: CLLocationCoordinate2D, endLoc: CLLocationCoordinate2D) {
        self.id = id
        self.started = started
        thumbnail = UIImage(data: imageData)
        self.length = length
        self.size = size
        storageStat = "local"
        startLat = startLoc.latitude
        startLong = startLoc.longitude
        endLat = endLoc.latitude
        endLong = endLoc.longitude
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

    public func getStorageStat() -> String {
        return storageStat!
    }

    public func changeStorageToBoth() {
        storageStat = "both"
    }

    public func getStartLat() -> CLLocationDegrees {
        return startLat
    }

    public func getStartLong() -> CLLocationDegrees {
        return startLong
    }

    public func getEndLat() -> CLLocationDegrees {
        return endLat
    }

    public func getEndLong() -> CLLocationDegrees {
        return endLong
    }

    public func getStartLocation() -> String {
        return getLocation(lattitude: startLat, longitude: startLong)
    }

    public func getEndLocation() -> String {
        return getLocation(lattitude: endLat, longitude: endLong)
    }

    // helper function to get the location (in string format) given a lattitude and longitude
    private func getLocation(lattitude: CLLocationDegrees, longitude: CLLocationDegrees) -> String {
        var locString = "Location not found"

        let geoCoder = CLGeocoder()
        let loc = CLLocation(latitude: lattitude, longitude: longitude)

        geoCoder.reverseGeocodeLocation(loc) { placemarks, error in
            if let e = error {
                print("Error finding location: ")
                print(e)
            } else {
                let placeArray = placemarks as [CLPlacemark]!
                var placeMark: CLPlacemark!
                placeMark = placeArray![0]

                locString = placeMark.locality! + ", " + placeMark.country!
            }
        }

        return locString
    }
}
