//
//  WCLAngleLayer.swift
//  WCLShineButton
//
// **************************************************
// *                                  _____         *
// *         __  _  __     ___        \   /         *
// *         \ \/ \/ /    / __\       /  /          *
// *          \  _  /    | (__       /  /           *
// *           \/ \/      \___/     /  /__          *
// *                               /_____/          *
// *                                                *
// **************************************************
//  Github  :https://github.com/imwcl
//  HomePage:https://imwcl.com
//  CSDN    :http://blog.csdn.net/wang631106979
//
//  Created by 王崇磊 on 16/9/14.
//  Copyright © 2016年 王崇磊. All rights reserved.
//
// @class WCLAngleLayer
// @abstract 旋转的layer
// @discussion 旋转的layer
//

import UIKit

class WCLShineAngleLayer: CALayer, CAAnimationDelegate {
    
    var params: WCLShineParams = WCLShineParams()
    
    var shineLayers: [CAShapeLayer] = [CAShapeLayer]()//存储扩散粒子的图层(较大的粒子)
    
    var smallShineLayers: [CAShapeLayer] = [CAShapeLayer]()//存储扩散粒子的图层(较小的粒子)
    
    var displaylink: CADisplayLink?
    
    //MARK: Initial Methods
    init(frame: CGRect, params: WCLShineParams) {
        super.init()
        self.frame = frame
        self.params = params
        addShines()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Public Methods
    public func startAnim() {
        let radius = frame.size.width/2 * CGFloat(params.shineDistanceMultiple*2)
        var startAngle: CGFloat = 0
        let angle = CGFloat(Double.pi*2/Double(params.shineCount))//粒子之间的夹角
        if params.shineCount%2 != 0 {//当粒子总数是奇数的时候
            startAngle = CGFloat(Double.pi*2 - (Double(angle)/Double(params.shineCount)))
        }
        for i in 0..<params.shineCount {
            //粒子移动到更远的圆心点 而且半径变成0.1
            let bigShine = shineLayers[i]
            let bigAnim = getAngleAnim(shine: bigShine, angle: startAngle + CGFloat(angle)*CGFloat(i), radius: radius)
            let smallShine = smallShineLayers[i]
            var radiusSub = frame.size.width*0.15*0.66
            if params.shineSize != 0 {
                radiusSub = params.shineSize*0.66
            }
            let smallAnim = getAngleAnim(shine: smallShine, angle: startAngle + CGFloat(angle)*CGFloat(i) - CGFloat(params.smallShineOffsetAngle)*CGFloat(Double.pi)/180, radius: radius-radiusSub)
            bigShine.add(bigAnim, forKey: "path")
            smallShine.add(smallAnim, forKey: "path")
            if params.enableFlashing {
                let bigFlash = getFlashAnim()
                let smallFlash = getFlashAnim()
                bigShine.add(bigFlash, forKey: "bigFlash")
                smallShine.add(smallFlash, forKey: "smallFlash")
            }
            
        }
        //整体旋转20度
        let angleAnim = CABasicAnimation(keyPath: "transform.rotation")
        angleAnim.duration = params.animDuration * 0.87
        angleAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        angleAnim.fromValue = 0
        angleAnim.toValue = CGFloat(params.shineTurnAngle)*CGFloat(Double.pi)/180
        angleAnim.delegate = self
        add(angleAnim, forKey: "rotate")
        if params.enableFlashing {
            startFlash()
        }
    }
    
    //MARK: Privater Methods
    private func startFlash() {
        displaylink = CADisplayLink(target: self, selector: #selector(flashAction))
        if #available(iOS 10.0, *) {
            displaylink?.preferredFramesPerSecond = 10
        }else {
            displaylink?.frameInterval = 6
        }
        displaylink?.add(to: .current, forMode: .commonModes)
    }
    
    private func addShines() {
        var startAngle: CGFloat = 0
        let angle = CGFloat(Double.pi*2/Double(params.shineCount)) + startAngle
        if params.shineCount%2 != 0 {
            startAngle = CGFloat(Double.pi*2 - (Double(angle)/Double(params.shineCount)))
        }
        let radius = frame.size.width/2 * CGFloat(params.shineDistanceMultiple)
        for i in 0..<params.shineCount {
            //绘制扩散粒子的形态
            let bigShine = CAShapeLayer()
            var bigWidth = frame.size.width*0.15
            if params.shineSize != 0 {
                bigWidth = params.shineSize
            }
            let center = getShineCenter(angle: startAngle + CGFloat(angle)*CGFloat(i), radius: radius)
            let path = UIBezierPath(arcCenter: center, radius: bigWidth, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: false)
            bigShine.path = path.cgPath
            if params.allowRandomColor {
                bigShine.fillColor = params.colorRandom[Int(arc4random())%params.colorRandom.count].cgColor
            }else{
                bigShine.fillColor = params.bigShineColor.cgColor
            }
            addSublayer(bigShine)
            shineLayers.append(bigShine)
            
            let smallShine = CAShapeLayer()
            let smallWidth = bigWidth*0.66
            let smallCenter = getShineCenter(angle: startAngle + CGFloat(angle)*CGFloat(i) - CGFloat(params.smallShineOffsetAngle)*CGFloat(Double.pi)/180, radius: radius-bigWidth)
            let smallPath = UIBezierPath(arcCenter: smallCenter, radius: smallWidth, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: false)
            smallShine.path = smallPath.cgPath
            if params.allowRandomColor {
                smallShine.fillColor = params.colorRandom[Int(arc4random())%params.colorRandom.count].cgColor
            }else {
                smallShine.fillColor = params.smallShineColor.cgColor
            }
            addSublayer(smallShine)
            smallShineLayers.append(smallShine)
        }
    }
    //获取粒子的动画（重新绘制粒子，圆心在比原来圆心更远的在圆环半径的方向上，半径变成0.1）
    private func getAngleAnim(shine: CAShapeLayer, angle: CGFloat, radius: CGFloat) -> CABasicAnimation {
        let anim = CABasicAnimation(keyPath: "path")
        anim.duration = params.animDuration * 0.87
        anim.fromValue = shine.path
        let center = getShineCenter(angle: angle, radius: radius)
        let path = UIBezierPath(arcCenter: center, radius: 0.1, startAngle: 0, endAngle: CGFloat(Double.pi)*2, clockwise: false)
        anim.toValue = path.cgPath//layer层属性的改变和animation.path动画路径不同
        anim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        anim.isRemovedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        return anim
    }
    //闪烁动画 （随机改变视图透明度）
    private func getFlashAnim() -> CABasicAnimation {
        let flash = CABasicAnimation(keyPath: "opacity")
        flash.fromValue = 1
        flash.toValue = 0
        let duration = Double(arc4random()%20+60)/1000
        flash.duration = duration
        flash.repeatCount = MAXFLOAT
        flash.isRemovedOnCompletion = false
        flash.autoreverses = true
        flash.fillMode = kCAFillModeForwards
        return flash
    }
    //获取4个象限中的粒子的中心点
    private func getShineCenter(angle: CGFloat, radius: CGFloat) -> CGPoint {
        //整个layer层的bounds
        let cenx = bounds.midX
        let ceny = bounds.midY
        var multiple: Int = 0 //象限（笛卡尔坐标系）
        if (angle >= 0 && angle <= CGFloat(90 * Double.pi/180)) {
            multiple = 1
        }else if (angle <= CGFloat(Double.pi) && angle > CGFloat(90 * Double.pi/180)) {
            multiple = 2
        }else if (angle > CGFloat(Double.pi) && angle <= CGFloat(270 * Double.pi/180)) {
            multiple = 3
        }else {
            multiple = 4
        }
        //将四个象限里面的角度换算成锐角
        let resultAngel = CGFloat(multiple)*CGFloat(90 * Double.pi/180) - angle
        let a = sin(resultAngel)*radius//粒子与圆环切点在坐标系里面的Y轴方向上的距离
        let b = cos(resultAngel)*radius//粒子与圆环切点在坐标系里面的X轴方向上的距离
        //粒子的中心点 （位于圆环外层，粒子与圆环相切）
        if (multiple == 1) {
            return CGPoint.init(x: cenx+b, y: ceny-a)
        }else if (multiple == 2) {
            return CGPoint.init(x: cenx+a, y: ceny+b)
        }else if (multiple == 3) {
            return CGPoint.init(x: cenx-b, y: ceny+a)
        }else {
            return CGPoint.init(x: cenx-a, y: ceny-b)
        }
    }
    //填充颜色随机
    @objc private func flashAction() {
        for i in 0..<params.shineCount {
            let bigShine = shineLayers[i]
            let smallShine = smallShineLayers[i]
            bigShine.fillColor = params.colorRandom[Int(arc4random())%params.colorRandom.count].cgColor
            smallShine.fillColor = params.colorRandom[Int(arc4random())%params.colorRandom.count].cgColor
        }
    }
    
    //MARK: CAAnimationDelegate
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            displaylink?.invalidate()
            displaylink = nil
            removeAllAnimations()
            removeFromSuperlayer()
        }
    }
}
