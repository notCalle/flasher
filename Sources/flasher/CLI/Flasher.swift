//
//  Flasher.swift
//  
//
//  Created by Calle Englund on 2021-02-12.
//

import ArgumentParser

struct Flasher: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for writing images to removable storage devices",
        subcommands: [Flasher.List.self, Flasher.Write.self]
    )
}
