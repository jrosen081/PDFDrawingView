//
//  ViewController.swift
//  SamplePDFDrawingViewApp
//
//  Created by Jack Rosen (New User) on 2/21/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import UIKit
import PDFKit

class ViewController: UIViewController, PDFDelegate {
	/**
	 * This view is on the screen so that the PDFView is not blocked off
	 */
	@IBOutlet weak var holdingView: UIView!
	/**
     * A variable to hold onto the current page
     */
	var currentPage: Int = 0
	/**
	 * The PDF Drawing View
	 */
	var pdfView: PDFDrawingView!
	override func viewDidAppear(_ animated: Bool) {
		if let path = Bundle.main.path(forResource: "Kant", ofType: "pdf"), let pdf = PDFDocument(url: URL(fileURLWithPath: path)){
			pdfView = PDFDrawingView(frame: self.holdingView.bounds, document: pdf, style: .horizontal, delegate: self)
			self.holdingView.addSubview(pdfView)
		}
	}
	// MARK: These will all be called after a button is pressed
	
	
	// Changes the key to erasing
	@IBAction func changeToErase(_ sender: Any) {
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.erase
	}
	
	// Changes the key to lasso
	@IBAction func changeToLasso(_ sender: Any){
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.lasso
	}
	
	// Changes the key to drawing
	@IBAction func changeToScroll(_ sender: Any) {
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.scroll
	}
	
	// Changes the key to text
	@IBAction func changeToText(_ sender: Any) {
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.text
	}
	
	// Changes the key to highlight
	@IBAction func changeToHighlight(_ sender: Any) {
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.highlight
	}
	
	// Changes the key to draw
	@IBAction func changeToDraw(_ sender: Any) {
		pdfView.drawingKey = PDFDrawingView.DrawingKeys.draw
	}
	
	// MARK: Delegate methods being implemented
	func scrolled(to page: Int) {
		self.currentPage = page
	}
	func viewWasCreated() {
		return
	}
}

