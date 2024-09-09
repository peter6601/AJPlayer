//
//  AJPlayerGestureView.swift
//  AJPlayer
//
//  Created by DinDin on 2024/8/23.
//

import UIKit

public struct AJPlayerGestureOptions: OptionSet {
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    static public let panVertical = AJPlayerGestureOptions(rawValue: 1 << 0)
    static public let panHorizontal = AJPlayerGestureOptions(rawValue: 1 << 1)
    static public let singleTap = AJPlayerGestureOptions(rawValue: 1 << 2)
    static public let doubleTap = AJPlayerGestureOptions(rawValue: 1 << 3)
}

public enum AJPanDirection {
    case horizontal
    case vertical
}

public protocol AJPlayerGestureViewDelegate: AnyObject {
    func gestureView(_ gestureView: AJPlayerGestureView, doubleTapWith gesture: UITapGestureRecognizer)
    func gestureView(_ gestureView: AJPlayerGestureView, singleTapWith gesture: UITapGestureRecognizer)
    func gestureView(_ gestureView: AJPlayerGestureView, state: UIGestureRecognizer.State, velocityPoint: CGPoint)
}

open class AJPlayerGestureView: UIView {
    
    open var vFastforword: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    
    
    open var vFastBackWord: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()
    open var panStartLocation: CGPoint = .zero
    open var panDirection: AJPanDirection = .horizontal
    private var panGesture: UIPanGestureRecognizer?
    private var singleTapGesture: UITapGestureRecognizer?
    private var doubleTapGesture: UITapGestureRecognizer?
    private var verticalPanIsDisable: Bool = false
    private var horizontalPanIsDisable: Bool = false
    open weak var delegate: AJPlayerGestureViewDelegate?
    
    open func disableGestures(_ gestures: AJPlayerGestureOptions) {
        let all: AJPlayerGestureOptions = [.panVertical,.panHorizontal,.singleTap,.doubleTap]
        
        if gestures.contains(all) {
            verticalPanIsDisable = true
            horizontalPanIsDisable = true
            panGesture?.isEnabled = false
            singleTapGesture?.isEnabled = false
            doubleTapGesture?.isEnabled = false
        }
        if gestures.contains(.panVertical) {
            verticalPanIsDisable = true
        }
        if gestures.contains(.panHorizontal) {
            horizontalPanIsDisable = true
        }
        let pangestrue: AJPlayerGestureOptions = [.panVertical,.panHorizontal]
        if gestures.contains(pangestrue) {
            panGesture?.isEnabled = false
        }
        if gestures.contains(.singleTap) {
            singleTapGesture?.isEnabled = false
        }
        if gestures.contains(.doubleTap){
            doubleTapGesture?.isEnabled = false
        }
    }
    open func enableGesture(_ gestures: AJPlayerGestureOptions) {
        if gestures.contains(.panVertical) {
            verticalPanIsDisable = false
            panGesture?.isEnabled = true
        }
        if gestures.contains(.panHorizontal) {
            horizontalPanIsDisable = false
            panGesture?.isEnabled = true
        }
        if gestures.contains(.singleTap) {
            singleTapGesture?.isEnabled = true
        }
        if gestures.contains(.doubleTap){
            doubleTapGesture?.isEnabled = true
        }
    }
    private func addGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
        addGestureRecognizer(panGesture)
        self.panGesture = panGesture
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        singleTapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(singleTapGesture)
        self.singleTapGesture = singleTapGesture
        
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        self.doubleTapGesture = doubleTapGesture
        singleTapGesture.require(toFail: doubleTapGesture)
    }
    
    @objc private func tap(_ gesture: UITapGestureRecognizer) {
        switch gesture.numberOfTapsRequired {
        case 1: delegate?.gestureView(self, singleTapWith: gesture)
        case 2: delegate?.gestureView(self, doubleTapWith: gesture)
        default: break
        }
    }
    
    @objc private func pan(_ gesture: UIPanGestureRecognizer) {
        let locationPoint = gesture.location(in: self)
        let velocityPoint = gesture.velocity(in: self)
        switch gesture.state {
        case .began:
            let horizontalValue = abs(velocityPoint.x)
            let verticalValue = abs(velocityPoint.y)
            panDirection = horizontalValue > verticalValue ? .horizontal: .vertical
            panStartLocation = locationPoint
        default:
           break
        }
        switch panDirection {
        case .vertical:
            if verticalPanIsDisable { return }
        case .horizontal:
            if horizontalPanIsDisable { return }
        }
        delegate?.gestureView(self, state: gesture.state, velocityPoint: velocityPoint)
    }
    
    public init() {
        super.init(frame: .zero)
        addGestures()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    @objc private func tapbtnFastBackword(completion: @escaping (Bool) -> Void) {
        leftIsStartCount += 1
        if leftIsStartCount > 1 {
            leftTempAdd += 1
        }
        let fastforwardSec: Int = VideoConfig.fastForwardSec
        let sec = String(leftTempAdd * fastforwardSec)
        let atrbuteStr = getatrbuteString(title: "\(sec)秒")
        var rippleViewConfig = TVRippleViewConfig()
        rippleViewConfig.UI_PAGE_HEIGHT = self.vFastBackWord.frame.height
        rippleViewConfig.UI_PAGE_WIDTH =  self.vFastBackWord.frame.width
        _ = TVRippleView.showRipple(type: .TVRipple_Left, viewConfig: rippleViewConfig, superview: self.vFastBackWord, atributeTipStr:atrbuteStr) {
            self.leftIsStartCount -= 1
            if self.leftIsStartCount == 0 {
                self.leftTempAdd = 1
            }
        }
        customPlayViewDelegate?.tappedBackword()
    }
    
    private func getatrbuteString(title: String, color: UIColor = .white, font: UIFont = UIFont.systemFont(ofSize: 12) ) -> NSMutableAttributedString {
        let atrbuteStr = NSMutableAttributedString(string: title)
        atrbuteStr.addAttribute(NSAttributedString.Key.font, value:font , range: NSMakeRange(0, atrbuteStr.length))
        atrbuteStr.addAttribute(NSAttributedString.Key.foregroundColor, value: color, range: NSRange.init(location: 0, length: atrbuteStr.length))
        return atrbuteStr
    }
    
}

class PanCounter {
    enum Direction {
        case left
        case right
    }
    private(set) var leftTempAdd: Int = 1
    private(set) var rightTempAdd: Int = 1
    private(set) var leftIsStartCount: Int = 0
    private(set) var rightIsStartCount: Int = 0
    
    func add(by direct: Direction) {
        switch direct {
        case .right:
            rightIsStartCount += 1
        case .left:
            leftIsStartCount += 1
        }
    }
    func mins(by direct: Direction) {
        switch direct {
        case .right:
            rightIsStartCount -= 1
        case .left:
            leftIsStartCount -= 1
        }
    }
    func check(by direct: Direction) {
        switch direct {
        case .right:
        self.rightTempAdd += rightIsStartCount > 1 ? 1 : 0
        case .left:
            leftTempAdd += leftIsStartCount > 1 ? 1 : 0
        }
    }
}
