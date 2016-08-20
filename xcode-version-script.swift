#!/usr/bin/env xcrun --sdk macosx swift

/*
 Copyright (c) 2016 Matthew Brown

 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import Foundation
import Darwin

// Utils

@discardableResult
func shell(_ args: String ...) -> (statusCode: Int, output: String) {
    let process = Process()
    process.launchPath = "/usr/bin/env"
    process.arguments = args

    let pipe = Pipe()
    process.standardOutput = pipe
    process.launch()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return (Int(process.terminationStatus), String(data: data, encoding: .utf8)!.trimmingCharacters(in: .whitespacesAndNewlines))
}

func setPlistProperty(_ property: String, toValue value: Any) {
    let environment = ProcessInfo.processInfo.environment

    guard let projectDir = environment["PROJECT_DIR"] else {
        print("\'PROJECT_DIR\' environment variable not set!")
        exit(1)
    }
    guard let infoPlistFile = environment["INFOPLIST_FILE"] else {
        print("\'INFOPLIST_FILE\' environment variable not set!")
        exit(1)
    }

    if shell("/usr/libexec/PlistBuddy", "-c", "Set :\(property) \(value)", "\(projectDir)/\(infoPlistFile)").statusCode == 0 {
        print("Set \(property) to \(value)")
    } else {
        print("Failed to set \(property) to \(value)")
        exit(1)
    }
}

// Script

shell("sh", "/etc/profile")
let gitExec = shell("which", "git").output
let branchName = shell(gitExec, "rev-parse", "--abbrev-ref", "HEAD").output

guard branchName.hasPrefix("release") else {
    print("Not in release branch, not updating version numbers.")
    exit(0)
}

guard let versionStartIndex = branchName.range(of: "/")?.upperBound else {
    print("Release branch should have form \"release/x.y.z\".")
    exit(1)
}

let versionNumberString = branchName.substring(from: versionStartIndex)
let versionNumberPattern = "^\\d+(\\.\\d+)*$"
guard (try! NSRegularExpression(pattern: versionNumberPattern, options: [])).numberOfMatches(in: versionNumberString, options: [], range: NSRange(location: 0, length: versionNumberString.characters.count)) > 0 else {
    print("Version number should match regex pattern \"\(versionNumberPattern)\".")
    exit(1)
}

let rcNumber = Int(shell("git", "rev-list", "dev..", "--count").output)! + 1

let shortVersionString = "\(versionNumberString)-rc\(rcNumber)"
let buildNumber = shell(gitExec, "rev-list", "--all", "--count").output

setPlistProperty("CFBundleShortVersionString", toValue: shortVersionString)
setPlistProperty("CFBundleVersion", toValue: buildNumber)
