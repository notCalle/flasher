//
//  main.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-08.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
var parser = Command(usage: "<command> ...",
                     overview: "Write an image to a storage device")

parser.add(command: ListCommand.self)
parser.add(command: WriteCommand.self)

do {
    try parser.run(with: arguments)
}
catch let error as CommandError {
    error.print()
    exit(EXIT_FAILURE)
}
