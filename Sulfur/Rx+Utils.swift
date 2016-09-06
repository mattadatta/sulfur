/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import RxSwift

public protocol ObservableOptional {
    associatedtype Wrapped

    var observable_unwrapped: Wrapped { get }
    var observable_isNil: Bool { get }
}

public extension ObservableOptional {

    public var observable_isNotNil: Bool {
        return !self.observable_isNil
    }
}

extension Optional: ObservableOptional {

    public var observable_unwrapped: Wrapped {
        return self!
    }

    public var observable_isNil: Bool {
        return self == nil
    }
}

extension Observable where Element: ObservableOptional {

    public func unwrap() -> Observable<Element.Wrapped> {
        return self.filter({ $0.observable_isNotNil }).map({ $0.observable_unwrapped })
    }
}

extension Variable where Element: ObservableOptional {

    public func asUnwrappedObservable() -> Observable<Element.Wrapped> {
        return self.asObservable().unwrap()
    }
}

extension Variable where Element: Equatable {

    public func setIfDifferent(value: Element) {
        if self.value != value {
            self.value = value
        }
    }
}

extension Variable where Element: ObservableOptional, Element.Wrapped: Equatable {

    public func setIfDifferent(value: Element) {
        self.setIfDifferent(value: value)
    }
}
