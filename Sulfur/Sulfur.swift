/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import Foundation
import XCGLogger

public final class SulfurSDK {

    public static let log: XCGLogger = {
        let log = XCGLogger()
        log.setup(level: .info, showFunctionName: true, showThreadName: false, showLevel: true, showFileNames: true, showLineNumbers: true, showDate: false, writeToFile: nil, fileLevel: nil)
        return log
    }()
}
