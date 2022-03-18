//
//  CircleTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

@objc public class CircleTransition: Transition {
    
    public override func animateNavigationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        animatePresentationTransition(isShow: isShow, from: fromView, to: toView, completion: completion)
    }
    
    public override func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        let containerView = transitionContext?.containerView
        
        guard let point = (containerView ?? fromView ?? toView)?.center else { return }
        
        let radius = CGFloat(sqrtf(powf(Float(point.x), 2) + powf(Float(point.y), 2)))
        let startPath = UIBezierPath(arcCenter: point, radius: 0.01, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        let endPath = UIBezierPath(arcCenter: point, radius: radius, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        let maskLayer = CAShapeLayer(layer: startPath)
        
        let circleAnimation = CABasicAnimation(keyPath: "path")
        circleAnimation.duration = animationDuration
        // Avoid screen flash
        circleAnimation.isRemovedOnCompletion = false
        circleAnimation.fillMode = CAMediaTimingFillMode.both
        
        if isShow {
            if let toView = toView {
                containerView?.addSubview(toView)
                toView.layer.mask = maskLayer
            }
            circleAnimation.fromValue = startPath
            circleAnimation.toValue = endPath
        } else {
            // For custom presentation style, toView is nil.
            if let fromView = fromView, let toView = toView {
                containerView?.insertSubview(toView, belowSubview: fromView)
            }
            fromView?.layer.mask = maskLayer
            circleAnimation.fromValue = endPath
            circleAnimation.toValue = startPath
        }
        maskLayer.add(circleAnimation, forKey: "cirleAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            fromView?.layer.mask = nil
            toView?.layer.mask = nil
            self.completeTransition(completion: completion)
        }
    }
}
