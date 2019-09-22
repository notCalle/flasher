//
//  AuthOpen.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-13.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

public struct AuthOpen {
    let proc = Process()
    let fileHandle: FileHandle

    init(with auth: FileAccessAuthorization) throws {
        let authPipe = Pipe()
        let fdSockets = try FileHandle.socketPair()

        var args = ["-stdoutpipe", "-extauth"]
        switch auth.action {
        case .writing(let path):
            args.append(contentsOf: ["-w", path])
        case .reading(let path):
            args.append(path)
        }

        proc.standardInput = authPipe.fileHandleForReading
        proc.standardOutput = fdSockets[1]
        proc.standardError = FileHandle.standardError
        proc.executableURL = AbsolutePath("/usr/libexec/authopen").asURL
        proc.arguments = args
        proc.launch()

        let extAuth = try auth.externalAuthorization()
        let authData = withUnsafePointer(to: extAuth.bytes, {
            return Data(bytes: $0, count: 32)
        })
        authPipe.fileHandleForWriting.write(authData)
        try authPipe.fileHandleForWriting.close()

        fileHandle = try fdSockets[0].receiveFileHandle(closeOnDealloc: false)
    }

    // Helpers for writing
    public init(forWritingAtPath path: String) throws {
        let auth = try FileAccessAuthorization(for: .writing(path))

        try self.init(with: auth)
    }

    public init(forWritingTo url: URL) throws {
        let path = url.absoluteString
        try self.init(forWritingAtPath: path)
    }

    // Helpers for reading
    public init(forReadingAtPath path: String) throws {
        let auth = try FileAccessAuthorization(for: .reading(path))

        try self.init(with: auth)
    }

    public init(forReadingFrom url: URL) throws {
        let path = url.absoluteString

        try self.init(forReadingAtPath: path)
    }
}
