//
// This file is subject to the terms and conditions defined in
// file 'LICENSE', which is part of this source code package.
//

import XCTest
import UIKit
@testable import Sulfur

final class SulfurTests: XCTestCase {

    typealias GridRect = GridCollectionController.GridRect

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testHashing() {
        self.log(rect: GridRect(x: 0.0, y: 0.0, width: 0.0, height: 0.0))
        let rects = (0..<100).map({ LinearGrid(numUnits: 10).rect(forIndex: $0) })
        for (i, rect1) in rects.enumerated() {
            self.log(rect: rect1)
            for (j, rect2) in rects.enumerated() {
                guard i != j else { break }
                XCTAssertNotEqual(rect1.hashValue, rect2.hashValue)
            }
        }
    }

    private func log(rect: GridRect) {
        print("rect = \(rect), hash = \(rect.hashValue)")
    }
}
