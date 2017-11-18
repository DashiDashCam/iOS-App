//
//  CloudManager.swift
//  Dashi
//
//  Created by Eric Smith on 11/7/17.
//  Copyright © 2017 Senior Design. All rights reserved.
//

import Foundation

// this class exists to serve as the model between the application and the cloud video storage

class CloudManager {
    private static let API_URL = "http://api.dashidashcam.com/Video"

    static func pushToCloud(file: String, timestamp: String, size: Int, length: Int) {
        let jsonEncoder = JSONEncoder()

        let headers = [
            "content-type": "multipart/form-data; boundary=----WebKitFormBoundary7MA4YWxkTrZu0gW",
            "cache-control": "no-cache",
        ]
        let parameters = [
            [
                "name": "video",
                "content": try! String(contentsOfFile: file, encoding: String.Encoding.utf8),
                "content-type": "video/mpeg",
            ],
            [
                "name": "metadata",
                "content": [
                    "started": timestamp,
                    "size": size,
                    "length": length,
                ],
                "content-type": "application/json",
            ],
        ]

        let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"

        var body = ""
        var error: NSError?
        for param in parameters {
            let paramName = param["name"]!
            body += "--\(boundary)\r\n"
            body += "Content-Disposition:form-data; name=\"\(paramName)\""
            if let filename = param["fileName"] {
                let contentType = param["content-type"]!
                let fileContent = param["content"]
                if error != nil {
                    print(error)
                }
                body += "; filename=\"\(filename)\"\r\n"
                body += "Content-Type: \(contentType)\r\n\r\n"
                body += fileContent as! String
            } else if let paramValue = param["value"] {
                body += "\r\n\r\n\(paramValue)"
            }
        }

        let request = NSMutableURLRequest(url: NSURL(string: API_URL)! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        //        request.httpBody = postData as Data

        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (_, response, error) -> Void in
            if error != nil {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })

        dataTask.resume()
    }
}
