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
        }
    }
}

struct DeviceController {
    let disk: String

    init(for device: String, force: Bool = false) throws {
        disk = device
        try validate(forced: force)
    }

    public func write(image: AbsolutePath, verify: Bool = false) throws {
        let size = 1024*1024
        let input = image.pathString.withCString({path in
            return open(path, k)

        })
        let input = try Data(contentsOf: image.asURL, options: .alwaysMapped)
        let size = input.count

        stderrStream <<< input
        stderrStream.flush()

        let auth = try DeviceAccessAuthorization(for: .writing(disk))
        try auth.withAuth({_ in
            let output = AbsolutePath("/dev/" + disk)
            try input.write(to: output.asURL)
        })
    }

    private func validate(forced: Bool) throws {
        let info = try DiskInfo(for: disk)

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
}
