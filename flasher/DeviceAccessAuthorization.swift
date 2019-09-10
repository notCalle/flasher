//
//  AuthorizeDeviceAccess.swift
//  flasher
//
//  Created by Calle Englund on 2019-09-09.
//  Copyright © 2019 Calle Englund. All rights reserved.
//

import Foundation

/// Wrapped OSStatus error code for Authorization* failures
enum DeviceAuthorizationError: Error {
    case failure(OSStatus)
}
extension DeviceAuthorizationError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .failure(let status):
            return SecCopyErrorMessageString(status, nil)! as String
        }
    }
}

/// Wrapped authorization item name for a device action
enum AuthorizedDeviceAction: Equatable {
    case writing(String)
    case reading(String)
}
extension AuthorizedDeviceAction: CustomStringConvertible {
    public var description: String {
        switch self {
        case .reading(let device):
            return "sys.openfile.read./dev/" + device
        case .writing(let device):
            return "sys.openfile.readwrite./dev/" + device
        }
    }
}

struct DeviceAccessAuthorization {
    let action: AuthorizedDeviceAction

    init(for action: AuthorizedDeviceAction) throws {
        self.action = action
    }

    public func withAuth(_ method: (AuthorizationRef) throws -> Void) throws
    {
        let authRef = try authorize()
        defer {
            AuthorizationFree(authRef, [.destroyRights])
        }
        try method(authRef)
    }

    public func withExtAuth(_ method: (AuthorizationExternalForm) throws -> Void) throws
    {
        try withAuth({authRef in
            let extAuth = try externalAuthorization(authRef)
            try method(extAuth)
        })
    }

    private func authorize() throws -> AuthorizationRef
    {
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
            throw DeviceAuthorizationError.failure(status)
        }
        return authRef!
    }

    private func externalAuthorization(_ authRef: AuthorizationRef) throws
        -> AuthorizationExternalForm
    {
        var extAuthRef = AuthorizationExternalForm()
        let status = AuthorizationMakeExternalForm(authRef, &extAuthRef)

        if status != errAuthorizationSuccess {
            throw DeviceAuthorizationError.failure(status)
        }
        return extAuthRef
    }
}
