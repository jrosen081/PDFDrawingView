//
//  TestOverloads.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 4/2/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import UIKit
import XCTest
@testable import DrawingPDF

class TestOverloads: XCTestCase {
	func testCGPoint() {
		let point1 = CGPoint.zero
		let point2 = CGPoint(x: 10, y: 10)
		let point3 = CGPoint(x: 1, y: 12)
		let point4 = CGPoint(x: 0, y: 10)
		let point5 = CGPoint(x: 0, y: 2.5)
		
		let vector1 = CGVector(dx: 10, dy: 10)
		let vector2 = CGVector(dx: -10, dy: -10)
		let vector3 = CGVector(dx: 1, dy: 12)
		
		XCTAssertEqual(point1 + vector1, point2)
		XCTAssertEqual(point1 + vector1 + vector2, point1)
		XCTAssertEqual(point2 + vector2, point1)
		XCTAssertEqual(point1 + vector3, point3)
		XCTAssertEqual(point1 - vector2, point2)
		XCTAssertEqual(point1 - vector1 - vector2, point1)
		XCTAssertEqual(point1 + 10, point4)
		XCTAssertEqual(point2 / 4, point5)
	}
	
	func testCGFloat() {
		let vector = CGVector(dx: 10, dy: 10)
		let vector2 = CGVector(dx: -10, dy: 1)
		let vector3 = CGVector(dx: 25, dy: 25)
		let vector4 = CGVector(dx: 10, dy: -1)
		
		XCTAssertEqual(vector * 2.5, vector3)
		XCTAssertEqual(vector2 * -1, vector4)
		XCTAssertEqual(vector2 * -1 * -1, vector2)
	}
	
	func testCGRect() {
		var cg1 = CGRect(x: 10, y: 10, width: 2, height: 2)
		let second = CGRect(x: 10, y: 10, width: 10, height: 10)
		let third = CGRect(x: 10, y: 10, width: 100, height: 100)
		
		cg1 *= 5
		XCTAssertEqual(cg1, second)
		cg1 *= 10
		XCTAssertEqual(cg1, third)
		
		let secondDown = CGRect(x: 10, y: 10, width: 1, height: 1)
		let thirdDown = CGRect(x: 10, y: 10, width: 25, height: 25)
		
		XCTAssertEqual(second / 10, secondDown)
		XCTAssertEqual(third / 4, thirdDown)
	}
	
}
