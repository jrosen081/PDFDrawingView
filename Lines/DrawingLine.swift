//
//  Line.swift
//  drawSecure
//
//  Created by Jack Rosen on 6/12/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit

class DrawingLine: Line{
    private var scale: CGFloat{
        return self.drawingType == .highlight ? 8 : 2
    }
    private var strokes: [Stroke] = [Stroke]()
    private var touchToStroke = [NSNumber: Int]()
    private var previousPoints: (CGPoint, CGPoint)?
    private var updatedIndex: Int = 0
    var opacity: Float
    private(set) var finished = false
    private(set) var color: CGColor
	private var circular: Bool = false
	// Wrapper for append to work more functionally
	func funAppend(_ point: CGPoint, with touch: UITouch?, path: UIBezierPath? = nil, predictedTouches: [CGPoint] = []) -> DrawingLine{
		self.append(point, with: touch, path: path, predictedTouches: predictedTouches)
		return self
	}
	// Appends the given info onto the line
    func append(_ point: CGPoint, with touch: UITouch?, path: UIBezierPath? = nil, predictedTouches: [CGPoint] = []){
        self.predicted = predictedTouches
		if let last = points.last{
            let vector = last.distance(to: point).normalized().unitize() * scale
            if let _ = touch{
				strokes.append(Stroke(touch: touch!, vector: vector, location: point))
				if (touch!.estimationUpdateIndex == nil){
					if (updatedIndex == strokes.count - 1){
						previousPoints = previousPoints ?? (last - vector, last + vector)
						_path.addStrokeToPath(stroke: strokes.last!, previousPoints: &previousPoints)
						updatedIndex = strokes.count
					}
				} else{
					touchToStroke[touch!.estimationUpdateIndex!] = points.count - 1
				}
            } else{
                previousPoints = previousPoints ?? (last - vector, last + vector)
                strokes.append(Stroke(force: 1, vector: vector, location: point))
                _path.addStrokeToPath(stroke: strokes.last!, previousPoints: &previousPoints)
                updatedIndex = strokes.count
            }
        }
        self.points.append(point)
        if let _ = path{
			circular = true
            _path = path!
            updatedIndex = strokes.count
        }
        self.drawLine(path: path)
    }
	
	// Updates the opacity of this line
	func updateOpacity() {
		if (self.opacity == self.layer.opacity) {
			self.layer.opacity = Constants.opacity
		} else {
			self.layer.opacity = self.opacity
		}
	}
	// Ends the line at the end
    func finishAll(){
        predicted.removeAll()
        _path = path
        finished = true
    }
	// finishes the line when the given touch was given the finished touch
    func finish(with touch: UITouch){
        if let index = touchToStroke[touch.estimationUpdateIndex!]{
            touchToStroke.removeValue(forKey: touch.estimationUpdateIndex!)
            strokes[index].force = touch.force == 0 ? 1 : touch.force
            strokes[index].doneUpdating = true
            if (index == updatedIndex + 1){
                for counter in index ..< strokes.count{
                    guard let _ = strokes[counter].actualTop else{break}
                    previousPoints = previousPoints ?? (points[0], points[0])
                    _path.addStrokeToPath(stroke: strokes[counter], previousPoints: &previousPoints)
                    updatedIndex = counter
                    if let number = strokes[counter].estimationUpdateIndex, let _ = touchToStroke[number]{
                        touchToStroke.removeValue(forKey: number)
                    }
                }
            }
        }
    }
	// Destroys the given line
    func removeAll(){
        self.points.removeAll()
        self.strokes.removeAll()
        self.touchToStroke.removeAll()
        self.layer.removeFromSuperlayer()
        self.previousPoints = nil
        self.updatedIndex = 0
        self._path = UIBezierPath()
        self.layer.path = nil
    }
    private(set) var drawingType: DrawingTypes
    
	init(points: [CGPoint], opacity: Float, color: CGColor, lineWidth: CGFloat, drawingType: DrawingTypes){
        self.opacity = opacity
        self.color = color
        self.lineWidth = lineWidth
        self.drawingType = drawingType
        super.init(startingPoint: points[0])
        self.points = points
        self.layer.fillColor = color
        self.layer.opacity = opacity
        self.layer.strokeColor = nil
    }
	
	// Convenience constructor
	convenience init(startingPoint: CGPoint, color: CGColor) {
		self.init(points: [startingPoint], opacity: 1, color: color, lineWidth: Constants.lineWidth, drawingType: .draw)
	}
	
