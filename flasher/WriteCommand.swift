//
//  WriteCommand.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-09.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic
import SPMUtility

enum WriteCommandError: Error {
    case notImplemented
    case notExternal(String)
    case notPhysical(String)
    case notRemovable(String)
    case notWritable(String)
}
extension WriteCommandError: CustomStringConvertible {
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

struct WriteCommand: CommandProtocol {
    let command = "write"
    let overview = "Write an image to a removable storage device"

    private let force: OptionArgument<Bool>
    private let verify: OptionArgument<Bool>
    private let device: PositionalArgument<String>
    private let image: PositionalArgument<String>

    init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)

        force = subparser.add(option: "--force", kind: Bool.self,
                               usage: "Ignore safety checks (DANGEROUS)")
        verify = subparser.add(option: "--verify", kind: Bool.self,
                               usage: "Verify image after writing")
        device = subparser.add(positional: "device", kind: String.self,
                               usage: "Storage device to write image to")
        image = subparser.add(positional: "image", kind: String.self,
                              usage: "Image file to write to device")
    }

    public func run(with arguments: ArgumentParser.Result) throws {
        let disk = arguments.get(device)!
        try validate(disk: disk, force: arguments.get(force) ?? false)

        let auth = try DeviceAccessAuthorization(for: .writing(disk))
        try auth.withAuth({_ in
            throw WriteCommandError.notImplemented
        })
    }

    private func validate(disk: String, force: Bool = false) throws {
        let info = try DiskInfo(for: disk)

        // Safeguard checks, ignored if forced
        if !force {
            if info.internal {
                throw WriteCommandError.notExternal(disk)
            }
            if !info.removable {
                throw WriteCommandError.notRemovable(disk)
            }
            if info.virtualOrPhysical != .physical {
                throw WriteCommandError.notPhysical(disk)
            }
        }

        if !info.writable {
            throw WriteCommandError.notWritable(disk)
        }
    }
}
