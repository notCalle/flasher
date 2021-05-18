//
//  ListCommand.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-08.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import ArgumentParser
import Foundation

enum ListCommandError: Error {
    case plistTypeError(Any)
    case keyError(String)
}

extension Flasher {
    /// Sub-command to list available disks
    struct List: ParsableCommand {
        static var configuration = CommandConfiguration(
            abstract: "Lists available storage devices"
        )

        mutating func run() throws {
            let disks = try DiskInfo.list(["physical"])
            let stdout = FileHandle.standardOutput

            try disks.forEach({disk in
                let info = try DiskInfo(for: disk)

                if !info.safe || !info.writableMedia { return }

                stdout <<< disk <<< " \"" <<< info.mediaName <<< "\" ("
                stdout <<< ByteCountFormatter.string(fromByteCount: info.size,
                                                     countStyle: .file)
                stdout <<< ")\n"
            })
            try stdout.synchronize()
        }
    }
}
