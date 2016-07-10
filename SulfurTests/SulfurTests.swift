//
//  SulfurTests.swift
//  SulfurTests
//
//  Created by Matthew Brown on 2016-05-08.
//  Copyright © 2016 Mattadatta. All rights reserved.
//

import XCTest
import UIKit
@testable import Sulfur

class SulfurTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testExample() {
        let linearGrid = LinearGrid(numUnits: 4)
        let things = (0..<100).map { linearGrid.rect(forIndex: $0) }
        print(things)
    }
}
