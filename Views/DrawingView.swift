//
//  DrawingScrollView.swift
//  drawSecure
//
//  Created by Jack Rosen on 3/5/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit

final class DrawingView: UIView, UITextViewDelegate, UIGestureRecognizerDelegate{
	override var canBecomeFirstResponder: Bool{
		return true
	}
	weak var delegate: DrawingDelegate?
	// The last point that was touched
	private var startPoint = CGPoint(x: -100,y: -100)
	private var touchPoint = CGPoint()
	private var swiped = false
	// The color for drawing
	var drawingColor = UIColor.black
	// The color for highlighting
	var highlightColor = UIColor.yellow
	// A representation of all of the lines that are drawn
	private var lines: [DrawingLine] = [DrawingLine]()
	// Checks if the keyboard is open or not
	private var keyboardIsOpen = false
	// The menu to be shown after tapping a text box
	private let menu = UIMenuController.shared
	// The current text view
	private var textView = OverTopText()
	// The layers that the lasso is on
	private var lassoLayers = [Int]()
	// A tap gesture for drawing/erasing
	private lazy var tapGesture: UITapGestureRecognizer = {
		let tap = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
		tap.numberOfTapsRequired = 1
		tap.cancelsTouchesInView = true
		return tap
	}()
	// The type of drawing that is occurring
	var drawingType = PDFDrawingView.DrawingKeys.draw {
		didSet {
			self.endLasso()
		}
	}
	// All of the text views on the screen
	var textViews = [OverTopText]()
	// Is the scroll view scrolling?
	var scrollViewIsScrolling: Bool{
		return delegate?.scrollViewIsScrolling() ?? false
	}
	// Does the lasso have elements in it.
	private var lassoHasElements = false {
		didSet{
			canZoom = !lassoHasElements
		}
	}
	// The current zoom scale
	private var zoomScale: CGFloat{
		get{
			return delegate?.zoomScale ?? 1
		}
	}
	// The lasso line
	private var lasso = Lasso(startingPoint: CGPoint.zero)
	// Can the scrollview zoom?
	private var canZoom = true{
		didSet{
			if (canZoom)
			{
				delegate?.setMinScale(scale: 1)
				delegate?.setMaxScale(scale: 3)
			}
			else
			{
				delegate?.setMinScale(scale: zoomScale)
				delegate?.setMaxScale(scale: zoomScale)
			}
		}
	}
	// The number of touches on the screen
	private var numberOfTouches = 0 {
		didSet{
			for textView in textViews
			{
				textView.touches = self.numberOfTouches
			}
		}
	}
	
