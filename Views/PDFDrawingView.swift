//
//  PDFDrawingView.swift
//  drawSecure
//
//  Created by Jack Rosen on 7/23/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import UIKit
import PDFKit

public class PDFDrawingView: UIView{
    public struct DrawingKeys{
        public static let draw = "draw"
        public static let scroll = "scroll"
        public static let highlight = "highlight"
        public static let text = "text"
        public static let erase = "erase"
        public static let lasso = "lasso"
    }
    /**
     The width of the lines when drawing. It is scaled by 4 when highlighting vs. drawing
     */
    public var lineWidth: CGFloat{
        get{
            return Constants.lineWidth + Constants.halfPointShift
        }
        set{
            Constants.lineWidth = max(5, newValue)
        }
    }
    /**
     The document that was added
    */
    public let document: PDFDocument
    private let backgroundView = UIScrollView()
    /**
    The number of pages within the document
     */
    public let numberOfPages: Int
    private(set) var drawer = DrawingView()
    /**
    The color that the drawing view will draw with (defaults to black)
    */
    public var drawingColor: UIColor{
        get{
            return drawer.drawingColor
        }
        set{
            drawer.drawingColor = newValue
        }
    }
    /**
     The color that the drawing view will highlight with (defaults to yellow)
     */
    public var highlightColor: UIColor{
        get{
            return drawer.highlightColor
        }
        set{
            drawer.highlightColor = newValue
        }
    }
    /**
     The key to tell the view what to use (defaults to draw)
     */
    public var drawingKey: String{
        get{
            return drawer.drawingType
        }
        set{
            self.drawer.hideAllKeyboards()
            self.drawer.endLasso()
            if (newValue != DrawingKeys.scroll){
                backgroundView.panGestureRecognizer.minimumNumberOfTouches = 2
                drawer.isUserInteractionEnabled = true
            }else{
                backgroundView.panGestureRecognizer.minimumNumberOfTouches = 1
                drawer.isUserInteractionEnabled = false
            }
            drawer.drawingType = newValue
        }
    }
    private let backgroundHold = UIView()
    private var offsets = [Border]()
    /**
     The Pages that are visible
    */
    public private(set) var visiblePages = [PDFPageDisplayer]()
    /**
     The current page number
    */
    public private(set) var currentPageNumber = 0
	/**
  	 * The way the document is rendered
     */
	public let renderStyle: DrawingStyle
    public weak var delegate: PDFDelegate?
	public init(frame: CGRect, document: PDFDocument, style: DrawingStyle = .vertical, delegate: PDFDelegate? = nil){
        self.document = document
        self.numberOfPages = document.pageCount
        self.delegate = delegate
		self.renderStyle = style
        guard let page = document.page(at: 0) else {
            super.init(frame: frame)
            delegate?.viewWasCreated()
            return
        }
        super.init(frame: frame)
		let scale = self.getScale(number: 0)
		let pageSize = CGSize(width: (page.bounds(for: .mediaBox).width) * scale, height: (page.bounds(for: .artBox).height * scale))
        backgroundView.frame = frame
        self.drawer.drawingType = DrawingKeys.draw
		if (style == .vertical){
			offsets.append(Border(topX: 0, topY: 0, bottomX: 0, bottomY: pageSize.height))
		} else {
			offsets.append(Border(topX: 0, topY: 0, bottomX: pageSize.width, bottomY: 0))
		}
        for counter in 1 ..< numberOfPages{
			let internalScale = self.getScale(number: counter)
			guard let upPage = document.page(at: counter) else {return}
			let border: Border
			switch self.renderStyle {
				case .horizontal:
					border = Border(topX: offsets[counter - 1].bottomX, topY: offsets[counter - 1].bottomY, bottomX: offsets[counter - 1].bottomX + (upPage.bounds(for: .artBox).width * internalScale), bottomY: offsets[counter - 1].bottomY)
					break
				case .vertical:
					border = Border(topX: offsets[counter - 1].bottomX, topY:offsets[counter - 1].bottomY, bottomX: offsets[counter - 1].bottomX, bottomY: offsets[counter - 1].bottomY + (upPage.bounds(for: .artBox).height * internalScale))
					break
			}
            offsets.append(border)
        }
		let holder: UIView
		switch self.renderStyle {
		case .horizontal:
			holder = UIView(frame: CGRect(x: 0, y: 0, width: offsets.last?.bottomX ?? 0, height: self.frame.height))
			break
		case .vertical:
			holder = UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: offsets.last?.bottomY ?? 0))
			break
		}
        drawer = DrawingView(frame: holder.frame)
        drawer.delegate = self
        self.backgroundView.contentInset = UIEdgeInsets(top: 1, left: 1, bottom: 1, right: 1)
        backgroundHold.frame = holder.frame
        backgroundHold.addSubview(holder)
        backgroundHold.addSubview(drawer)
        backgroundView.addSubview(backgroundHold)
        backgroundView.contentSize = holder.frame.size
        backgroundView.minimumZoomScale = 1
        backgroundView.maximumZoomScale = 3
        backgroundView.delegate = self
        backgroundView.bouncesZoom = false
        backgroundView.scrollsToTop = true
        backgroundView.bounces = false
        self.addSubview(backgroundView)
        drawBeginning(holder: holder, range: (0 ..< min(3, numberOfPages)))
		drawer.isUserInteractionEnabled = true
        delegate?.viewWasCreated()
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    private func drawBeginning(holder: UIView, range: CountableRange<Int>){
        visiblePages.forEach({$0.removeFromSuperview()})
        visiblePages.removeAll()
        for counter in range
        {
			visiblePages.append(drawPage(number: counter))
        }
    }
    private func findRange(_ currentPageNumber: Int) -> CountableRange<Int>{
        if (currentPageNumber - 2 < 0){
            return 0 ..< 3
        }
        else if (currentPageNumber != numberOfPages){
            return currentPageNumber - 2 ..< currentPageNumber + 1
        }
        else{
            return currentPageNumber - 3 ..< currentPageNumber
        }
    }
	@discardableResult
    private func drawPage(number: Int) -> PDFPageDisplayer{
		guard let page = document.page(at: number) else {return PDFPageDisplayer(frame: CGRect.zero, page: nil)}
		let size = page.bounds(for: .artBox)
		let internalScale = self.getScale(number: number)
		let displayer: PDFPageDisplayer
		switch self.renderStyle {
		case .vertical:
			displayer = PDFPageDisplayer(frame: CGRect(x: offsets[number].topX, y: offsets[number].topY, width: self.frame.width, height: size.height * internalScale), page: page, scale: internalScale)
			break
		case .horizontal:
			displayer = PDFPageDisplayer(frame: CGRect(x: offsets[number].topX, y: offsets[number].topY, width: size.width * internalScale, height: self.frame.height), page: page, scale: internalScale)
		}
        displayer.pageNumber = number
        backgroundHold.subviews[0].addSubview(displayer)
		return displayer
    }
    /**
     Creates a new PDF out of the PDFView
     - returns: The Data representation of the PDFDocument
    */
    public func createPDF() -> Data {
        drawer.endLasso()
        drawer.hideAllKeyboards()
        let zoomScale = backgroundView.zoomScale
        let page = self.currentPageNumber
		let newDocument = NSMutableData()
		let frame = self.backgroundView.frame
		UIGraphicsBeginPDFContextToData(newDocument, CGRect(x: 0,y: 0, width: backgroundView.contentSize.width, height: backgroundView.contentSize.height), nil)
		UIGraphicsBeginPDFContextToFile("/Users/Jack/Updated.pdf", CGRect(x: 0,y: 0, width: backgroundView.contentSize.width, height: backgroundView.contentSize.height), nil)
		backgroundView.delegate = nil
		let contentOffset = self.backgroundView.contentOffset
		guard let context = UIGraphicsGetCurrentContext() else {
			UIGraphicsEndPDFContext()
			return newDocument as Data
		}
		context.setShouldSmoothFonts(true)
		context.textMatrix = CGAffineTransform.identity
		backgroundView.setContentOffset(CGPoint.zero, animated: false)
		scrollViewDidScrollToTop(self.backgroundView)
		for counter in 0 ..< numberOfPages {
			backgroundView.setZoomScale(1, animated: false)
			let scale = self.getScale(number: counter)
			backgroundView.minimumZoomScale = 1 / scale
			let offset = offsets[counter]
			backgroundView.setContentOffset(CGPoint(x: offset.topX, y: offset.topY), animated: false)
			switch self.renderStyle {
			case .horizontal:
				backgroundView.frame = CGRect(x: frame.minX, y: frame.minY, width: (offset.bottomX - offset.topX), height: backgroundView.frame.height)
			case .vertical:
				backgroundView.frame = CGRect(x: frame.minX, y: frame.minY, width: backgroundView.frame.width, height: (offset.bottomY - offset.topY))
			}
			backgroundView.setZoomScale(1 / scale, animated: false)
			UIGraphicsBeginPDFPageWithInfo(CGRect(x: 0, y: 0, width: backgroundView.frame.width, height: backgroundView.frame.height), nil)
			context.translateBy(x: -offset.topX, y: -offset.topY)
			backgroundView.layer.render(in: context)
			if (counter + 3 < numberOfPages){
				self.visiblePages.first?.removeFromSuperview()
				self.visiblePages.removeFirst()
				visiblePages.append(drawPage(number: counter + 3))
			}
		}
		UIGraphicsEndPDFContext()
		backgroundView.frame = frame
		backgroundView.minimumZoomScale = 1
		backgroundView.setZoomScale(zoomScale, animated: false)
		backgroundView.setContentOffset(contentOffset, animated: false)
		drawBeginning(holder: self.backgroundHold.subviews[0], range: findRange(page))
		backgroundView.delegate = self
		self.currentPageNumber = page
        return newDocument as Data
    }
    /**
     Scrolls to a certain page
     - parameter page: The page to scroll to
    */
    public func scrollTo(page: Int){
        let currentPageNumber = page
        if (currentPageNumber < 1){
            self.currentPageNumber = 1
        }else if (currentPageNumber > numberOfPages){
            self.currentPageNumber = numberOfPages
        }else{
            self.currentPageNumber = currentPageNumber
        }
        backgroundView.setZoomScale(1, animated: true)
        backgroundView.delegate = nil
        backgroundView.setContentOffset(CGPoint(x: self.offsets[self.currentPageNumber - 1].topX, y: self.offsets[self.currentPageNumber - 1].topY), animated: true)
        self.drawBeginning(holder: self.backgroundHold.subviews[0], range: findRange(self.currentPageNumber))
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {self.backgroundView.delegate = self})
        delegate?.scrolled(to: page)
    }
}
extension PDFDrawingView: DrawingDelegate{
	
