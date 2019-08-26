//
//  TestLassoLine.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 4/4/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import UIKit
import XCTest
@testable import DrawingPDF

class TestLassoLine: XCTestCase {
	func testStart() {
		let lasso = Lasso(startingPoint: CGPoint.zero)
		lasso.append(point: CGPoint(x: 1, y: 1), predicted: [])
		lasso.append(point: CGPoint(x: 23, y: 33), predicted: [CGPoint.zero])
		XCTAssertEqual(lasso.predicted.count, 1)
		lasso.starts(at: CGPoint.zero)
		XCTAssertEqual(lasso.points.count, 4)
		XCTAssertEqual(lasso.predicted.count, 1)
	}
}
