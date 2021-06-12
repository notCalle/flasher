//
//  File.swift
//  
//
//  Created by Calle Englund on 2021-02-12.
//

import ArgumentParser
import Pathos

extension Path: ExpressibleByArgument {
    public init?(argument: String) {
        self.init(argument)
    }
}
