//
//  ListCommand.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-08.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic
import SPMUtility

enum ListCommandError: Error {
    case plistTypeError(Any)
    case keyError(String)
}

struct ListCommand: CommandProtocol {
    let command = "list"
    let overview = "Lists available storage devices"

    init(parser: ArgumentParser) {
        parser.add(subparser: command, overview: overview)
    }

    func run(with arguments: ArgumentParser.Result) throws {
        let disks = try getDiskIds()
        try disks.forEach({disk in
            let diskInfo = try getDiskInfo(for: disk)
            guard let writable = diskInfo["Writable"] as? Bool else {
                throw ListCommandError.keyError("Writable")
            }
            guard let removable = diskInfo["Removable"] as? Bool else {
                throw ListCommandError.keyError("Removable")
            }

            if !removable || !writable { return }

            guard let mediaName = diskInfo["MediaName"] as? String else {
                throw ListCommandError.keyError("MediaName")
            }
            guard let size = diskInfo["TotalSize"] as? Int64 else {
                throw ListCommandError.keyError("TotalSize")
            }

            stdoutStream <<< disk <<< " \"" <<< mediaName <<< "\" ("
            stdoutStream <<< ByteCountFormatter.string(fromByteCount: size,
                                                       countStyle: .file)
            stdoutStream <<< ")\n"
        })
        stdoutStream.flush()
    }

    private func getDiskIds() throws -> [String] {
        let output = try Process.checkNonZeroExit(arguments: [
            "/usr/sbin/diskutil", "list", "-plist", "external", "physical"
        ])
        let plist = output.propertyList()
        guard let dict = plist as? [String:[Any]] else {
            throw ListCommandError.plistTypeError(plist)
        }
        guard let disks = dict["AllDisksAndPartitions"] as? [[String:Any]] else {
            throw ListCommandError.keyError("AllDisksAndPartitions")
        }
        return try disks.map({disk in
            guard let id = disk["DeviceIdentifier"] as? String else {
                throw ListCommandError.keyError("DeviceIdentifier")
            }
            return id
        })
    }

    private func getDiskInfo(for disk: String) throws -> [String:Any] {
        let output = try Process.checkNonZeroExit(arguments: [
            "/usr/sbin/diskutil", "info", "-plist", disk
        ])
        let plist = output.propertyList()
        guard let dict = plist as? [String:Any] else {
            throw ListCommandError.plistTypeError(plist)
        }
        return dict
    }
}

