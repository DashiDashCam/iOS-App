//
//  TempFile.swift
//  Dashi
//
//  Created by Chris Henk on 4/2/18.
//  Copyright © 2018 Senior Design. All rights reserved.
//

import Foundation

/**
 *  Author: Victor Pavlychko
 *  Taken from: https://gist.github.com/victor-pavlychko/b991c265f872f080447dcdda1fdc16c5#file-managing_temporary_files_managedurl-swift
 */
public protocol ManagedURL {
    var contentURL: URL { get }
    func keepAlive()
}

public extension ManagedURL {
    public func keepAlive() {}
}

extension URL: ManagedURL {
    public var contentURL: URL { return self }
}

/**************************************************************/

/**
 *  Author: Victor Pavlychko
 *  Taken from: https://gist.github.com/victor-pavlychko/d0ca3cf9264a5707a7544d46ee913493#file-managing_temporary_files_temporaryfileurl-swift
 */
public final class TemporaryFileURL: ManagedURL {

    public let contentURL: URL

    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }

    deinit {
        DispatchQueue.global(qos: .utility).async { [contentURL = self.contentURL] in
            try? FileManager.default.removeItem(at: contentURL)
        }
    }
}

/**************************************************************/

public final class TempFile {

    public let tmpFileURL: TemporaryFileURL

    public init(extension ext: String, content: Data) {
        tmpFileURL = TemporaryFileURL(extension: ext)
        FileManager.default.createFile(atPath: tmpFileURL.contentURL.absoluteString, contents: content)
    }
}
