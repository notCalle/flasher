//
//  DeviceController.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-10.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

enum DeviceControllerError: Error {
    case notImplemented
    case notExternal(String)
    case notPhysical(String)
    case notRemovable(String)
    case notWritable(String)
    case errno(errno_t)
    case tooSmall(String, Int64, Int64)
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
        case .notRemovable(let disk):
            return "\"" + disk + "\" is not removable"
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
        }
    }
}

struct DeviceController {
    let disk: String
    let info: DiskInfo

    init(for device: String, force: Bool = false) throws {
        disk = device
        info = try DiskInfo(for: disk)

        try validate(forced: force)
        try umountDisk()
    }

    public func write(image: AbsolutePath, verify: Bool = false) throws {
        let fileManager = FileManager()
        let fileAttr = try fileManager.attributesOfItem(atPath: image.pathString)
        let fileSize = fileAttr[.size] as! Int64

        if info.totalSize < fileSize {
            throw DeviceControllerError.tooSmall(disk, info.totalSize, fileSize)
        }

        let chunksize = 1024*1024
        guard let inputFH = FileHandle(forReadingAtPath: image.pathString) else {
            throw DeviceControllerError.errno(errno)
        }

        let output = AbsolutePath("/dev/r" + disk)
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
            let writeSpeed = Measurement<UnitInformationStorage>(value: Double(copySoFar)/elapsedTime.duration, unit: .bytes)
            let percent = Double(copySoFar) / Double(fileSize)
            let bar = String(repeating: "-", count: Int(percent * 50))
            let filler = String(repeating: " ", count: 50)

            stderrStream <<< "\r[\(filler)]"
            stderrStream <<< " "
            stderrStream <<< ByteCountFormatter().string(from: writeSpeed)
            stderrStream <<< "/s   \r[\(bar)"
            stderrStream.flush()
        }
    }

    private func validate(forced: Bool) throws {
        // Safeguard checks, ignored if forced
        if !forced {
            if info.internal {
                throw DeviceControllerError.notExternal(disk)
            }
            if !info.removable {
                throw DeviceControllerError.notRemovable(disk)
            }
            if info.virtualOrPhysical != .physical {
                throw DeviceControllerError.notPhysical(disk)
            }
        }

        if !info.writable {
            throw DeviceControllerError.notWritable(disk)
        }
    }

    private func umountDisk() throws {
        try Process.checkNonZeroExit(arguments: [
            "diskutil", "umountDisk", disk
        ])
    }
}
