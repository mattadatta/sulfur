/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import RxSwift

public func nilIfNull(_ obj: Any?) -> Any? {
    guard obj is NSNull else { return obj }
    return nil
}

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

    public func anyOptional() -> Observable<Any?> {
        return self.map({ $0 })
    }
}

extension Variable where Element: ObservableOptional {

    public func asUnwrappedObservable() -> Observable<Element.Wrapped> {
        return self.asObservable().unwrap()
    }
}

public extension Observable {

    public func optionally() -> Observable<Element?> {
        return self.map({ $0 })
    }

    public func any() -> Observable<Any> {
        return self.map({ $0 })
    }
}

public extension Observable {

    public func delayOnMain(by interval: RxTimeInterval) -> Observable<Element> {
        return self.delay(interval, scheduler: MainScheduler.instance)
    }
}
