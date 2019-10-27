//
//  Command.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-08.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import SPMUtility

/// Protocol for sub-command parsers
protocol CommandProtocol {
    var command: String { get }
    var overview: String { get }

    /// Initialize parser for sub-command
    /// 
    /// This should typically add a `subparser` to the parent `parser`
    /// and initialize any argument parsers for the sub-command.
    ///
    /// - Parameter parser: parent parser
    init(parser: ArgumentParser)

    /// Execute sub-command with parsed arguments
    /// 
    /// - Parameter arguments: parsed sub-command arguments
    func run(with arguments: ArgumentParser.Result) throws
}
