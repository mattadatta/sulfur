/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation
import XCGLogger

public extension Data {

    public var hexadecimalString: String {
        var result: String?
        self.withUnsafeBytes { (chars: UnsafePointer<CChar>) in
            result = UnsafeBufferPointer(start: chars, count: self.count).map({ String(format: "%02.2hhx", arguments: [$0]) }).reduce("", +)
        }
        return result ?? ""
    }
}
