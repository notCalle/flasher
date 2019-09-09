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
        let auth = try DeviceAccessAuthorization(for: .writing(arguments.get(device)!))
        try auth.withAuth({_ in
            throw WriteCommandError.notImplemented
        })
    }
}
