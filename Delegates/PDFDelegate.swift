//
//  PDFDelegate.swift
//  DrawingPDF
//
//  Created by Jack Rosen on 7/23/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import Foundation

public protocol PDFDelegate: class{
    /**
     Gets called when the PDFDrawingView changes pages
     - parameter page: The new page number
     */
    func scrolled(to page: Int)
    /**
     Gets called when the PDFDrawingView is created and ready for usage (should be instantaneous)
    */
    func viewWasCreated()
}
