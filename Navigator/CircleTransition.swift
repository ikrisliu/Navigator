//
//  CircleTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import Foundation

@objc public class CircleTransition : Transition {
    
    public override func animateNavigationTransition(from fromVC: UIViewController, to toVC: UIViewController) {
        animatePresentingTransition(from: fromVC, to: toVC)
    }
    
    public override func animatePresentingTransition(from fromVC: UIViewController, to toVC: UIViewController) {
        let containerView = transitionContext.containerView
        let fromView = fromVC.view!
        let toView = toVC.view!
        
        let point = containerView.center
        let radius = CGFloat(sqrtf(powf(Float(point.x), 2) + powf(Float(point.y), 2)))
        let startPath = UIBezierPath(arcCenter: containerView.center, radius: 0.01, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        let endPath = UIBezierPath(arcCenter: containerView.center, radius: radius, startAngle: 0, endAngle: 2*CGFloat.pi, clockwise: true).cgPath
        let maskLayer = CAShapeLayer(layer: startPath)
        
        let circleAnimation = CABasicAnimation(keyPath: "path")
        circleAnimation.duration = animationDuration
        // Avoid screen flash
        circleAnimation.isRemovedOnCompletion = false
        circleAnimation.fillMode = kCAFillModeBoth
        
        if isShow {
            containerView.addSubview(toView)
            toView.layer.mask = maskLayer
            circleAnimation.fromValue = startPath
            circleAnimation.toValue = endPath
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)
            fromView.layer.mask = maskLayer
            circleAnimation.fromValue = endPath
            circleAnimation.toValue = startPath
        }
        maskLayer.add(circleAnimation, forKey: "cirleAnimation")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration) {
            fromView.layer.mask = nil
            toView.layer.mask = nil
            self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
        }
    }
}
