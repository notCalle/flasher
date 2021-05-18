//
//  File.swift
//  
//
//  Created by Calle Englund on 2021-02-12.
//

import Foundation

infix operator <<< : AdditionPrecedence

extension FileHandle {
    @discardableResult
    static func <<<(this: FileHandle, string: String) -> FileHandle {
        guard let data = string.data(using: .utf8) else { return this }
        this.write(data)
        return this
    }
}
