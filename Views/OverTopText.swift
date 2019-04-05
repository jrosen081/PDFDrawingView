//
//  OverTopText.swift
//  drawSecure
//
//  Created by Jack Rosen on 3/23/18.
//  Copyright © 2018 Jack Rosen. All rights reserved.
//

import UIKit

class OverTopText: UITextView, UIGestureRecognizerDelegate {
    var swipe: Bool? = nil
    private var start = CGPoint.zero
    init(){
        super.init(frame: CGRect.zero, textContainer: nil)
    }
    var touches = 0
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        self.frame = frame
        self.isEditable = true
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        self.textAlignment = .left
        self.backgroundColor = UIColor.clear
        self.textContainer.lineBreakMode = .byWordWrapping
        self.isScrollEnabled = false
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(swipe(_:)))
        panGesture.maximumNumberOfTouches = 1
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func swipe(_ pan: UIPanGestureRecognizer)
    {
        if let swipe = self.swipe, !self.isFirstResponder, touches == 1{
            self.layer.borderColor = UIColor.darkText.cgColor
            self.layer.borderWidth = 1
            if (pan.state == .ended || pan.state == .cancelled)
            {
                self.swipe = nil
                self.layer.borderColor = UIColor.darkText.cgColor
                self.layer.borderWidth = 0
                start = CGPoint.zero
                return
            }
            if (swipe)
            {
                self.moveBy(x: pan.translation(in: self).x - start.x, y: pan.translation(in: self).y - start.y)
            }
            else{
                let frame = self.frame
                self.bounds.size = CGSize(width: self.bounds.width + (pan.translation(in: self).x - start.x), height: self.bounds.height + (pan.translation(in: self).y - start.y))
                self.frame = CGRect(x: frame.minX, y: frame.minY, width: self.frame.width, height: self.frame.height)
            }
            start = pan.translation(in: self)
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let newEvent = event, let total = newEvent.allTouches{
            self.touches = total.count
        }
        if (touches.count > 1){return}
        start = CGPoint.zero
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
