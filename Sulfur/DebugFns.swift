//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import Foundation

public func inspect<Object>(_ objFn: @autoclosure () -> Object, inspectFn: (Object) -> Void) -> Object {
    let obj = objFn()
    inspectFn(obj)
    return obj
}

public func inspectPrint<Object>(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, obj: Object) -> Object {
    return inspect(obj) { object in
        print("[\((fileName as NSString).lastPathComponent):\(lineNumber) - \(functionName)]:")
        debugPrint(object)
    }
}

public func time<Input, Output>(fn: @escaping (Input) -> Output, onTime: @escaping (CFAbsoluteTime) -> Void) -> (Input) -> Output {
    return { (input) -> Output in
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = fn(input)
        let endTime = CFAbsoluteTimeGetCurrent()
        let deltaTime = endTime - startTime
        onTime(deltaTime * 1000)
        return result
    }
}

public func timePrint<Input, Output>(functionName: String = #function, fileName: String = #file, lineNumber: Int = #line, fn: @escaping ((Input) -> Output)) -> ((Input) -> Output) {
    return time(fn: fn) { (time) in
        print("[\((fileName as NSString).lastPathComponent):\(lineNumber) - \(functionName)] - Elapsed time: \(time) ms")
    }
}
