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

    private let chunksize = 1024*1024
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
    }

    /// Write the image to a target file handle
    /// - Parameter target: file handle to write image to
    func writeImage(to target: FileHandle) throws {
        let startTime = Date()
        let startOffset = target.offsetInFile

        if decompress {
            throw DeviceControllerError.notImplemented("decompression");
        }

        eachChunk { writeBuffer in
            target.write(writeBuffer)
            let elapsedTime = DateInterval(start: startTime, end: Date())
            progressBar(for: fileHandle.offsetInFile, of: imageSize,
                        in: elapsedTime.duration)
        }

        if #available(OSX 10.15, *) {
            try target.synchronize()
        } else {
            target.synchronizeFile()
        }

        if verify {
            if #available(OSX 10.15, *) {
                try target.seek(toOffset: startOffset)
            } else {
                target.seek(toFileOffset: startOffset)
            }
            try verifyImage(with: target)
        }

        stderr <<< "\n"
        try? stderr.synchronize()
    }

    func verifyImage(with target: FileHandle) throws {
        let startTime = Date()

        if #available(OSX 10.15, *) {
            try fileHandle.seek(toOffset: 0)
        } else {
            fileHandle.seek(toFileOffset: 0)
        }

        try eachChunk { verifyBuffer in
            let targetBuffer = target.readData(ofLength: verifyBuffer.count)
            if !verifyBuffer.elementsEqual(targetBuffer) {
                stderr <<< "\n"
                try? stderr.synchronize()
                throw DeviceControllerError.verifyFailed
            }

            let elapsedTime = DateInterval(start: startTime, end: Date())

            progressBar(for: fileHandle.offsetInFile, of: imageSize,
                        in: elapsedTime.duration,
                        done: "+", todo: "-")
        }
    }

    private func eachChunk(perform: (_ chunk: Data) throws -> ()) rethrows {
        let globalQueue = DispatchQueue.global(qos: .userInitiated)
        let readQueue = DispatchQueue(label: "Image read queue",
                                      target: globalQueue)
        var buffer: Data?

        readQueue.async { buffer = self.readChunk() }

        while readQueue.sync(execute: { buffer!.count > 0 }) {
            let chunk = buffer!
            readQueue.async { buffer = self.readChunk() }

            try perform(chunk)
        }
    }

    private func readChunk() -> Data {
        return fileHandle.readData(ofLength: chunksize)
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
