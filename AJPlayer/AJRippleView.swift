//
//  AJRippleView.swift
//  AJPlayer
//
//  Created by DinDin on 2024/9/9.
//


import UIKit
import Lottie
import SnapKit

extension UIColor {
    
    static public func rgba(red: UInt8, green: UInt8, blue: UInt8, alpha: CGFloat) -> UIColor {
        return UIColor(red: CGFloat(Float(red) / 255.0), green: CGFloat(Float(green) / 255.0), blue: CGFloat(Float(blue) / 255.0), alpha:alpha)
    }
    
}

enum TVRippleType:NSInteger {
    case TVRipple_Left
    case TVRipple_Right
}

struct TVRippleViewConfig {
    var pageHeight = UIScreen.main.bounds.size.height
    var pageWeight  = UIScreen.main.bounds.size.width

    var animationDuration:CFTimeInterval = 0.5
    var tipWidth:CGFloat = 300
    var tiplHeight:CGFloat = 80

    var arrowBgViewWidth:CGFloat = 180
    var arrowBgViewHeight:CGFloat = 70
    
    var ArrowBG_LR_Margin:CGFloat = 5
    var Label_LR_Margin:CGFloat = 5
    var Arrow_LR_Margin:CGFloat = 5
    var Arrow_Center_Margin:CGFloat = 18
    var Arrow_Height:CGFloat = 40
    var Arrow_Width:CGFloat = 32

    
    var Circle_Center:CGPoint{
        return CGPoint(x: 0, y: self.pageHeight/2)//圆心位置(离position的间距,不代表方向)
    }
    var BG_Width:CGFloat {
        return self.pageHeight * 3
    }
    var BG_Height:CGFloat {
        return self.pageHeight * 3
    }
    var Bg_Radian:CGFloat {
        return self.pageHeight * 1.5
    }//大圆能看到的弧度宽
     var Bg_TB_Margin:CGFloat  {
        return (self.BG_Height - self.pageHeight)/2
    }//大圆能看到的弧度宽 (1400-1080)/2=160

    var Small_Circle_R:CGFloat{
        return (self.pageHeight * 0.5)
    }
    var Medium_Circle_R:CGFloat {
        return (self.pageHeight * 0.8 )
    }

    var Small_Circle_Opacity:Float = 0.2//Opacity
    var Mediun_Circle_Opacity:Float = 0.1//Opacity
    var Large_Circle_ColorAlpha:CGFloat = 0.0//ColorAlpha
}

class TVRippleView: UIView {

    

    private var isDismiss:Bool = false //动画未完成时需求想立马消失动画，避免还去执行一些不必要的操作
    var rippleType: TVRippleType = TVRippleType.TVRipple_Left//默认left
    private var tipLabel:UILabel!
    private var vMain: UIView!
    private var forwardView: LottieAnimationView!
    private var arrorBgView:UIView!
    var viewConfig: TVRippleViewConfig?

    typealias CompleteAnimation = ()->Void
    var completeAnimation:CompleteAnimation?
    
    //MARK: 展示上下视频切换动画
    static func showRipple(type:TVRippleType, viewConfig: TVRippleViewConfig? = nil, superview: UIView, atributeTipStr:NSMutableAttributedString, complete:@escaping CompleteAnimation) ->TVRippleView {
//        let window = UIApplication.shared.windows.last
        let rippleView = TVRippleView()
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()
        rippleView.viewConfig = rippleViewConfig
        //加个遮罩
//        rippleView.blueEffectView = TVRippleView.initMaskView(viewConfig: viewConfig)
//
//        superview.addSubview(rippleView.blueEffectView)

        if type == .TVRipple_Left {
            rippleView.frame = CGRect(x: -(rippleViewConfig.BG_Width-rippleViewConfig.Bg_Radian), y: -(rippleViewConfig.BG_Height-rippleViewConfig.pageHeight)/2, width: rippleViewConfig.BG_Width, height: rippleViewConfig.BG_Height)
        } else {
            rippleView.frame = CGRect(x: rippleViewConfig.pageWeight-rippleViewConfig.Bg_Radian, y: -(rippleViewConfig.BG_Height-rippleViewConfig.pageHeight)/2, width: rippleViewConfig.BG_Width, height: rippleViewConfig.BG_Height)
        }
        rippleView.layer.cornerRadius = rippleViewConfig.BG_Width/2
        superview.addSubview(rippleView)

        rippleView.completeAnimation = complete
        rippleView.rippleType = type
        rippleView.isDismiss = false

        rippleView.backgroundColor = UIColor.clear
        rippleView.clipsToBounds = true
        rippleView.layer.masksToBounds = true
        rippleView.initTipLabel(atributeStr: atributeTipStr, baseView: superview, type: type)
        rippleView.forwardView.play()

        rippleView.addRippleLayer(beginRect: rippleView.makeBeginRect(), endRect: rippleView.makeEndRect(), opacity: rippleViewConfig.Small_Circle_Opacity)
    
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleViewConfig.animationDuration * 0.9) {
            rippleView.tipLabel.removeFromSuperview()
            rippleView.forwardView.stop()
            rippleView.forwardView.removeFromSuperview()
            rippleView.vMain.removeFromSuperview()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + rippleViewConfig.animationDuration*1.2) {
            rippleView.dismiss(isAnimation: true)
        }
        