	// Long gesture for straight lines
	private lazy var press: UILongPressGestureRecognizer = {
		let press  = UILongPressGestureRecognizer(target: self, action: #selector(self.straight(_:)))
		press.delegate = self
		press.cancelsTouchesInView = false
		press.numberOfTouchesRequired = 1
		press.minimumPressDuration = 0.4
		return press
	}()
	
	// Is everything set up for drawing?
	private var canDraw: Bool {
		return (drawingType == PDFDrawingView.DrawingKeys.draw || drawingType == PDFDrawingView.DrawingKeys.highlight) && !(lines.last?.finished ?? false)
	}
	convenience init(){
		self.init(frame: CGRect.zero)
	}
	override init(frame: CGRect) {
		super.init(frame: frame)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardDidShowNotification, object: nil)
		self.backgroundColor = UIColor.clear
		self.isMultipleTouchEnabled = true
		self.isUserInteractionEnabled = true
		self.addGestureRecognizer(self.press)
		
		self.addGestureRecognizer(tapGesture)
	}
	@objc func keyboardWillDisappear(){
		keyboardIsOpen = false
	}
	@objc func keyboardWillAppear(){
		keyboardIsOpen = true
	}
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// Draws the line given tap gesture
	func draw(with tap: UITapGestureRecognizer) -> DrawingLine {
		let point = tap.location(in: self)
		let path = UIBezierPath(arcCenter: point, radius: Constants.lineWidth, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
		let currentDot = DrawingLine(points: point.squareAround(), opacity: 1, color: self.drawingColor.cgColor, lineWidth: 1, drawingType: .draw)
		currentDot.append(CGPoint(x: point.x - Constants.lineWidth, y: point.y - Constants.lineWidth), with: nil, path: path)
		return currentDot
	}
	// Returns all elements tapped
	func allLines(at location: CGPoint) -> [DrawingLine]{
		return lines.filter({$0.contains(location)})
	}
	// Returns a new textView at the given location
	func newTextView(at location: CGPoint) -> OverTopText {
		let textView: OverTopText = OverTopText(frame: CGRect(x: location.x - 75, y: location.y - 20, width: 150, height: 30), textContainer: nil)
		textView.layer.borderColor = UIColor.darkText.cgColor
		textView.layer.borderWidth = 1
		textView.layer.shadowColor = UIColor.black.cgColor
		textView.font = UIFont.systemFont(ofSize: textView.frame.height / UIScreen.main.scale)
		textView.allowsEditingTextAttributes = true
		textView.delegate = self
		return textView
	}
	//Tap gesture for drawing
	@objc func tapped(_ tap: UITapGestureRecognizer){
		if (drawingType == PDFDrawingView.DrawingKeys.draw){
			// Gets the point tapped and adds it to the lines
			let point = self.draw(with: tap)
			lines.append(point)
			self.layer.addSublayer(point.layer)
		} else if (drawingType == PDFDrawingView.DrawingKeys.erase){
			// Gets all lines tapped and removes them
			let inLines = self.allLines(at: tap.location(in: self))
			lines.removeAll(where: {inLines.contains($0)})
			inLines.forEach({$0.removeAll()})
		} else if (drawingType == PDFDrawingView.DrawingKeys.text){
			if (keyboardIsOpen){
				self.hideAllKeyboards()
				startPoint = CGPoint(x: -100, y: -100)
				return
			}
			startPoint = CGPoint(x: -100, y: -100)
			let center = tap.location(in: self)
			let textView = self.newTextView(at: center)
			self.textView = textView
			textView.becomeFirstResponder()
			let tap = UITapGestureRecognizer(target: self, action: #selector(DrawingView.tapGesture(_:)))
			textView.addGestureRecognizer(tap)
			self.addSubview(textView)
			textViews.append(textView)
			self.moveTextView(textView: textView)
		}else if (drawingType == PDFDrawingView.DrawingKeys.lasso){
			if (lassoHasElements && !lasso.contains(test: tap.location(in: self))){
				self.endLasso()
			}
		}
	}
	//Moves the textview above the keyboard
	func moveTextView(textView: UITextView){
		guard let value = delegate?.contentOffset, let height = delegate?.frame.height else{return}
		if textView.frame.origin.y > value + (height / 2.5){
			delegate?.contentOffset = textView.frame.origin.y - (100 / zoomScale)
		}
	}
	
	override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
		for touch in touches{
			lines.last?.finish(with: touch)
		}
	}
	
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		touchesEnded(touches, with: event)
	}
	
	// Draws a line with a given UITouch
	func drawLine(line: DrawingLine?, with touch: UITouch, event: UIEvent?) -> DrawingLine{
		let lineToReturn: DrawingLine = line ?? DrawingLine(startingPoint: touch.location(in: self), color: self.drawingColor.cgColor)
		if let predicted = event?.predictedTouches(for: touch) {
			return lineToReturn.funAppend(touch.location(in: self), with: touch, predictedTouches: predicted.map({$0.location(in: self)}))
		} else {
			return lineToReturn.funAppend(touch.location(in: self), with: touch)
		}
	}
	
