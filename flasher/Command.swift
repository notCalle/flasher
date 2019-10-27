//
//  CommandParser.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-08.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic
import SPMUtility

public enum CommandError: Swift.Error {
    /// Incorrect command usage
    case usage(ArgumentParser)

    /// Incorrect arguments
    case arguments(ArgumentParserError)
}

extension CommandError {
    func print(on output: OutputByteStream = stderrStream) {
        switch self {
        case .usage(let parser):
            parser.printUsage(on: output)
        case .arguments(let error):
            output <<< error.description <<< "\n"
        }
        output.flush()
    }
}

/// Top level parser for the command itself
struct Command {
    private var commands: [CommandProtocol] = []
    private let parser: ArgumentParser

    init(usage: String, overview: String) {
        parser = ArgumentParser(usage: usage, overview: overview)
    }

    /// Adds a sub-command parser to the command
    ///
    /// - Parameter command: sub command parser
    mutating func add(command: CommandProtocol.Type) {
        commands.append(command.init(parser: parser))
    }

    /// Parse and execute command line
    /// 
    /// - Parameter arguments: command line arguments
    func run(with arguments: [String]) throws {
        do {
            try process(arguments)
        } catch let error as ArgumentParserError {
            throw CommandError.arguments(error)
        }
    }

    private func process(_ arguments: [String]) throws {
        let parsedArguments = try parser.parse(arguments)

        guard let subparser = parsedArguments.subparser(parser),
            let command = commands.first(where: { $0.command == subparser })
        else {
            throw CommandError.usage(parser)
        }
        try command.run(with: parsedArguments)
    }
}
