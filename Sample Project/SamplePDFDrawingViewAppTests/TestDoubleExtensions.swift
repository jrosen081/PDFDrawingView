//
//  TestDoubleExtensions.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 3/24/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import XCTest
@testable import DrawingPDF

class TestDoubleExtensions: XCTestCase {
	func testIsWithin(){
		assert(1.0.isWithin(other: 1, percentage: 0.1))
		assert(1.0.isWithin(other: 1.01, percentage: 0.1))
		assert(!1.0.isWithin(other: 1.1, percentage: 0.01))
	}
	
	func testExtensions() {
		assert((-1.0).abs().isWithin(other: 1, percentage: 0.1))
	}
}

extension Double {
	func isWithin(other: Double, percentage: Double) -> Bool{
		return other - self == 0 || (other - self).abs() <= self * percentage.abs()
	}
}