	// Returns lines that intersect with a given line
	func linesThatIntersect(with line: Line) -> [DrawingLine]{
		return self.lines.filter({$0.intersects(line: line)})
	}
	
	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		guard let touch = touches.first else {return}
		touchPoint = touch.location(in: self)
		if (drawingType != PDFDrawingView.DrawingKeys.scroll && startPoint != CGPoint(x: -100, y: -100))
		{
			swiped = true
			if (self.canDraw)
			{
				if (touch.majorRadius >= 50){
					return
				}
				lines.append(self.drawLine(line: lines.removeLast(), with: touch, event: event))
				startPoint = touchPoint
				return
			}
			else if (drawingType == PDFDrawingView.DrawingKeys.erase){
				let eraseLine = DrawingLine(points: [startPoint, touchPoint], opacity: 1, color: UIColor.clear.cgColor, lineWidth: 1, drawingType: .erase)
				self.linesThatIntersect(with: eraseLine).forEach({$0.updateOpacity()})
			}
			else if (drawingType == PDFDrawingView.DrawingKeys.lasso)
			{
				if (!lassoHasElements)
				{
					lasso.append(point: touchPoint, predicted: event?.predictedTouches(for: touch)?.map({$0.location(in: self)}) ?? [])
				}
			}
		}
		startPoint = touchPoint
	}
	//Hides all keyboards
	func hideAllKeyboards(){
		textViews.forEach({view in
			view.resignFirstResponder()
			view.endEditing(true)
			textViewDidEndEditing(view)
		})
		menu.setMenuVisible(false, animated: false)
		keyboardIsOpen = false
	}
	
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		// Updates text views so they don't move if they shouldnt
		if let eventList = event, let total = eventList.allTouches{
			self.numberOfTouches = total.count
		}
		// Closes the keyboard if it was open
		if (self.keyboardIsOpen)
		{
			startPoint = CGPoint(x: -100, y: -100)
			self.hideAllKeyboards()
			return
		}
		// Makes sure to only draw when one person touches
		if (touches.count > 1 || self.numberOfTouches > 1 || self.scrollViewIsScrolling)
		{
			startPoint = CGPoint(x: -100, y: -100)
			return
		}
		// Stops scrolling
		self.delegate?.changeMovement(canMove: false)
		swiped = false
		guard let touch = touches.first else {return}
		startPoint = touch.location(in: self)
		if drawingType == PDFDrawingView.DrawingKeys.lasso
		{
			if !self.lassoHasElements
			{
				lasso.removeAll()
				lasso.starts(at: startPoint)
				self.layer.addSublayer(lasso.layer)
			}
		}
		else if (drawingType == PDFDrawingView.DrawingKeys.draw)
		{
			let line = DrawingLine(points:[startPoint], opacity: 1, color: self.drawingColor.cgColor, lineWidth: Constants.lineWidth + Constants.halfPointShift, drawingType: .draw)
			lines.append(line)
			self.layer.addSublayer(line.layer)
		}
		else if (drawingType == PDFDrawingView.DrawingKeys.highlight){
			let highlightLine = DrawingLine(points: [startPoint], opacity: 0.6, color: self.highlightColor.cgColor, lineWidth: Constants.lineWidth + Constants.halfPointShift, drawingType: .highlight)
			lines.append(highlightLine)
			self.layer.addSublayer(highlightLine.layer)
		}
	}
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
		delegate?.changeMovement(canMove: true)
		guard lines.last != nil || drawingType == PDFDrawingView.DrawingKeys.lasso, startPoint != CGPoint(x: -100, y: -100) else {return}
		if var last = lines.last, self.canDraw, let firstInLast = last.first{
			// Makes a straight line from the non straight line
			if (last.layer.opacity == Constants.opacity)
			{
				last.layer.opacity = 1
				let count = last.points.count
				lines.removeLast()
				let straightLine = DrawingLine(points: [firstInLast], opacity: last.opacity, color: last.color, lineWidth: last.lineWidth, drawingType: last.drawingType)
				for point in firstInLast.addIncrements(amount: count , until: last.last!){
					straightLine.append(point, with: nil)
				}
				last.removeAll()
				lines.append(straightLine)
				self.layer.addSublayer(straightLine.layer)
				last = straightLine
			}
			last.finishAll()
		}
		else if (drawingType == PDFDrawingView.DrawingKeys.lasso)
		{
			// Checks if nothing is in the lasso
			if !lassoHasElements, let firstLass = lasso.first
			{
				lasso.append(point: firstLass, predicted: [])
				var lassoIsNotEmpty = false
				var counter = 0
				for line in lines
				{
					if (lasso.contains(line: line)){
						self.lassoLayers.append(counter)
						line.layer.opacity = 0.75
						line.layer.shadowColor = line.color
						line.layer.shadowRadius = Constants.lineWidth / 2
						line.layer.shadowOffset = CGSize.zero
						line.layer.shadowOpacity = 1
						lassoIsNotEmpty = true
					}
					counter += 1
				}
				if (lassoIsNotEmpty == false)
				{
					lasso.removeAll()
					lassoHasElements = false
					return
				}
				let pan = UIPanGestureRecognizer(target: self, action: #selector(self.swipe(_:)))
				pan.delegate = self
				self.addGestureRecognizer(pan)
				let zoom = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
				zoom.delegate = self
				self.addGestureRecognizer(zoom)
				startPoint = CGPoint.zero
				lassoHasElements = true
			}
		} else if self.drawingType == PDFDrawingView.DrawingKeys.erase {
			// Removes all lines that should be erased
			for idx in (0 ..< self.lines.count).reversed() {
				let line = self.lines[idx]
				if (line.layer.opacity ==  Constants.opacity) {
					line.removeAll()
					self.lines.remove(at: idx)
				}
			}
		}
	}
	
	func textViewDidBeginEditing(_ textView: UITextView) {
		textView.isSelectable = true
		menu.menuItems = nil
		textView.layer.borderColor = UIColor.darkText.cgColor
		textView.layer.borderWidth = 1
	}
	
	func textViewDidEndEditing(_ textView: UITextView) {
		textView.isSelectable = false
		textView.resignFirstResponder()
		textView.endEditing(true)
		textView.layer.borderWidth = 0
		textView.layer.borderColor = UIColor.clear.cgColor
		textView.isEditable = false
	}
	
	func textViewDidChange(_ textView: UITextView) {
		let fixedWidth = textView.frame.size.width
		let height = textView.frame.size.height
		let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
		var newFrame = textView.frame
		newFrame.size = CGSize(width: fixedWidth, height: max(height, newSize.height))
		textView.frame = newFrame
		delegate?.contentOffset += newFrame.size.height - height
	}
	
	//Adds moving gesture for the lasso
	@objc func swipe(_ pan: UIPanGestureRecognizer)
	{
		if (pan.numberOfTouches == 2 || pan.state == .ended || pan.state == .cancelled || drawingType == PDFDrawingView.DrawingKeys.scroll)
		{
			return
		}
		var differenceX: CGFloat = 0
		var differenceY: CGFloat = 0
		// Gets the movement between the two last touches
		if (startPoint == CGPoint.zero && pan.location(in: self) != CGPoint.zero){
			differenceX = pan.translation(in: self).x
			differenceY = pan.translation(in: self).y
		} else{
			differenceX = pan.location(in: self).x - startPoint.x
			differenceY = pan.location(in: self).y - startPoint.y
		}
		let vector = CGVector(dx: differenceX, dy: differenceY)
		for index in self.lassoLayers{
			self.lines[index].translate(by: vector)
		}
		lasso.translate(by: vector)
		startPoint = pan.location(in: self)
	}
	//Allows zooming of the lasso
	@objc func zoom (_ zoom: UIPinchGestureRecognizer)
	{
		// Changes the movement of the scrollview
		if (zoom.state == .began)
		{
			delegate?.changeMovement(canMove: false)
		}
		else if (zoom.state == .ended || zoom.state == .cancelled)
		{
			delegate?.changeMovement(canMove: true)
		}
		var movementVector: CGVector?
		for line in lines{
			if (line.layer.shadowRadius == Constants.lineWidth / 2){
				movementVector = line.zoom(scale: zoom.scale, moveBy: movementVector)
			}
		}
		self.lasso.zoom(scale: zoom.scale, moveBy: movementVector)
		zoom.scale = 1
	}
	//Ends the lasso
	func endLasso(){
		self.lassoLayers.removeAll()
		lasso.removeAll()
		startPoint = CGPoint(x: -100, y: -100)
		lassoHasElements = false
		self.gestureRecognizers?.removeAll()
		self.addGestureRecognizer(self.press)
		self.addGestureRecognizer(self.tapGesture)
		for line in lines{
			line.layer.opacity = line.opacity
			line.layer.shadowRadius = 0
		}
	}
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return false
	}
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
		return true
	}
	//Removes textview from the view
	@objc func removeTextView(){
		textView.removeFromSuperview()
		menu.menuItems = nil
		keyboardIsOpen = false
		self.becomeFirstResponder()
	}
	//Starts the editing of the textview
	@objc func editStart(){
		textView.isEditable = true
		textView.becomeFirstResponder()
		menu.menuItems = nil
		moveTextView(textView: self.textView)
	}
	//Gives info about the possible things to do for the textview
	@objc func tapGesture(_ tap: UITapGestureRecognizer)
	{
		if let _ = tap.view, let text = tap.view! as? OverTopText, !text.isFirstResponder{
			self.textView = text
			text.layer.borderColor = UIColor.black.cgColor
			text.layer.borderWidth = 1
			self.becomeFirstResponder()
			let item1 = UIMenuItem(title: "Edit", action: #selector(self.editStart))
			let item2 = UIMenuItem(title: "Move", action: #selector(self.move))
			let item3 = UIMenuItem(title: "Resize", action: #selector(self.resize))
			let item4 = UIMenuItem(title: "Delete", action: #selector(self.removeTextView))
			menu.menuItems = [item1, item2, item3, item4]
			menu.setTargetRect(self.textView.frame, in: self)
			menu.setMenuVisible(true, animated: false)
			keyboardIsOpen = true
		}
	}
	override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
		return action == #selector(editStart) || action == #selector(removeTextView) || action == #selector(move) || action == #selector(resize)
	}
	@objc func move()
	{
		textView.swipe = true
		textView.layer.borderWidth = 1
		textView.layer.borderColor = UIColor.black.cgColor
	}
	@objc func resize(){
		textView.swipe = false
		textView.layer.borderWidth = 1
		textView.layer.borderColor = UIColor.black.cgColor
	}
	//Uses straight line
	@objc func straight(_ long: UILongPressGestureRecognizer)
	{
		if drawingType == PDFDrawingView.DrawingKeys.draw || drawingType == PDFDrawingView.DrawingKeys.highlight, let last = lines.last
		{
			if (long.state == .began || long.state == .failed || long.state == .cancelled)
			{
				last.updateOpacity()
			}
		}
	}
}

public extension CGPoint{
	// Returns a new point with the different subtracted
	public func subtract(point: CGPoint) -> CGPoint{
		return CGPoint(x: self.x - point.x, y: self.y - point.y)
	}
	
	// Scales a point
	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}
	// Creates a line of points between this and the other point
	public func addIncrements(amount: Int, until point: CGPoint) -> [CGPoint]
	{
		var array = [CGPoint]()
		let xDistance = (point.x - self.x) / CGFloat(amount)
		let yDistance = (point.y - self.y) / CGFloat(amount)
		let movementVector = CGVector(dx: xDistance, dy: yDistance)
		for counter in 1 ..< amount
		{
			array.append(self + movementVector * CGFloat(counter + 1))
		}
		return array
	}
	
	// Gives a square around the given location
	public func squareAround() -> [CGPoint] {
		return [CGPoint(x: self.x - Constants.lineWidth,y: self.y - Constants.lineWidth), CGPoint(x: self.x + Constants.lineWidth,y: self.y - Constants.lineWidth), CGPoint(x: self.x + Constants.lineWidth,y: self.y + Constants.lineWidth)]
	}
}
