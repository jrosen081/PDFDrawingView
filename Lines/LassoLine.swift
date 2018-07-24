//
//  LassoLine.swift
//  drawSecure
//
//  Created by Jack Rosen on 6/25/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit

class Lasso: Line{
    override func drawLine(path: UIBezierPath? = nil){
        self.layer.path = self.path.cgPath
    }
    func starts(at point: CGPoint){
        self.points.append(point)
        _path.move(to: point)
    }
    func append(point: CGPoint, predicted: [CGPoint]){
        self.predicted.removeAll()
        self.predicted.append(contentsOf: predicted)
        points.append(point)
        _path.addQuadCurve(to: point, controlPoint: _path.currentPoint.midPoint(with: point))
        _path.move(to: point)
        self.drawLine()
    }
    
    func contains(line: Line) -> Bool{
        return line.points.contains(where: {self.contains(test: $0)})
    }
    //Check if point is within a given polygon
    func contains(test: CGPoint) -> Bool {
        let polygon = self.points
        let count = polygon.count
        var j = 0
        var contains = false
        for i in 0 ..< count - 1
        {
            j = i + 1
            if ( ((polygon[i].y >= test.y) != (polygon[j].y >= test.y)) &&
                (test.x <= (polygon[j].x - polygon[i].x) * (test.y - polygon[i].y) /
                    (polygon[j].y - polygon[i].y) + polygon[i].x) ) {
                contains = !contains;
            }
        }
        return contains;
    }
    func removeAll(){
        predicted.removeAll()
        self.points.removeAll()
        self.layer.removeFromSuperlayer()
        self._path = UIBezierPath()
        self.layer.path = _path.cgPath
    }
}
