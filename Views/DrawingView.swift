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
    private var previousPoints = [Line]()
    private var previousLayers = [CALayer]()
    private var previousPoint = CGPoint()
    private var startPoint = CGPoint()
    private var touchPoint = CGPoint()
    private var swiped = false
    private var layers: [CAShapeLayer] = [CAShapeLayer]()
    var drawingColor = UIColor.black
    var highlightColor = UIColor.yellow
    private var lines: [DrawingLine] = [DrawingLine]()
    private var keyboard = false
    private let menu = UIMenuController.shared
    private var textView = OverTopText()
    private var selectedIndex = [Int]()
    lazy var tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
    var drawingType = PDFDrawingView.DrawingKeys.draw
    var edit = false
    var textViews = [OverTopText]()
    var scale: CGFloat = 1
    var scrollViewIsScrolling: Bool{
        return delegate?.scrollViewIsScrolling() ?? false
    }
    private var selected = false {
        didSet{
            if (selected){
                canZoom = false
            }
            else
            {
                canZoom = true
            }
        }
    }
    private var zoomScale: CGFloat{
        get{
            return delegate?.zoomScale ?? 1
        }
    }
    private var lasso = Lasso(startingPoint: CGPoint.zero)
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
    private var touchesName = 0{
        didSet{
            for textView in textViews
            {
                textView.touches = self.touchesName
            }
        }
    }
    convenience init(){
        self.init(frame: CGRect.zero)
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: Notification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: Notification.Name.UIKeyboardDidShow, object: nil)
        self.backgroundColor = UIColor.clear
        self.isMultipleTouchEnabled = true
        self.isUserInteractionEnabled = true
        startPoint = CGPoint(x: -100, y: -100)
        let press = UILongPressGestureRecognizer(target: self, action: #selector(self.straight(_:)))
        press.delegate = self
        press.cancelsTouchesInView = false
        press.numberOfTouchesRequired = 1
        press.minimumPressDuration = 0.4
        self.addGestureRecognizer(press)
        tapGesture.numberOfTapsRequired = 1
        tapGesture.cancelsTouchesInView = true
        self.addGestureRecognizer(tapGesture)
    }
    @objc func keyboardWillDisappear(){
        keyboard = false
    }
    @objc func keyboardWillAppear(){
        keyboard = true
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    //Tap gesture for drawing
    @objc func tapped(_ tap: UITapGestureRecognizer){
        if (drawingType == PDFDrawingView.DrawingKeys.draw){
            let point = tap.location(in: self)
            let scale = delegate?.scale ?? 1
            let path = UIBezierPath(arcCenter: point, radius: 2 * scale, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            lines.append(DrawingLine(points: [CGPoint(x: point.x - (2 * scale),y: point.y - (2 * scale)), CGPoint(x: point.x + (2 * scale),y: point.y - (2 * scale)), CGPoint(x: point.x + (2 * scale),y: point.y + (2 * scale))], opacity: 1, color: self.drawingColor.cgColor, lineWidth: 1, drawingType: .draw))
            lines[lines.count - 1].append(CGPoint(x: point.x - (2 * scale), y: point.y - (2 * scale)), with: nil, path: path)
            self.layer.addSublayer(lines.last!.layer)
        } else if (drawingType == PDFDrawingView.DrawingKeys.erase){
			var total = lines.count
			var count = 0
			for i in 0 ..< total {
				let line = lines[count]
				if line.path.contains(tap.location(in: self)){
					lines[count].removeAll()
					lines.remove(at: count)
					count -= 1
					total -= 1
				}
				count += 1
			}
        } else if (drawingType == PDFDrawingView.DrawingKeys.text){
            if (keyboard){
                self.hideAllKeyboards()
                startPoint = CGPoint(x: -100, y: -100)
                return
            }
            edit = true
            startPoint = CGPoint(x: -100, y: -100)
            let center = tap.location(in: self)
            let textView: OverTopText = OverTopText(frame: CGRect(x:center.x - (self.frame.width / 8) / 2, y:center.y - 20, width: self.frame.width / CGFloat(8) * scale, height: 30 * scale), textContainer: nil)
            textView.layer.borderColor = UIColor.darkText.cgColor
            textView.layer.borderWidth = 1
            textView.layer.shadowColor = UIColor.black.cgColor
            textView.font = UIFont.systemFont(ofSize: textView.frame.height / UIScreen.main.scale)
            textView.allowsEditingTextAttributes = true
            textView.delegate = self
            self.textView = textView
            textView.becomeFirstResponder()
            let tap = UITapGestureRecognizer(target: self, action: #selector(DrawingView.tapGesture(_:)))
            textView.addGestureRecognizer(tap)
            self.addSubview(textView)
            textViews.append(textView)
            lines.append(DrawingLine(points: [Constants.defaultPoint], opacity: 1, color: UIColor.clear.cgColor, lineWidth: 1, drawingType: .text))
            moveTextView(textView: textView)
        }else if (drawingType == PDFDrawingView.DrawingKeys.lasso){
            if (selected && !lasso.contains(test: tap.location(in: self))){
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
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {return}
        touchPoint = touch.location(in: self)
        if (drawingType != PDFDrawingView.DrawingKeys.scroll && startPoint != CGPoint(x: -100, y: -100))
        {
            swiped = true
            if ((drawingType == PDFDrawingView.DrawingKeys.draw || drawingType == PDFDrawingView.DrawingKeys.highlight) && !lines.last!.finished)
            {
                if (touch.majorRadius >= 50){
                    return
                }
                guard let event = event, let predicted = event.predictedTouches(for: touch) else {return}
                lines[lines.count - 1].append(touchPoint, with: touch, predictedTouches: predicted.map({$0.location(in: self)}))
                previousPoint = startPoint
                startPoint = touchPoint
                return
            }
            else if (drawingType == PDFDrawingView.DrawingKeys.erase){
                let eraseLine = DrawingLine(points: [startPoint, touchPoint], opacity: 1, color: UIColor.clear.cgColor, lineWidth: 1, drawingType: .erase)
                for line in lines{
                    if (line.intersects(line: eraseLine))
                    {
                        line.layer.opacity = line.layer.opacity == Constants.opacity ? line.opacity : Constants.opacity
                    }
                }
            }
            else if (drawingType == PDFDrawingView.DrawingKeys.lasso)
            {
                if (!selected)
                {
                    lasso.append(point: touchPoint, predicted: event?.predictedTouches(for: touch)?.map({$0.location(in: self)}) ?? [])
                }
            }
        }
        startPoint = touchPoint
    }
    //Hides all keyboards
    func hideAllKeyboards(){
        for view in textViews
        {
            view.resignFirstResponder()
            view.endEditing(true)
            textViewDidEndEditing(view)
            menu.setMenuVisible(false, animated: false)
        }
        keyboard = false
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let eventList = event, let total = eventList.allTouches{
            touchesName = total.count
        }
        if (keyboard)
        {
            startPoint = CGPoint(x: -100, y: -100)
            hideAllKeyboards()
            return
        }
        if (touches.count > 1 || touchesName > 1 || scrollViewIsScrolling)
        {
            startPoint = CGPoint(x: -100, y: -100)
            return
        }
        delegate?.changeMovement(canMove: false)
        if (drawingType == PDFDrawingView.DrawingKeys.lasso)
        {
            guard let touch = touches.first else {return}
            startPoint = touch.location(in: self)
            if (!selected)
            {
                lasso.removeAll()
                lasso.starts(at: startPoint)
                self.layer.addSublayer(lasso.layer)
            }
        }
        else if drawingType != PDFDrawingView.DrawingKeys.scroll
        {
            swiped = false
            guard let touch = touches.first else {return}
            previousPoint = touch.previousLocation(in: self)
            startPoint = touch.location(in: self)
            if (drawingType == PDFDrawingView.DrawingKeys.draw)
            {
                
                lines.append(DrawingLine(points:[startPoint], opacity: 1, color: self.drawingColor.cgColor, lineWidth: Constants.lineWidth + Constants.halfPointShift, drawingType: .draw))
            }
            else if (drawingType == PDFDrawingView.DrawingKeys.highlight){
                lines.append(DrawingLine(points: [startPoint], opacity: 0.6, color: self.highlightColor.cgColor, lineWidth: Constants.lineWidth + Constants.halfPointShift, drawingType: .highlight))
            }
            if let _ = lines.last{
                self.layer.addSublayer(lines.last!.layer)
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        delegate?.changeMovement(canMove: true)
        guard lines.last != nil || drawingType == PDFDrawingView.DrawingKeys.lasso else {return}
        if (startPoint == CGPoint(x: -100, y: -100))
        {
            return
        }
        if ((drawingType == PDFDrawingView.DrawingKeys.draw || drawingType == PDFDrawingView.DrawingKeys.highlight) && !lines.last!.finished){
            if (lines.last!.layer.opacity == Constants.opacity)
            {
                lines.last?.layer.opacity = 1
                let count = lines.last!.points.count
                let last = lines.removeLast()
                lines.append(DrawingLine(points: [last.first!], opacity: last.opacity, color: last.color, lineWidth: last.lineWidth, drawingType: last.drawingType))
                for point in last.first!.addIncrements(amount: count , until: last.last!){
                    lines.last?.append(point, with: nil)
                }
                last.removeAll()
                self.layer.addSublayer(lines.last!.layer)
            }
            lines.last?.finishAll()
        }
        else if (drawingType == PDFDrawingView.DrawingKeys.lasso)
        {
            if (!selected && lasso.points.count > 1)
            {
                lasso.append(point: lasso.first!, predicted: [])
                var something = false
                var counter = 0
                for line in lines
                {
                    if (lasso.contains(line: line)){
                        self.selectedIndex.append(counter)
                        line.layer.opacity = 0.75
                        line.layer.shadowColor = line.color
                        line.layer.shadowRadius = Constants.lineWidth / 2
                        line.layer.shadowOffset = CGSize.zero
                        line.layer.shadowOpacity = 1
                        something = true
                    }
                    counter++
                }
                if (something == false)
                {
                    lasso.removeAll()
                    selected = false
                    return
                }
                let pan = UIPanGestureRecognizer(target: self, action: #selector(self.swipe(_:)))
                pan.delegate = self
                self.addGestureRecognizer(pan)
                let zoom = UIPinchGestureRecognizer(target: self, action: #selector(zoom(_:)))
                zoom.delegate = self
                self.addGestureRecognizer(zoom)
                startPoint = CGPoint.zero
                selected = true
            }
        }
        for line in self.lines.filter({$0.layer.opacity == Constants.opacity}){
            if let index = lines.index(where: {thing in thing == line}){
                self.lines.remove(at: index)
                line.removeAll()
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
        var vector = CGVector()
        var differenceX: CGFloat = 0
        var differenceY: CGFloat = 0
        if (startPoint == CGPoint.zero && pan.location(in: self) != CGPoint.zero){
            differenceX = pan.translation(in: self).x
            differenceY = pan.translation(in: self).y
        }else{
            differenceX = pan.location(in: self).x - startPoint.x
            differenceY = pan.location(in: self).y - startPoint.y
        }
        vector = CGVector(dx: differenceX, dy: differenceY)
        for index in self.selectedIndex{
            self.lines[index].translate(by: vector)
        }
        lasso.translate(by: vector)
        startPoint = pan.location(in: self)
    }
    //Allows zooming of the lasso
    @objc func zoom (_ zoom: UIPinchGestureRecognizer)
    {
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
        if selected
        {
            self.selectedIndex.removeAll()
            lasso.removeAll()
            startPoint = CGPoint(x: -100, y: -100)
            selected = false
            self.gestureRecognizers?.removeAll()
            let press = UILongPressGestureRecognizer(target: self, action: #selector(self.straight(_:)))
            press.delegate = self
            press.cancelsTouchesInView = false
            press.numberOfTouchesRequired = 1
            press.minimumPressDuration = 0.4
            self.addGestureRecognizer(press)
            self.addGestureRecognizer(tapGesture)
            for line in lines{
                line.layer.opacity = line.opacity
                line.layer.shadowRadius = 0
            }
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
        if let counter = layer.sublayers?.index(of: textView.layer)
        {
            lines.remove(at: counter)
            textView.removeFromSuperview()
            menu.menuItems = nil
            keyboard = false
            self.becomeFirstResponder()
        }
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
        if let _ = tap.view, let text = tap.view! as? OverTopText{
            if (text.isFirstResponder)
            {
                return
            }
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
            keyboard = true
        }
    }
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if (action == #selector(editStart) || action == #selector(removeTextView) || action == #selector(move) || action == #selector(resize))
        {
            return true
        }
        return false
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
        if drawingType == PDFDrawingView.DrawingKeys.draw || drawingType == PDFDrawingView.DrawingKeys.highlight
        {
            if (long.state == .began)
            {
                lines.last?.layer.opacity = Constants.opacity
            }
            else if (long.state == .failed || long.state == .cancelled)
            {
                lines.last?.layer.opacity = lines.last!.opacity
                
            }
        }
    }
}
infix operator ++
public postfix func ++ (first: inout Int){
    first += 1
}
infix operator --
public postfix func -- (first: inout Int){
    first -= 1
}
public extension CGPoint{
    public func subtract(point: CGPoint) -> CGPoint{
        return CGPoint(x: self.x - point.x, y: self.y - point.y)
    }
    public func addIncrements(amount: Int, until point: CGPoint) -> [CGPoint]
    {
        var array = [CGPoint]()
        let xDistance = (point.x - self.x) / CGFloat(amount)
        let yDistance = (point.y - self.y) / CGFloat(amount)
        for counter in 1 ..< amount
        {
            array.append(CGPoint(x: self.x + xDistance * CGFloat(counter + 1), y: self.y + yDistance * CGFloat(counter + 1)))
        }
        return array
    }
}
