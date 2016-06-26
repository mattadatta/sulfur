/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public extension String {

    @warn_unused_result
    public func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    public var isBlank: Bool {
        return self.trim().isEmpty
    }

    public var nilIfBlank: String? {
        guard !self.isBlank else {
            return nil
        }
        return self
    }
}
