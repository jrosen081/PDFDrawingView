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
		XCTAssert(line.first == CGPoint(x: 10, y: 10))
		XCTAssert(line.last == CGPoint(x: 10, y: 10))
		XCTAssert(line.points == [CGPoint(x: 10, y: 10)])
    }
	
	func testMutations() {
		let point = CGPoint(x: 10, y: 10)
		let line = Line(startingPoint: point)
		line.translate(by: CGVector(dx: -10, dy: -10))
		XCTAssert(line.points.first == CGPoint.zero)
		line.translate(by: CGVector(dx: 10, dy: 10))
	}
	
	func testEquality() {
		let line1: DrawingLine = DrawingLine(startingPoint: CGPoint.zero, color: UIColor.red.cgColor)
		let line2 = DrawingLine(startingPoint: CGPoint(x: 10, y: 10), color: UIColor.red.cgColor)
		let line3 = DrawingLine(startingPoint: CGPoint.zero, color: UIColor.red.cgColor)
		XCTAssertTrue(line1 == line3)
		XCTAssertFalse(line1 == line2)
		line1.append(CGPoint(x: 10, y: 10), with: nil)
		XCTAssertTrue(line1 != line3)
		line3.append(CGPoint(x: 10, y: 10), with: nil)
		XCTAssertTrue(line1 == line3)
	}
	
	func testZoom() {
		let line = Line(startingPoint: CGPoint(x: 10, y: 10))
		XCTAssertEqual(line.zoom(scale: 1.5, moveBy: CGVector.zero), CGVector.zero)
		XCTAssertEqual(line, Line(startingPoint: CGPoint(x: 15, y: 15)))
		
	}

}
