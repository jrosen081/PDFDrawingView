//
//  SamplePDFDrawingViewAppTests.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 3/24/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import XCTest
@testable import DrawingPDF
class TestLines: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testComputedProperties() {
		let line = Line(startingPoint: CGPoint(x: 10, y: 10))
		assert(line.first == CGPoint(x: 10, y: 10))
		assert(line.last == CGPoint(x: 10, y: 10))
		assert(line.points == [CGPoint(x: 10, y: 10)])
    }
	
	func testMutations() {
		let point = CGPoint(x: 10, y: 10)
		let line = Line(startingPoint: point)
		line.translate(by: CGVector(dx: -10, dy: -10))
		assert(line.points.first == CGPoint.zero)
		line.translate(by: CGVector(dx: 10, dy: 10))
	}

}
