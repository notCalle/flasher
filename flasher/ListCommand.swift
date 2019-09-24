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
        let disks = try DiskInfo.list(["external", "physical"])
        try disks.forEach({disk in
            let info = try DiskInfo(for: disk)

            if !info.removable || !info.writableMedia { return }

            stdoutStream <<< disk <<< " \"" <<< info.mediaName <<< "\" ("
            stdoutStream <<< ByteCountFormatter.string(fromByteCount: info.totalSize,
                                                       countStyle: .file)
            stdoutStream <<< ")\n"
        })
        stdoutStream.flush()
    }
}
