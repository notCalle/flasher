//
//  DeviceController.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-10.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

/// Device Controller errors
enum DeviceControllerError: Error {
    case notImplemented
    case notExternal(String)
    case notPhysical(String)
    case notSafe(String)
    case notWritable(String)
    case errno(errno_t)
    case tooSmall(String, Int64, Int64)
    case verifyFailed
}
extension DeviceControllerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notImplemented:
            return "Not Implemented"
        case .notExternal(let disk):
            return "\"" + disk + "\" is not external"
        case .notPhysical(let disk):
            return "\"" + disk + "\" is not physical"
        case .notSafe(let disk):
            return "\"" + disk + "\" is not safe (force to override)"
        case .notWritable(let disk):
            return "\"" + disk + "\" is not writable"
        case.errno(let err):
            return "errno(" + String(err) + ")"
        case .tooSmall(let disk, let dsize, let isize):
            let diskSize = ByteCountFormatter.string(fromByteCount: dsize,
                                                     countStyle: .file)
            let imageSize = ByteCountFormatter.string(fromByteCount: isize,
                                                      countStyle: .file)

            return "\(disk) is too small (\(diskSize)) for image (\(imageSize))"
        case .verifyFailed:
            return "verification failed"
        }
    }
}

/// Controller for disk device operations
struct DeviceController {
    let disk: String
    let info: DiskInfo

    /// Initialize device controller
    ///
    /// The target disk is validated against some safety rules, unless forced.
    ///
    /// - Throws: `DeviceControllerError`
    /// - Parameter device: target disk identifier
    /// - Parameter force: allow unsafe targets
    init(for device: String, force: Bool = false) throws {
        disk = device
        info = try DiskInfo(for: disk)

        try validate(forced: force)
        try umountDisk()
    }

    /// Write image to target
    ///
    /// - Throws: `DeviceControllerError`
    /// - Throws:
    /// - Parameter image: path to image file
    /// - Parameter verify: perform read verification after writing
    public func write(image: AbsolutePath, verify: Bool = false) throws {
        let fileManager = FileManager()
        let fileAttr = try fileManager.attributesOfItem(atPath: image.pathString)
        let fileSize = fileAttr[.size] as! Int64

        if info.size < fileSize {
            throw DeviceControllerError.tooSmall(disk, info.size, fileSize)
        }

        let chunksize = 1024*1024
        guard let inputFH = FileHandle(forReadingAtPath: image.pathString) else {
            throw DeviceControllerError.errno(errno)
        }

        let output = AbsolutePath("/dev/r\(disk)")
        let outputFH = try AuthOpen(forWritingAtPath: output.pathString).fileHandle

        let startTime = Date()
        var copySoFar: Int64 = 0

        let readQueue = DispatchQueue(label: "flasher_read_queue")
        var buffer = Data()

        readQueue.async {
            buffer = inputFH.readData(ofLength: chunksize)
        }

        while readQueue.sync(execute: { return buffer.count > 0 }) {
            let wrbuf = buffer

            readQueue.async {
                buffer = inputFH.readData(ofLength: chunksize)
            }
            outputFH.write(wrbuf)
            copySoFar += Int64(wrbuf.count)

            let elapsedTime = DateInterval(start: startTime, end: Date())

            progressBar(for: copySoFar, of: fileSize, in: elapsedTime.duration)
        }
        if #available(OSX 10.15, *) {
            try outputFH.synchronize()
        } else {
            outputFH.synchronizeFile()
        }

        if verify { try self.verify(image: image, with: outputFH) }
    }

    /// Verify that image was correctly written to target
    ///
    /// - Throws: `DeviceControllerError`
    /// - Parameter image: path to image file
    public func verify(image path: AbsolutePath) throws {
        let fileHandle =
            try AuthOpen(forReadingAtPath: "/dev/r\(disk)").fileHandle

        try verify(image: path, with: fileHandle)
    }

    private func verify(image: AbsolutePath, with verifyFH: FileHandle) throws {
        let fileManager = FileManager()
        let fileAttr = try fileManager.attributesOfItem(atPath: image.pathString)
        let fileSize = fileAttr[.size] as! Int64
        let chunksize = 1024*1024

        guard let inputFH = FileHandle(forReadingAtPath: image.pathString) else {
            throw DeviceControllerError.errno(errno)
        }

        let startTime = Date()
        var verifySoFar: Int64 = 0

        let readQueue = DispatchQueue(label: "flasher_read_queue")
        var buffer = Data()

        readQueue.async {
            buffer = inputFH.readData(ofLength: chunksize)
        }

        verifyFH.seek(toFileOffset: 0)
        while readQueue.sync(execute: { return buffer.count > 0 }) {
            let rdbuf = buffer

            readQueue.async {
                buffer = inputFH.readData(ofLength: chunksize)
            }
            let vfbuf = verifyFH.readData(ofLength: rdbuf.count)
            if !rdbuf.elementsEqual(vfbuf) {
                stderrStream <<< "\n"
                stderrStream.flush()
                throw DeviceControllerError.verifyFailed
            }
            verifySoFar += Int64(rdbuf.count)

            let elapsedTime = DateInterval(start: startTime, end: Date())

            progressBar(for: verifySoFar, of: fileSize, in: elapsedTime.duration,
                        done: "+", todo: "-")
        }
    }

    private func progressBar(for bytes: Int64, of total: Int64,
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

        stderrStream <<< "\r[\(filler)] \(byteCount)/s   \r[\(bar)"
        stderrStream.flush()
    }

    private func validate(forced: Bool) throws {
        // Safeguard checks, ignored if forced
        if !forced {
            if !info.safe {
                throw DeviceControllerError.notSafe(disk)
            }
            if info.virtualOrPhysical != .physical {
                throw DeviceControllerError.notPhysical(disk)
            }
        }

        if !info.writableMedia {
            throw DeviceControllerError.notWritable(disk)
        }
    }

    private func umountDisk() throws {
        try Process.checkNonZeroExit(arguments: [
            "diskutil", "umountDisk", disk
        ])
    }
}
