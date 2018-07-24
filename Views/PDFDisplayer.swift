//
//  PDFDisplayer.swift
//  drawSecure
//
//  Created by Jack Rosen on 3/7/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import UIKit
import PDFKit

public final class PDFPageDisplayer: UIView {
    public var page: PDFPage?
    public var pageNumber = 0
    init(frame: CGRect, page: PDFPage?)
    {
        super.init(frame: frame)
        self.frame = frame
        self.page = page
    }
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    public override func draw(_ rect: CGRect) {
        guard let document = page, let context = UIGraphicsGetCurrentContext() else {return}
        UIColor.white.setFill()
        context.fill(rect)
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1, y: -1)
        document.draw(with: .artBox, to: context)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0,y: self.bounds.minY))
        path.addLine(to: CGPoint(x: UIScreen.main.bounds.width, y: self.bounds.minY))
        UIColor.lightGray.setStroke()
        path.stroke()
    }
}