	// The finished path plus all points not finished/predicted
    override var path: UIBezierPath{
        let newPath = UIBezierPath()
        newPath.append(_path)
        var previousPoints = self.previousPoints
        if previousPoints == nil{
            previousPoints = (points[updatedIndex], points[updatedIndex])
        }
        for counter in updatedIndex ..< strokes.count{
            newPath.addStrokeToPath(stroke: strokes[counter], previousPoints: &previousPoints)
        }
        var previousPoint = points.last!
        for point in predicted{
            let vector = previousPoint.distance(to: point).normalized().unitize() * scale
            newPath.addStrokeToPath(stroke: Stroke(force: strokes.last!.force, vector: vector, location: point), previousPoints: &previousPoints)
            previousPoint = point
        }
        newPath.lineWidth = lineWidth
        return newPath
    }
    
    private(set) var lineWidth: CGFloat
    
    private var boundingBox: CGRect{
        return path.bounds
    }
    
    subscript(index: Int) -> CGPoint{
        get{
            return points[index]
        }
        set{
            self.points[index] = newValue
        }
    }
	
	// Does the given path contain the point within?
	func contains(_ point: CGPoint) -> Bool{
		if circular {
			return self._path.contains(point)
		}
		for counter in 0 ..< self.points.count - 1{
			let thisPoint = self.points[counter]
			let nextPoint = self.points[counter + 1]
			let angle = atan2(Double(thisPoint.y - point.y), Double(thisPoint.x - point.x))
			if (self.doIntersect(thisPoint, nextPoint, point.shiftDownBy(angle, Double(self.lineWidth)), point.shiftUpBy(angle, Double(self.lineWidth)))) {
				return true
			}
		}
		return false
	}
	// Do the two line intersect?
    func intersects(line: Line) -> Bool{
        for counter in 1 ..< self.points.count{
            for tracker in 1 ..< line.points.count{
                if (doIntersect(self.points[counter - 1], self.points[counter], line.points[tracker - 1], line.points[tracker])){
                    return true
                }
            }
        }
        return false
    }
    //Check if the two lines intersect, given their endpoints
    private func doIntersect(_ p1: CGPoint, _ q1: CGPoint, _ p2: CGPoint, _ q2: CGPoint) -> Bool
    {
        let o1 = orientation(p1, q1, p2)
        let o2 = orientation(p1, q1, q2)
        let o3 = orientation(p2, q2, p1)
        let o4 = orientation(p2, q2, q1)
        if (o1 != o2 && o3 != o4){return true}
        if (o1 == 0 && onSegment(p1, q2, q1)){return true}
        if (o2 == 0 && onSegment(p1, q2, q1)){return true}
        if (o3 == 0 && onSegment(p2, p1, q2)){return true}
        if (o4 == 0 && onSegment(p2, q1, q2)){return true}
        return false
    }
    //Checks the direction of the three points
    private func orientation(_ p: CGPoint, _ q: CGPoint, _ r: CGPoint) -> Int
    {
        let value = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
        if (value == 0) {return 0}
        return value > 0 ? 1: 2
    }
    //Checks if the point is on the segment
    private func onSegment(_ p1: CGPoint, _ p2: CGPoint, _ q1: CGPoint) -> Bool
    {
        return p2.x <= max(p1.x, q1.x) && p2.x >= min(p1.x, q1.x) && p2.y <= max(p1.y, q1.y) && p2.y > min(p1.y, q1.y)
    }
    override func drawLine(path: UIBezierPath? = nil){
        let newPath = path ?? self.path
        if (self.layer.path == nil){
			self.layer.fillRule = CAShapeLayerFillRule.nonZero
        }
        self.layer.path = newPath.cgPath
    }
}

fileprivate extension UIBezierPath{
    func addStrokeToPath(stroke: Stroke, previousPoints: inout (CGPoint, CGPoint)?){
        guard let lastPoints = previousPoints else {return}
        let actualBottom = stroke.actualBottom ?? stroke.estimatedBottom
        let actualTop = stroke.actualTop ?? stroke.estimatedTop
        self.move(to: lastPoints.0)
        self.addQuadCurve(to: actualBottom, controlPoint: actualBottom.midPoint(with: lastPoints.0))
        self.addLine(to: actualTop)
        self.addQuadCurve(to: lastPoints.1, controlPoint: lastPoints.1.midPoint(with: actualTop))
        self.addLine(to: lastPoints.0)
        previousPoints = (actualBottom, actualTop)
    }
}

