/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation

public struct Delayed {

    private let onCancel: () -> Void

    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }

    public func cancel() {
        self.onCancel()
    }
}

@discardableResult
public func delay(by time: Double, on queue: DispatchQueue = .main, block: @escaping () -> Void) -> Delayed {
    var cancelled = false
    queue.asyncAfter(deadline: .now() + time) {
        guard !cancelled else { return }
        block()
    }
    return Delayed() {
        cancelled = true
    }
}
