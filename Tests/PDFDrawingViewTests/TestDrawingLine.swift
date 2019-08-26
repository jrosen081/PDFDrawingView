//
//  TestDrawingLine.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 3/24/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import XCTest
@testable import DrawingPDF

class TestDrawingLine: XCTestCase {
	func testIntersect() {
		let line1 = DrawingLine(points: [CGPoint(x: 10, y: 10), CGPoint(x: 15, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		let line2 = DrawingLine(points: [CGPoint(x: 5, y: 10), CGPoint(x: 20, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		let line3 = DrawingLine(points: [CGPoint(x: 15, y: 10), CGPoint(x: 20, y: 12)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		XCTAssert(line1.intersects(line: line2))
		XCTAssert(line2.intersects(line: line1))
		XCTAssert(!line2.intersects(line: line3))
		XCTAssert(!line1.intersects(line: line3))
		XCTAssert(!line3.intersects(line: line1))
	}
	
	func testAppend() {
		let line1 = DrawingLine(points: [CGPoint(x: 10, y: 10), CGPoint(x: 15, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		line1.append(CGPoint(x: 100, y: 100), with: nil)
		XCTAssert(line1.points.count == 3)
		XCTAssert(line1.contains(CGPoint(x: 100, y: 100)))
		XCTAssert(line1._path.contains(CGPoint(x: 100, y: 100)))
	}
	
	func testFinishAll() {
		let line1 = DrawingLine(points: [CGPoint(x: 10, y: 10), CGPoint(x: 15, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		line1.finishAll()
		XCTAssert(line1.finished)
		XCTAssert(line1.predicted.isEmpty)
		XCTAssert(line1.path == line1._path)
	}
}
