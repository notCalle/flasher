//
//  AuthOpen.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-13.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation
import Basic

/// Obtain authorization for privileged access to a file, calling out to `/usr/libexec/authopen`
/// to get an open file handle.
public struct AuthOpen {
    /// `FileHandle` with privileged access authorization
    let fileHandle: FileHandle

    /// Initialize file handle with privileged access authorization
    /// 
    /// - Parameter auth: pre-authorization for privileged file access
    private init(with auth: FileAccessAuthorization) throws {
        let proc = Process()
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

        if #available(OSX 10.15, *) {
            try authPipe.fileHandleForWriting.close()
        } else {
            authPipe.fileHandleForWriting.closeFile()
        }

        fileHandle = try fdSockets[0].receiveFileHandle()
    }

    //MARK: Helpers for writing

    /// Obtain authorization for writing to file at path
    ///
    /// - Parameter path: path to file for writing
    public init(forWritingAtPath path: String) throws {
        let auth = try FileAccessAuthorization(for: .writing(path))

        try self.init(with: auth)
    }

    //MARK: Helpers for reading

    /// Obtain authorization for reading from file at path
    ///
    /// - Parameter path: path to file for reading
    public init(forReadingAtPath path: String) throws {
        let auth = try FileAccessAuthorization(for: .reading(path))

        try self.init(with: auth)
    }
}
