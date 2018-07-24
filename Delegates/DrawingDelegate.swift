//
//  DrawingDelegate.swift
//  drawSecure
//
//  Created by Jack Rosen on 6/5/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation
import UIKit

protocol DrawingDelegate: class{
    /**
     The scale that the PDF was transformed
     - returns: The transformed scale
     */
    var scale: CGFloat {get}
    /**
     The zoom scale of the PDFView
     - returns: The zoom scale
     */
    var zoomScale: CGFloat{get}
    /**
     The content offset of the PDFView
     - returns: The content offset without the zoom
     */
    var contentOffset: CGFloat {get set}
    /**
    The frame of the PDFView
    - returns: The frame
     */
    var frame: CGRect{get}
    /**
     The minimum scale that the scrollview can zoom
     - returns: The minimum scale
     */
    func getMinScale() -> CGFloat
    /**
     The maximum scale that the scrollview can zoom
     - returns: The maximum scale
     */
    func getMaxScale() -> CGFloat
    /**
     Sets the minimum scale for the scrollview
     - parameter scale: the scale to set
     */
    func setMinScale(scale: CGFloat)
    /**
     Sets the maximum scale for the scrollview
     - parameter scale: the scale to set
     */
    func setMaxScale(scale: CGFloat)
    /**
     This decides whether the scrollview can move
     - parameter canMove: A boolean designating whether the scrollview can move
     */
    func changeMovement(canMove: Bool)
    /**
     Designates whether the scrollview is scrolling
     - returns: true if the scrollview is scrolling, false if not
     */
    func scrollViewIsScrolling() -> Bool
}
