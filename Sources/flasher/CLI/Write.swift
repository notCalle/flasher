//
//  WriteCommand.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-09.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import ArgumentParser
import Pathos

extension Flasher {
    /// Sub-command to write an image to a disk
    struct Write: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Write an image to a removable storage device"
        )

        @Flag(help: "Ignore safety checks (DANGEROUS)")
        var force: Bool = false

        @Flag(help: "Verify image after writing")
        var verify: Bool = false

        @Argument(help: "Image file to write to device")
        var device: String

        @Argument(help: "Image file to write to device", completion: .file())
        var image: Path

        mutating func run() throws {
            let controller = try DeviceController(for: device, force: force)
            try controller.write(image: image, verify: verify)
        }
    }
}
