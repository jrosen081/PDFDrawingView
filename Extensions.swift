//
//  Extensions.swift
//  SamplePDFDrawingViewApp
//
//  Created by Jack Rosen on 4/5/19.
//  Copyright © 2019 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit

public extension CGPoint{
	// Returns a new point with the different subtracted
	func subtract(point: CGPoint) -> CGPoint{
		return CGPoint(x: self.x - point.x, y: self.y - point.y)
	}
	
	// Scales a point
	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}
	// Creates a line of points between this and the other point
	func addIncrements(amount: Int, until point: CGPoint) -> [CGPoint]
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
	func squareAround() -> [CGPoint] {
		return [CGPoint(x: self.x - Constants.lineWidth,y: self.y - Constants.lineWidth), CGPoint(x: self.x + Constants.lineWidth,y: self.y - Constants.lineWidth), CGPoint(x: self.x + Constants.lineWidth,y: self.y + Constants.lineWidth)]
	}
	
	static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint{
		return CGPoint(x: 0, y: lhs.y / rhs)
	}
	static func + (lhs: CGPoint, rhs: CGFloat) -> CGPoint{
		return CGPoint(x: lhs.x, y: lhs.y + rhs)
	}
	
	// Gets the midpoint between two points
	func midPoint(with point: CGPoint) -> CGPoint
	{
		return CGPoint(x: (self.x + point.x) / 2, y: (self.y + point.y) / 2)
	}
	
	// Moves the point
	func moveBy(x: CGFloat, y: CGFloat) -> CGPoint
	{
		return self + CGVector(dx: x, dy: y)
	}
	
	// Shifts up the point
	func shiftUpBy(_ angle: Double, _ offsetAmount: Double) -> CGPoint {
		return CGPoint(x: Double(self.x) + sin(angle) * offsetAmount, y: Double(self.y) + cos(angle) * offsetAmount)
	}
	
	// Shifts down the point
	func shiftDownBy(_ angle: Double, _ offsetAmount: Double) -> CGPoint {
		return CGPoint(x: Double(self.x) - sin(angle) * offsetAmount, y: Double(self.y) - cos(angle) * offsetAmount)
	}
	
	// Distance between two points
	func distance(to point: CGPoint) -> CGVector{
		return CGVector(dx: point.x - self.x, dy: point.y - self.y)
	}
	
	static func + (lhs: CGPoint, rhs: CGVector) -> CGPoint{
		return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
	}
	
	static func - (lhs: CGPoint, rhs: CGVector) -> CGPoint{
		return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
	}
}

public extension UITextView{
	// Moves the text view
	func moveBy(x: CGFloat, y: CGFloat)
	{
		self.frame.origin = CGPoint(x: self.frame.origin.x + x, y: self.frame.origin.y + y)
	}
}

public extension Int{
	func toString() -> String{
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

extension CGVector{
	func normalized() -> CGVector{
		let y = self.dy == 0 ? 0 : -self.dy
		return CGVector(dx: y, dy: self.dx)
	}
	func unitize() -> CGVector{
		var distance = sqrt(Double((self.dx * self.dx) + (self.dy * self.dy)))
		if distance == 0{
			distance = 1
		}
		return CGVector(dx: self.dx / CGFloat(distance), dy: self.dy / CGFloat(distance))
	}
	static func * (lhs: CGVector, rhs: CGFloat) -> CGVector{
		return CGVector(dx: lhs.dx * rhs, dy: lhs.dy * rhs)
	}
}


extension Double{
	func abs() -> Double{
		return Swift.abs(self)
	}
}