    var zoomScale: CGFloat {
        return backgroundView.zoomScale
    }
    
    var contentOffset: CGFloat {
        get {
            return backgroundView.contentOffset.y / self.zoomScale
        }
        set {
            self.backgroundView.setContentOffset(CGPoint(x: backgroundView.contentOffset.x, y: newValue * backgroundView.zoomScale), animated: true)
        }
    }
    
    func getMinScale() -> CGFloat {
        return backgroundView.minimumZoomScale
    }
    
    func getMaxScale() -> CGFloat {
        return backgroundView.maximumZoomScale
    }
    
    func setMinScale(scale: CGFloat) {
        backgroundView.minimumZoomScale = scale
    }
    
    func setMaxScale(scale: CGFloat) {
        backgroundView.maximumZoomScale = scale
    }
    
    func changeMovement(canMove: Bool) {
        backgroundView.isScrollEnabled = canMove
    }
    
    func scrollViewIsScrolling() -> Bool {
        return backgroundView.isDragging || backgroundView.isDecelerating
    }
}
extension PDFDrawingView: UIScrollViewDelegate{
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.backgroundHold
    }
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        self.drawer.isUserInteractionEnabled = false
    }
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        if (self.drawer.drawingType != DrawingKeys.scroll){
            self.drawer.isUserInteractionEnabled = true
        }
    }
    private func checkBelow(offset: CGFloat, test: CGFloat) -> Bool{
        return test - offset < self.frame.height && test >= offset
    }
    private func checkAbove(offset: CGFloat, test: CGFloat) -> Bool{
        return offset - test < self.frame.height && offset >= test
    }
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        drawBeginning(holder: self.backgroundHold.subviews[0],range: 0 ..< min(numberOfPages, 3))
        
    }
	
	private func getScale(number: Int) -> CGFloat{
		guard let page = document.page(at: number) else{
			return -1
		}
		let bounds = page.bounds(for: .artBox)
		switch self.renderStyle {
		case .horizontal:
			return self.frame.height / bounds.height
		case .vertical:
			return self.frame.width / bounds.width
		}
	}
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
		switch self.renderStyle {
		case .horizontal:
			updateHorizontal(scrollView)
			break
		case .vertical:
			updateVertical(scrollView)
			break
		}
    }
	// Updates the views horizontally
	private func updateHorizontal(_ scrollView: UIScrollView) {
		if (visiblePages[0].pageNumber > 0){
			if (checkAbove(offset: scrollView.contentOffset.x / scrollView.zoomScale, test: offsets[visiblePages[0].pageNumber].topX)){
				self.visiblePages.last?.removeFromSuperview()
				self.visiblePages.removeLast()
				self.visiblePages.insert(self.drawPage(number: visiblePages[0].pageNumber - 1), at: 0)
			}
		}
		if let last = visiblePages.last, (last.pageNumber < numberOfPages - 1){
			if (checkBelow(offset: scrollView.contentOffset.x / scrollView.zoomScale, test: offsets[last.pageNumber].bottomX)){
				self.visiblePages[0].removeFromSuperview()
				self.visiblePages.removeFirst()
				self.visiblePages.append(self.drawPage(number: last.pageNumber + 1))
			}
		}
		
		let pageNumber = currentPageNumber
		let offset = scrollView.contentOffset / scrollView.zoomScale +  (scrollView.frame.width / 2)
		for page in visiblePages{
			let border = offsets[page.pageNumber]
			if (border.topX <= offset.x && border.bottomX >= offset.x){
				self.currentPageNumber = page.pageNumber + 1
				
			}
		}
		if (pageNumber != currentPageNumber){
			delegate?.scrolled(to: currentPageNumber)
		}
	}
	// Updates the views vertically
	private func updateVertical(_ scrollView: UIScrollView)  {
		if (visiblePages[0].pageNumber > 0){
			if (checkAbove(offset: scrollView.contentOffset.y / scrollView.zoomScale, test: offsets[visiblePages[0].pageNumber].topY)){
				self.visiblePages.last?.removeFromSuperview()
				self.visiblePages.removeLast()
				self.visiblePages.insert(self.drawPage(number: visiblePages[0].pageNumber - 1), at: 0)
			}
		}
		if let last = visiblePages.last, (last.pageNumber < numberOfPages - 1){
			if (checkBelow(offset: scrollView.contentOffset.y / scrollView.zoomScale, test: offsets[last.pageNumber].bottomY)){
				self.visiblePages[0].removeFromSuperview()
				self.visiblePages.removeFirst()
				self.visiblePages.append(self.drawPage(number: last.pageNumber + 1))
			}
		}
		
		let pageNumber = currentPageNumber
		let offset = scrollView.contentOffset / scrollView.zoomScale +  (scrollView.frame.height / 2)
		for page in visiblePages{
			let border = offsets[page.pageNumber]
			if (border.topY <= offset.y && border.bottomY >= offset.y){
				self.currentPageNumber = page.pageNumber + 1
				
			}
		}
		if (pageNumber != currentPageNumber){
			delegate?.scrolled(to: currentPageNumber)
		}
	}
}
public extension Int{
    public func toString() -> String{
        return "\(self)"
    }
}
extension CGRect{
    static func *= (lhs: inout CGRect, rhs: CGFloat){
        lhs = CGRect(x: lhs.origin.x, y: lhs.origin.y, width: lhs.width * rhs, height: lhs.height * rhs)
    }
    static func / (lhs: CGRect, rhs: CGFloat) -> CGRect{
        return CGRect(x: lhs.origin.x, y: lhs.origin.y, width: lhs.width / rhs, height: lhs.height / rhs)
    }
}
extension CGPoint{
    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint{
        return CGPoint(x: 0, y: lhs.y / rhs)
    }
    static func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint{
        return CGPoint(x: lhs.x, y: lhs.y + rhs)
    }
}
