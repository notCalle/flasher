//
//  File.swift
//  
//
//  Created by Calle Englund on 2021-02-12.
//

import Foundation

extension Data {
    init(outputFrom command: String, arguments: [String]) throws {
        let pipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: command)
        process.arguments = arguments
        process.standardOutput = pipe
        try process.run()

        var buffer = Data()
        pipe.fileHandleForReading.readabilityHandler = { fh in
            buffer.append(fh.availableData)
        }

        process.waitUntilExit()
        pipe.fileHandleForReading.readabilityHandler = nil

        precondition(process.terminationStatus == 0)
        self = buffer
    }
}

extension Data {
    func propertyList() ->  Any {
        return String(data: self, encoding: .utf8)!.propertyList()
    }
}
