//
//  FileAccessAuthorization.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-09.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation

/// Wrapped OSStatus error code for Authorization* failures
enum FileAccessAuthorizationError: Error {
    case failure(OSStatus)
}
extension FileAccessAuthorizationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .failure(let status):
            return SecCopyErrorMessageString(status, nil)! as String
        }
    }
}

/// Wrapped authorization item name for a device action
enum AuthorizedFileAccess: Equatable {
    typealias RawValue = (Int, String)

    case writing(String)
    case reading(String)
}
extension AuthorizedFileAccess: CustomStringConvertible {
    public var description: String {
        switch self {
        case .reading(let path):
            return "sys.openfile.read." + path
        case .writing(let path):
            return "sys.openfile.readwrite." + path
        }
    }
}

final class FileAccessAuthorization {
    let action: AuthorizedFileAccess
    let authRef: AuthorizationRef

    init(for action: AuthorizedFileAccess) throws {
        var authRef: AuthorizationRef?
        var items = [AuthorizationItem(name: String(describing: action),
                                       valueLength: 0, value: nil,
                                       flags: 0)]
        var rights = AuthorizationRights(count: UInt32(items.count),
                                         items: &items)
        let flags: AuthorizationFlags = [.interactionAllowed,
                                         .extendRights,
                                         .preAuthorize]

        let status = AuthorizationCreate(&rights, nil, flags, &authRef)

        if status != errAuthorizationSuccess {
            throw FileAccessAuthorizationError.failure(status)
        }

        self.action = action
        self.authRef = authRef!
    }

    deinit {
        AuthorizationFree(authRef, [.destroyRights])
    }

    func externalAuthorization() throws -> AuthorizationExternalForm
    {
        var extAuthRef = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authRef, &extAuthRef)

        if status != errAuthorizationSuccess {
            throw FileAccessAuthorizationError.failure(status)
        }
        return extAuthRef
    }
}
