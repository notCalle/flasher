//
//  ImageWriter.swift
//  flasher
//
//  Created by Calle Englund on 2019-10-27.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Pathos

/// Handle the details of writing an image
struct ImageWriter {
    var decompress = false
    var verify = false

    private let stderr = FileHandle.standardError

    private let chunkSize = 128*1024
    private let fileHandle: FileHandle
    private let imageSize: UInt64
    private var writtenSize: UInt64 = 0

    /// Initialize image writer for a file at path
    /// - Parameter image: path to image file
    init(for path: Path) throws {
        let imagePath = String(describing: try path.absolute())
        let fileManager = FileManager()
        let fileAttr = try fileManager.attributesOfItem(atPath: imagePath)

        imageSize = fileAttr[.size] as! UInt64
        fileHandle = FileHandle(forReadingAtPath: imagePath)!
        precondition(fcntl(fileHandle.fileDescriptor, F_NOCACHE, 1) != -1)
    }

    /// Write the image to a target file handle
    /// - Parameter target: file handle to write image to
    func writeImage(using target: DeviceController) throws {
        let startTime = Date()

        if decompress {
            throw DeviceControllerError.notImplemented("decompression");
        }

        defer {
            stderr <<< "\n"
            try? stderr.synchronize()
        }

        for chunk in fileHandle.blocks(ofSize: chunkSize) {
            try target.write(chunk)
            let elapsedTime = DateInterval(start: startTime, end: Date())
            progressBar(for: fileHandle.offsetInFile, of: imageSize,
                        in: elapsedTime.duration)
        }

        try target.synchronize()

        if verify {
            try verifyImage(using: target)
        }
    }

    private func verifyImage(using target: DeviceController) throws {
        let startTime = Date()

        if #available(OSX 10.15, *) {
            try fileHandle.seek(toOffset: 0)
        } else {
            fileHandle.seek(toFileOffset: 0)
        }
        try target.rewind()

        let sourceBlocks = fileHandle.blocks(ofSize: chunkSize)
        let targetBlocks = try target.blocks(ofSize: chunkSize)

        for (source, target) in zip(sourceBlocks, targetBlocks) {
            if !source.elementsEqual(target[0 ..< source.count]) {
                throw DeviceControllerError.verifyFailed
            }

            let elapsedTime = DateInterval(start: startTime, end: Date())

            progressBar(for: fileHandle.offsetInFile, of: imageSize,
                        in: elapsedTime.duration,
                        done: "+", todo: "-")
        }
    }

    private func progressBar(for bytes: UInt64, of total: UInt64,
                             in seconds: Double,
                             done: String = "-",
                             todo: String = " ")
    {
        let percent = Double(bytes) / Double(total)
        let bar = String(repeating: done, count: Int(percent * 50))
        let filler = String(repeating: todo, count: 50)
        let writeSpeed = Int64(Double(bytes) / seconds)
        let byteCount = ByteCountFormatter.string(fromByteCount: writeSpeed,
                                                  countStyle: .file)

        stderr <<< "\r[\(filler)] \(byteCount)/s   \r[\(bar)"
        try? stderr.synchronize()
    }
}
