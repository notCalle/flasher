//
//  DeviceController.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-10.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Pathos

/// Device Controller errors
enum DeviceControllerError: Error {
    case notImplemented(String)
    case notExternal(String)
    case notPhysical(String)
    case notSafe(String)
    case notWritable(String)
    case errno(errno_t)
    case tooSmall(String, Int64, Int64)
    case verifyFailed
    case umountFailed
}
extension DeviceControllerError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notImplemented(let what):
            return "\(what) is not implemented"
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
        case .umountFailed:
            return "unmount of target device failed"
        }
    }
}

/// Controller for disk device operations
class DeviceController {
    private let stderr = FileHandle.standardError

    let disk: String
    let info: DiskInfo

    private var _fileHandle: FileHandle?

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
    }

    private func fileHandle() throws -> FileHandle {
        if _fileHandle == nil {
            try umountDisk()

            _fileHandle = try AuthOpen(forWritingAtPath: "/dev/r\(disk)").fileHandle
            precondition(fcntl(_fileHandle!.fileDescriptor, F_NOCACHE, 1) != -1)
        }
        return _fileHandle!
    }

    func write(_ data: Data) throws {
        let blockSize = Int(info.deviceBlockSize)
        let blockCount = (data.count - 1) / blockSize + 1
        var buffer = Data(count: blockCount * blockSize)
        buffer[0 ..< data.count] = data

        try fileHandle().write(buffer)
    }

    func blocks(ofSize blockSize: Int) throws -> PrefetchingBlockReader {
        return try fileHandle().blocks(ofSize: blockSize)
    }

    func synchronize() throws {
        if #available(OSX 10.15, *) {
            try fileHandle().synchronize()
        } else {
            try fileHandle().synchronizeFile()
        }
    }

    func rewind() throws {
        if #available(OSX 10.15, *) {
            try fileHandle().seek(toOffset: 0)
        } else {
            try fileHandle().seek(toFileOffset: 0)
        }
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
        let process = Process.launchedProcess(launchPath: "/usr/sbin/diskutil",
                                              arguments: ["umountDisk", disk])
        process.waitUntilExit()
        if process.terminationStatus != 0 { throw DeviceControllerError.umountFailed }
    }
}
