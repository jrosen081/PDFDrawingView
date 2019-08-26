//
//  Stroke.swift
//  drawSecure
//
//  Created by Jack Rosen on 6/19/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit
struct Stroke {
    let estimatedTop: CGPoint
    let estimatedBottom: CGPoint
    var location: CGPoint
    var force: CGFloat{
        didSet{
            if (force < 1){
                force = 1
            }
        }
    }
    var unitVector: CGVector
    var actualTop: CGPoint?{
        if (doneUpdating){
            return location + (unitVector * force)
        }
        else{
            return nil
        }
    }
    var actualBottom: CGPoint?{
        if (doneUpdating){
            return location - (unitVector * force)
        }
        else{
            return nil
        }
        
    }
    var estimationUpdateIndex: NSNumber?
    var doneUpdating: Bool
}
extension Stroke{
    init(touch: UITouch, vector: CGVector, location: CGPoint){
        self.location = location
        force = touch.force == 0 ? 1: touch.force
        unitVector = vector
        estimatedTop = location + (vector * force)
        estimatedBottom = location - (vector * force)
        doneUpdating = touch.estimationUpdateIndex == nil
        estimationUpdateIndex = touch.estimationUpdateIndex
    }
    init(force: CGFloat, vector: CGVector, location: CGPoint){
        self.location = location
        self.force = force
        unitVector = vector
        estimatedTop = location + vector
        estimatedBottom = location - vector
        doneUpdating = true
    }
}
