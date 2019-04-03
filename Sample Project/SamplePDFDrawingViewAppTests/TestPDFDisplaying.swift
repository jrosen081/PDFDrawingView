//
//  TestPDFDisplaying.swift
//  SamplePDFDrawingViewAppTests
//
//  Created by Jack Rosen on 4/2/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import UIKit
import XCTest
import PDFKit
@testable import DrawingPDF

class TestPDFDisplaying: XCTestCase {
	var pdf: PDFDocument = PDFDocument(url: URL(fileURLWithPath: Bundle.main.path(forResource: "ListAbstractions", ofType: "pdf")!))!
	public override func setUp() {
		self.pdf = PDFDocument(url: URL(fileURLWithPath: Bundle.main.path(forResource: "ListAbstractions", ofType: "pdf")!))!
	}
	
	public func testDrawing() {
		let pdfView = PDFDrawingView(frame: CGRect(x: 0, y: 0, width: 100, height: 100), document: pdf)
		XCTAssertEqual(pdfView.numberOfPages, 2)
		XCTAssertEqual(pdfView.currentPageNumber, 0)
		XCTAssertNil(pdfView.delegate)
		XCTAssertEqual(pdfView.contentOffset, -1)
		XCTAssertEqual(pdfView.document, pdf)
		XCTAssertEqual(pdfView.drawingColor, UIColor.black)
		XCTAssertEqual(pdfView.highlightColor, UIColor.yellow)
		XCTAssertEqual(pdfView.drawingKey, PDFDrawingView.DrawingKeys.draw)
		XCTAssertEqual(pdfView.getMaxScale(), 3)
		XCTAssertEqual(pdfView.getMinScale(), 1)
		XCTAssertEqual(pdfView.renderStyle, DrawingStyle.vertical)
		XCTAssertEqual(pdfView.scrollViewIsScrolling(), false)
		XCTAssertEqual(pdfView.visiblePages.count, 2)
		XCTAssertEqual(pdfView.zoomScale, 1)
		XCTAssertEqual(pdfView.visiblePages[0].pageNumber, 0)
	}
}
