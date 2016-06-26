/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public extension Optional {

    public var isBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            switch value {
            case let str as String:
                return str.isBlank
            default:
                return false
            }
        }
    }
}
