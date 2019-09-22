//
//  FileHandle.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-13.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation

// Send / Receive FileHandles over a Pipe à la APUE
extension FileHandle {
    public static func socketPair() throws -> [FileHandle] {
        var fds: [Int32] = [0,0]
        let status = socketpair(PF_LOCAL, SOCK_STREAM, 0, &fds)
        if status != 0 {
            throw POSIXError(POSIXErrorCode(rawValue: status)!)
        }
        return fds.map({ self.init(fileDescriptor: $0) })
    }

    public func receiveFileHandle(closeOnDealloc cod: Bool = true) throws -> FileHandle {
        let nfd = recv_fd(self.fileDescriptor)
        return type(of: self).init(fileDescriptor: nfd, closeOnDealloc: cod)
    }
}
