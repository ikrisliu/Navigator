//
//  ScaleTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import Foundation

@objc public class ScaleTransition: Transition {
    
    public override func animateNavigationTransition(from fromVC: UIViewController, to toVC: UIViewController) {
        animatePresentingTransition(from: fromVC, to: toVC)
    }
    
    public override func animatePresentingTransition(from fromVC: UIViewController, to toVC: UIViewController) {
        let containerView = transitionContext.containerView
        let fromView = fromVC.view!
        let toView = toVC.view!

        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: CAMediaTimingFunctionName.default))
        
        if isShow {
            containerView.addSubview(toView)
            var scaleTransform = CATransform3DMakeScale(0.9, 0.9, 1)
            scaleTransform.m34 = 1.0 / -500.0
            toView.layer.transform = isVertical ? CATransform3DMakeTranslation(0, toView.bounds.height, 0) : CATransform3DMakeTranslation(toView.bounds.width, 0, 0)
            UIView.animate(withDuration: animationDuration, animations: {
                toView.layer.transform = CATransform3DIdentity
                fromView.alpha = 0.7
                fromView.layer.transform = scaleTransform
            }, completion: { _ in
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)

            fromView.layer.shadowColor = UIColor.black.cgColor
            fromView.layer.shadowOpacity = 0.4
            fromView.layer.shadowOffset = isVertical ? CGSize(width: 0, height: -3) : CGSize(width: -3, height: 0)
            fromView.layer.shadowRadius = 5.0
            
            UIView.animate(withDuration: animationDuration, animations: {
                toView.alpha = 1
                toView.layer.transform = CATransform3DIdentity
                fromView.layer.transform = self.isVertical ? CATransform3DMakeTranslation(0, fromView.bounds.height, 0) : CATransform3DMakeTranslation(fromView.bounds.width, 0, 0)
            }, completion: { _ in
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        }
    }
}
