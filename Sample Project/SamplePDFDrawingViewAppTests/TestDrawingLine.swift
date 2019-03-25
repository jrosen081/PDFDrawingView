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
		assert(line1.intersects(line: line2))
		assert(line2.intersects(line: line1))
		assert(!line2.intersects(line: line3))
		assert(!line1.intersects(line: line3))
		assert(!line3.intersects(line: line1))
	}
	
	func testAppend() {
		let line1 = DrawingLine(points: [CGPoint(x: 10, y: 10), CGPoint(x: 15, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		line1.append(CGPoint(x: 100, y: 100), with: nil)
		assert(line1.points.count == 3)
		assert(line1.contains(CGPoint(x: 100, y: 100)))
		assert(line1._path.contains(CGPoint(x: 100, y: 100)))
	}
	
	func testFinishAll() {
		let line1 = DrawingLine(points: [CGPoint(x: 10, y: 10), CGPoint(x: 15, y: 15)], opacity: 1, color: UIColor.gray.cgColor, lineWidth: Constants.lineWidth, drawingType: .draw)
		line1.finishAll()
		assert(line1.finished)
		assert(line1.predicted.isEmpty)
		assert(line1.path == line1._path)
	}
}
