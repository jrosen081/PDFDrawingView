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
    private let pageSize: CGSize
    internal let scale: CGFloat
    private let backgroundHold = UIView()
    private var offsets = [(CGFloat, CGFloat)]()
    /**
     The Pages that are visible
    */
    public private(set) var visiblePages = [PDFPageDisplayer]()
    /**
     The current page number
    */
    public private(set) var currentPageNumber = 0
    public weak var delegate: PDFDelegate?
    public init(frame: CGRect, document: PDFDocument, delegate: PDFDelegate? = nil){
        self.document = document
        numberOfPages = document.pageCount
        self.delegate = delegate
        guard let page = document.page(at: 0) else {
            self.pageSize = CGSize.zero
            self.scale = 0
            super.init(frame: frame)
            delegate?.viewWasCreated()
            return
        }
        scale = UIScreen.main.bounds.width / page.bounds(for: .artBox).width
        let holder = UIView(frame: CGRect(x: 0, y: 0, width: (page.bounds(for: .artBox).width), height: ((page.bounds(for: .artBox).height) * CGFloat((document.pageCount)))))
        pageSize = CGSize(width: (page.bounds(for: .mediaBox).width) * scale, height: (page.bounds(for: .artBox).height * scale))
        super.init(frame: frame)
        backgroundView.frame = frame
        self.drawer.drawingType = DrawingKeys.draw
        for counter in 0 ..< numberOfPages{
            offsets.append((CGFloat(counter) * pageSize.height / scale, CGFloat(counter + 1) * pageSize.height / scale))
        }
        holder.transform = CGAffineTransform(scaleX: scale, y: scale)
        holder.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: holder.frame.height)
        drawer = DrawingView(frame: holder.frame)
        drawer.delegate = self
        drawer.scale = scale
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
            guard let page = document.page(at: counter) else {return}
            let displayer = PDFPageDisplayer(frame: CGRect(x: 0, y: (pageSize.height / scale) * CGFloat(counter), width: pageSize.width / scale, height: pageSize.height / scale), page: page)
            displayer.pageNumber = counter
            holder.addSubview(displayer)
            visiblePages.append(displayer)
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
    private func drawPage(number: Int){
        visiblePages.first!.removeFromSuperview()
        visiblePages.removeFirst()
        let displayer = PDFPageDisplayer(frame: CGRect(x: 0, y: offsets[number].0, width: pageSize.width / scale, height: pageSize.height / scale), page: document.page(at: number)!)
        displayer.pageNumber = number
        visiblePages.append(displayer)
        backgroundHold.subviews[0].addSubview(displayer)
    }
    public func createPDF() -> Data {
        drawer.endLasso()
        drawer.hideAllKeyboards()
        let zoomScale = backgroundView.zoomScale
        let page = self.currentPageNumber
        backgroundView.minimumZoomScale = 1 / scale
        backgroundView.setZoomScale(1 / scale, animated: false)
        backgroundView.delegate = nil
        let newDocument: NSMutableData = NSMutableData()
        UIGraphicsBeginPDFContextToData(newDocument, CGRect(x: 0,y: 0, width: backgroundView.contentSize.width, height: backgroundView.contentSize.height), nil)
        let contentOffset = backgroundView.contentOffset
        let context = UIGraphicsGetCurrentContext()!
        context.setShouldSmoothFonts(true)
        context.textMatrix = CGAffineTransform.identity
        backgroundView.frame = CGRect(x: backgroundView.frame.minX, y: backgroundView.frame.minY, width: backgroundView.contentSize.width, height: (backgroundView.contentSize.height / CGFloat(numberOfPages))).integral
        backgroundView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
        scrollViewDidScrollToTop(self.backgroundView)
        for counter in 0 ..< numberOfPages
        {
            backgroundView.setContentOffset(CGPoint(x: 0, y: (backgroundView.contentSize.height / CGFloat(numberOfPages)) * CGFloat(counter)), animated: false)
            UIGraphicsBeginPDFPageWithInfo(CGRect(x:0,y:0, width: backgroundView.frame.width, height: backgroundView.frame.height), nil)
            context.translateBy(x: 0, y: -backgroundView.contentOffset.y)
            backgroundView.layer.render(in: context)
            if (counter + 3 < numberOfPages){
                drawPage(number: counter + 3)
            }
        }
        UIGraphicsEndPDFContext()
        backgroundView.setContentOffset(contentOffset, animated: false)
        drawBeginning(holder: self.backgroundHold.subviews[0], range: findRange(currentPageNumber))
        backgroundView.delegate = self
        backgroundView.setZoomScale(zoomScale, animated: false)
        backgroundView.minimumZoomScale = 1
        self.currentPageNumber = page
        return newDocument as Data
    }
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
        backgroundView.setContentOffset(CGPoint(x: 0, y: self.offsets[self.currentPageNumber - 1].0 * scale), animated: true)
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
        return test - offset < UIScreen.main.bounds.height && test >= offset
    }
    private func checkAbove(offset: CGFloat, test: CGFloat) -> Bool{
        return offset - test < UIScreen.main.bounds.height && offset >= test
    }
    public func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        drawBeginning(holder: self.backgroundHold.subviews[0],range: 0 ..< min(numberOfPages, 3))
        
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (visiblePages[0].pageNumber > 0){
            if (checkAbove(offset: scrollView.contentOffset.y / scrollView.zoomScale, test: offsets[visiblePages[0].pageNumber - 1].1 * scale)){
                let displayer = PDFPageDisplayer(frame: CGRect(x: 0, y: offsets[visiblePages[0].pageNumber - 1].0, width: pageSize.width / scale, height: pageSize.height / scale), page: document.page(at: visiblePages[0].pageNumber - 1)!)
                displayer.pageNumber = visiblePages[0].pageNumber - 1
                self.backgroundHold.subviews[0].addSubview(displayer)
                self.visiblePages.insert(displayer, at: 0)
                self.visiblePages.last!.removeFromSuperview()
                self.visiblePages.removeLast()
            }
        }
        if (visiblePages.last!.pageNumber < numberOfPages - 1){
            if (checkBelow(offset: scrollView.contentOffset.y / scrollView.zoomScale, test: offsets[visiblePages.last!.pageNumber + 1].0 * scale)){
                let displayer = PDFPageDisplayer(frame: CGRect(x: 0, y: offsets[visiblePages.last!.pageNumber + 1].0, width: pageSize.width / scale, height: pageSize.height / scale), page: document.page(at: visiblePages.last!.pageNumber + 1)!)
                displayer.pageNumber = visiblePages.last!.pageNumber + 1
                self.backgroundHold.subviews[0].addSubview(displayer)
                self.visiblePages.append(displayer)
                self.visiblePages[0].removeFromSuperview()
                self.visiblePages.removeFirst()
            }
        }
        let pageNumber = currentPageNumber
        for page in visiblePages{
            if (page.frame.contains(((scrollView.contentOffset / scale) + ((scrollView.frame.height / scale) / 2)) / backgroundView.zoomScale)){
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
