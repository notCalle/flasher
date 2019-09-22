//
//  DiskInfo.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-10.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

enum VirtualOrPhysical: Equatable {
    case physical
    case virtual
    case undefined(String)

    init(_ virtualOrPhysical: String) {
        switch virtualOrPhysical {
        case "Virtual":
            self = .virtual
        case "Physical":
            self = .physical
        default:
            self = .undefined(virtualOrPhysical)
        }
    }
}
extension VirtualOrPhysical: CustomStringConvertible {
    public var description: String {
        switch self {
        case .physical:
            return "physical"
        case .virtual:
            return "virtual"
        case .undefined(let value):
            return "undefined(" + value + ")"
        }
    }
}

struct DiskInfo {
    private let dict: [String:Any]

    init(for disk: String) throws {
        let output = try Process.checkNonZeroExit(arguments: [
            "/usr/sbin/diskutil", "info", "-plist", disk
        ])
        let plist = output.propertyList()
        dict = plist as! [String:Any]
    }

    public var `internal`: Bool { return dict["Internal"] as! Bool }
    public var mediaName: String { return dict["MediaName"] as! String }
    public var removable: Bool { return dict["Removable"] as! Bool }
    public var totalSize: Int64 { return dict["TotalSize"] as! Int64 }
    public var virtualOrPhysical: VirtualOrPhysical {
        return VirtualOrPhysical(dict["VirtualOrPhysical"] as! String)
    }
    public var writable: Bool { return dict["Writable"] as! Bool }

    public static func list(_ args: [String] = []) throws -> [String] {
        let output = try Process.checkNonZeroExit(arguments: [
            "/usr/sbin/diskutil", "list", "-plist"
        ] + args)
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

}