        return rippleView
    }
    
    //MARK: 初始化遮罩view
    static func initMaskView(viewConfig: TVRippleViewConfig? = nil ) -> UIView {
        let maskView = UIView()
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()
        
        maskView.frame = CGRect(x: 0, y: 0, width: rippleViewConfig.pageWeight, height: rippleViewConfig.pageHeight)
        maskView.backgroundColor = UIColor.clear
        maskView.alpha = 0.3
        return maskView
    }
    
    //MARK: 开始小圆的圆心位置以及半径
    func makeBeginRect() -> CGRect {
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()

        var beginRect =  CGRect(x: 0, y: 0, width: 0, height: 0)
        if rippleType == .TVRipple_Left {
            //左边
            //x的值是圆心x位置减去半径大小
            beginRect = CGRect(x: rippleViewConfig.Circle_Center.x - rippleViewConfig.Small_Circle_R, y: -rippleViewConfig.Small_Circle_R, width: rippleViewConfig.Small_Circle_R*2, height: rippleViewConfig.Small_Circle_R*2)//半径是100，圆心在坐标系统中的0,-100(相对position位置，把position那里看成是0，0位置)

        } else if rippleType == .TVRipple_Right {
            //右边
            //x的值是圆心x位置加上半径大小
            beginRect = CGRect(x:-(rippleViewConfig.Circle_Center.x + rippleViewConfig.Small_Circle_R), y: -rippleViewConfig.Small_Circle_R, width: rippleViewConfig.Small_Circle_R*2, height: rippleViewConfig.Small_Circle_R*2)//半径是100，圆心在坐标系统中的-200,-100(相对position位置，把position那里看成是0，0位置)
        }
        return beginRect
    }
    
    //MARK: 开始中圆的圆心位置以及半径
    func makeEndRect() -> CGRect {
        var endRect =  CGRect(x: 0, y: 0, width: 0, height: 0)
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()

        if rippleType == .TVRipple_Left {
            //左边
            //x的值是圆心x位置减去半径大小
            endRect = CGRect(x: rippleViewConfig.Circle_Center.x - rippleViewConfig.Medium_Circle_R, y: -rippleViewConfig.Medium_Circle_R, width: rippleViewConfig.Medium_Circle_R*2, height: rippleViewConfig.Medium_Circle_R*2)//(相对position位置，把position那里看成是0，0位置)

        } else if rippleType == .TVRipple_Right {
            //右边
            //x的值是圆心x位置加上半径大小
            endRect = CGRect(x:-(rippleViewConfig.Circle_Center.x + rippleViewConfig.Medium_Circle_R), y: -rippleViewConfig.Medium_Circle_R, width: rippleViewConfig.Medium_Circle_R*2, height: rippleViewConfig.Medium_Circle_R*2)//(相对position位置，把position那里看成是0，0位置)
        }
        return endRect
    }
    
    //MARK: 背景色透明度加个动画
    func doShowBgViewAnimation() {
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()

        if self.isDismiss {
            return
        }
        UIView.animate(withDuration: 0.35) {
            self.backgroundColor = UIColor.rgba(red: 255, green: 255, blue: 255, alpha: rippleViewConfig.Large_Circle_ColorAlpha)
        }
    }
    
    //MARK: tip文案
    private func initTipLabel(atributeStr:NSMutableAttributedString, baseView: UIView, type: TVRippleType) {
        if self.isDismiss {
            return
        }
        switch type {
        case .TVRipple_Left:
            self.forwardView = LottieAnimationView(name: "ani_rewind")
        case .TVRipple_Right:
            self.forwardView = LottieAnimationView(name: "ani_forward")
        }
        
        self.vMain = UIView()
        self.addSubview(vMain)
        self.vMain.addSubview(forwardView)
        
        let _tipLabl: UILabel = {
           let ll = UILabel()
            ll.backgroundColor = UIColor.clear
            ll.numberOfLines = 2
            ll.attributedText = atributeStr
            ll.textAlignment = .center
            return ll
        }()
        self.tipLabel = _tipLabl
        self.vMain.addSubview(tipLabel)
        self.vMain.snp.makeConstraints { (m) in
            m.centerX.centerY.equalTo(baseView)
            m.width.equalTo(48).multipliedBy(0.825)
            m.height.equalTo(vMain.snp.width)
        }
        self.forwardView.snp.makeConstraints { (m) in
            m.top.leading.trailing.equalToSuperview()
            m.height.equalTo(self.forwardView.snp.width).multipliedBy(0.5)
        }
        self.tipLabel.snp.makeConstraints { (m) in
            m.leading.trailing.equalToSuperview()
            m.top.equalTo(forwardView.snp.bottom)
        }
    }
    
    //MARK: 三角形view
    @objc func initArrorView() {
        if self.isDismiss {
            return
        }
        arrorBgView = UIView()
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()
        if rippleType == .TVRipple_Left {
            arrorBgView.frame = CGRect(x: self.frame.size.width - rippleViewConfig.Bg_Radian + rippleViewConfig.ArrowBG_LR_Margin, y: rippleViewConfig.Bg_TB_Margin+rippleViewConfig.pageHeight/2-50, width: rippleViewConfig.arrowBgViewWidth, height: rippleViewConfig.arrowBgViewHeight)
        } else if rippleType == .TVRipple_Right {
            arrorBgView.frame = CGRect(x: rippleViewConfig.Bg_Radian - rippleViewConfig.arrowBgViewWidth - rippleViewConfig.ArrowBG_LR_Margin, y: rippleViewConfig.Bg_TB_Margin+rippleViewConfig.pageHeight/2-50, width: rippleViewConfig.arrowBgViewWidth, height: rippleViewConfig.arrowBgViewHeight)
        }
        arrorBgView.backgroundColor = UIColor.clear
        self.addSubview(arrorBgView)
        
        //在arrorBgView画三角形
        addTriangle()
    }
    
    //MARK: 画三角形并且添加动画
    @objc func addTriangle() {
        if self.isDismiss {
            return
        }
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()

        //动画1，时间成等差数列
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleViewConfig.animationDuration*0.1) {
            if self.rippleType == .TVRipple_Right {
                let leftTopPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let leftBottmPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let rightPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: leftTopPoint, leftBottmPoint:leftBottmPoint, rightPoint: rightPoint)
            } else if self.rippleType == .TVRipple_Left {
                let rightTopPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let rightBottmPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let leftPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: rightTopPoint, leftBottmPoint:rightBottmPoint, rightPoint: leftPoint)
            }
        }
        
        //动画2
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleViewConfig.animationDuration*0.15) {
            if self.rippleType == .TVRipple_Right {
                let leftTopPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width + rippleViewConfig.Arrow_Center_Margin , y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let leftBottmPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width + rippleViewConfig.Arrow_Center_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let rightPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width * 2 + rippleViewConfig.Arrow_Center_Margin, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: leftTopPoint, leftBottmPoint:leftBottmPoint, rightPoint: rightPoint)
            } else if self.rippleType == .TVRipple_Left {
                let rightTopPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width - rippleViewConfig.Arrow_Center_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let rightBottmPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width - rippleViewConfig.Arrow_Center_Margin, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let leftPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width * 2 - rippleViewConfig.Arrow_Center_Margin, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: rightTopPoint, leftBottmPoint:rightBottmPoint, rightPoint: leftPoint)
            }
        }
        //动画3
        DispatchQueue.main.asyncAfter(deadline: .now() + rippleViewConfig.animationDuration*0.16) {
            if self.rippleType == .TVRipple_Right {
                let leftTopPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width * 2 + rippleViewConfig.Arrow_Center_Margin * 2 , y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let leftBottmPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width * 2 + rippleViewConfig.Arrow_Center_Margin * 2, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let rightPoint = CGPoint(x: rippleViewConfig.Arrow_LR_Margin + rippleViewConfig.Arrow_Width * 3 + rippleViewConfig.Arrow_Center_Margin * 2, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: leftTopPoint, leftBottmPoint:leftBottmPoint, rightPoint: rightPoint)
            } else if self.rippleType == .TVRipple_Left {
                let rightTopPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width * 2 - rippleViewConfig.Arrow_Center_Margin * 2, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2)
                let rightBottmPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width * 2 - rippleViewConfig.Arrow_Center_Margin * 2, y: (rippleViewConfig.arrowBgViewHeight - rippleViewConfig.Arrow_Height)/2 + rippleViewConfig.Arrow_Height)
                let leftPoint = CGPoint(x: rippleViewConfig.arrowBgViewWidth - rippleViewConfig.Arrow_LR_Margin - rippleViewConfig.Arrow_Width * 3 - rippleViewConfig.Arrow_Center_Margin * 2, y: rippleViewConfig.arrowBgViewHeight/2)
                self.addOpacityAnimation(leftTopPoint: rightTopPoint, leftBottmPoint:rightBottmPoint, rightPoint: leftPoint)
            }
        }
    }
     
    //MARK: 根据三个坐标画个三角形
    func addOpacityAnimation(leftTopPoint:CGPoint, leftBottmPoint:CGPoint, rightPoint:CGPoint) {
        if self.isDismiss {
            return
        }
        //layer
        let triangleLayer = CAShapeLayer()
        triangleLayer.strokeColor = UIColor.white.cgColor
        triangleLayer.lineWidth = 1.5
        triangleLayer.fillColor = UIColor.white.cgColor
        if self.arrorBgView != nil {
            self.arrorBgView.layer.addSublayer(triangleLayer)
        }
        //三角形1
        let trianglePath = UIBezierPath()
        trianglePath.move(to: leftTopPoint)
        trianglePath.addLine(to: leftBottmPoint)
        trianglePath.addLine(to: rightPoint)
        UIColor.magenta.setFill()
        trianglePath.fill()
        triangleLayer.path = trianglePath.cgPath
        triangleLayer.opacity = 0.0
        //动画
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = NSNumber(value: 0.8)
        opacityAnimation.toValue = NSNumber(value: 0.3)
        opacityAnimation.duration = 0.4
        triangleLayer.add(opacityAnimation, forKey: "aa")//key值无所谓，随便写
    }
    
    //MARK: 动画消失
    func dismiss(isAnimation:Bool) {
        self.isDismiss = true
        if self.superview != nil {
            if !isAnimation {
                removeAllView()
                return
            }
            //添加个消失的动画
            UIView.animate(withDuration: 0.1, animations: {
                if self.layer.sublayers != nil && (self.layer.sublayers?.count)! > 0 {
                    for layer in self.layer.sublayers! {
                        layer.opacity = 0.05
                    }
                }
            }, completion: { (flag) in
                if self.layer.sublayers != nil && (self.layer.sublayers?.count)! > 0 {
                    for layer in self.layer.sublayers! {
                        layer.opacity = 0.0
                    }
                }
                self.removeAllView()
            })
        }
    }
    
    //MARK: removeAllView
    private func removeAllView() {
        self.removeAllSubLayers()
//        if self.blueEffectView != nil {
//            self.blueEffectView.removeFromSuperview()
//        }
        self.removeFromSuperview()
        self.layer.removeAllAnimations()
        if self.completeAnimation != nil {
            self.completeAnimation!()
        }
    }
    
    //MARK: removeAllSubLayers
    private func removeAllSubLayers() {
        if self.layer.sublayers != nil && (self.layer.sublayers?.count)! > 0 {
            for layer in self.layer.sublayers! {
                layer.removeFromSuperlayer()
            }
        }
    }
    
    //MARK: 根据两个圆的位置和半径画圆，并且添加透明度变化的动画
    func addRippleLayer(beginRect:CGRect, endRect:CGRect,opacity:Float) {
        if self.isDismiss {
            return
        }
        let rippleLayer = CAShapeLayer()
        let rippleViewConfig: TVRippleViewConfig = viewConfig ?? TVRippleViewConfig.init()

        if rippleType == .TVRipple_Left {
            
            //160 = (self.frame.size.height - TVRippleView.UI_PAGE_HEIGHT)/2
            //972 = self.frame.size.width - TVRippleView.Bg_Radian
            rippleLayer.position = CGPoint(x: self.frame.size.width - rippleViewConfig.Bg_Radian, y: (self.frame.size.height - rippleViewConfig.pageHeight)/2 + rippleViewConfig.Circle_Center.y)//左边顶点，相对子layer的位置
        } else if rippleType == .TVRipple_Right {
            rippleLayer.position = CGPoint(x: rippleViewConfig.Bg_Radian, y: rippleViewConfig.Bg_TB_Margin + rippleViewConfig.Circle_Center.y)//右边顶点，相对子layer的位置
        }
        rippleLayer.strokeColor = UIColor.white.cgColor
        rippleLayer.lineWidth = 1.5
        rippleLayer.fillColor = UIColor.white.cgColor
        self.layer.addSublayer(rippleLayer)
        
        //把tiplabel放顶上
        if tipLabel != nil {
            self.bringSubviewToFront(tipLabel)
        }
        
        //addRippleAnimation
        let beginPath = UIBezierPath(ovalIn:beginRect)
        let endPath = UIBezierPath(ovalIn: endRect)
        rippleLayer.path = endPath.cgPath
        rippleLayer.opacity = opacity
        
        let rippleAnimation = CABasicAnimation(keyPath: "path")
        rippleAnimation.fromValue = beginPath.cgPath
        rippleAnimation.toValue = endPath.cgPath
        rippleAnimation.duration = rippleViewConfig.animationDuration
        rippleLayer.add(rippleAnimation, forKey: "")
    }
}

