//
//  AuthorizedByteStream.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-11.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

class AuthorizedByteStream {
    fileprivate let authData: Data
    fileprivate let writePipe = Pipe()
    fileprivate let proc = Process()

    init(with authorization: DeviceAccessAuthorization) throws {
        let auth = try authorization.externalAuthorization()

        authData = withUnsafePointer(to: auth.bytes, {
            return Data(bytes: $0, count: 32)
        })

        proc.standardInput = writePipe.fileHandleForReading
        proc.standardOutput = FileHandle.standardOutput
        proc.standardError = FileHandle.standardError
        proc.executableURL = AbsolutePath("/usr/libexec/authopen").asURL
        proc.arguments = [
            "-extauth"
        ]
    }

    fileprivate func open(_ args: String...) {
        for arg in args {
            proc.arguments!.append(arg)
        }
        proc.launch()
        writePipe.fileHandleForWriting.write(authData)
    }
}

final class AuthorizedOutputByteStream: AuthorizedByteStream {
    init(_ path: AbsolutePath, with authorization: DeviceAccessAuthorization) throws {
        try super.init(with: authorization)
        super.open("-w", path.pathString)
    }

    func write(_ data: Data) throws {
        writePipe.fileHandleForWriting.write(data)
    }

    func write(bytes: [UInt8]) throws {
        try write(Data(bytes))
    }
}
