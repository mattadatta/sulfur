/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import Foundation
import XCGLogger

let log: XCGLogger = {
    let log = XCGLogger()
    log.setup(.Info, showFunctionName: true, showThreadName: false, showLogLevel: true, showFileNames: true, showLineNumbers: true, showDate: false, writeToFile: nil, fileLogLevel: nil)
    return log
}()
