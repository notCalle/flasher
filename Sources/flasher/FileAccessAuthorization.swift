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
    case failure(OSStatus, AuthorizedFileAccess)
}
extension FileAccessAuthorizationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .failure(let status, let action):
            let sec_error = SecCopyErrorMessageString(status, nil)! as String
            return "Authorizing access to \(action.prompt): \(sec_error)"
        }
    }
}

/// Wrapped authorization item name for a device action
enum AuthorizedFileAccess: Equatable {
    typealias RawValue = (Int, String)

    case writing(String)
    case reading(String)

    public var prompt: String {
        switch self {
        case .reading(let path):
            return "\(path) for reading"
        case .writing(let path):
            return "\(path) for writing"
        }
    }
}
extension AuthorizedFileAccess: CustomStringConvertible {
    public var description: String {
        switch self {
        case .reading(let path):
            return "sys.openfile.readonly." + path
        case .writing(let path):
            return "sys.openfile.readwrite." + path
        }
    }
}

/// Authorization for privileged access to a file
final class FileAccessAuthorization {
    let action: AuthorizedFileAccess
    let authRef: AuthorizationRef

    /// Request pre-authorization for privileged access to a file
    ///
    /// - See also: `AuthorizationCreate`
    /// - Parameter action: file access to request authorization for
    init(for action: AuthorizedFileAccess) throws {
        var authRef: AuthorizationRef?
        let items = [
            String(describing: action).withCString() {
                AuthorizationItem(name: $0, valueLength: 0, value: nil, flags: 0)
            }
        ]

        var rights: AuthorizationRights = items.withUnsafeBufferPointer() {
            AuthorizationRights(count: UInt32(items.count),
                                items: UnsafeMutablePointer(mutating: $0.baseAddress))
        }

        let flags: AuthorizationFlags = [.interactionAllowed,
                                         .extendRights,
                                         .preAuthorize]

        let status = AuthorizationCreate(&rights, nil, flags, &authRef)

        if status != errAuthorizationSuccess {
            throw FileAccessAuthorizationError.failure(status, action)
        }

        self.action = action
        self.authRef = authRef!
    }

    deinit {
        AuthorizationFree(authRef, [.destroyRights])
    }

    /// Get external form of authorization
    /// - See Also: `AuthorizationExternalForm`
    func externalAuthorization() throws -> AuthorizationExternalForm
    {
        var extAuthRef = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authRef, &extAuthRef)

        if status != errAuthorizationSuccess {
            throw FileAccessAuthorizationError.failure(status, action)
        }
        return extAuthRef
    }
}
