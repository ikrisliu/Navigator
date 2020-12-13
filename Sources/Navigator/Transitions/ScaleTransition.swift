//
//  ScaleTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit

@objc public class ScaleTransition: Transition {
    
    private lazy var dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
        return view
    }()
    
    public required init() {
        super.init()
        interactiveGestureEnabled = true
        orientation = .vertical
    }
    
    public override func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) {
        animatePresentingTransition(from: fromView, to: toView)
    }
    
    public override func animatePresentingTransition(from fromView: UIView?, to toView: UIView?) {
        let containerView = transitionContext.containerView
        dimmedBackgroundView.frame = containerView.frame
        
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        
        var scaleTransform = CATransform3DMakeScale(0.9, 0.9, 1)
        scaleTransform.m34 = 1.0 / -500.0
        
        if isShow {
            if let toView = toView {
                containerView.addSubview(dimmedBackgroundView)
                containerView.addSubview(toView)
                toView.layer.transform = isVertical ? CATransform3DMakeTranslation(0, toView.bounds.height, 0) : CATransform3DMakeTranslation(toView.bounds.width, 0, 0)
            }
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                toView?.layer.transform = CATransform3DIdentity
                fromView?.layer.transform = scaleTransform
            }, completion: { _ in
                fromView?.layer.transform = CATransform3DIdentity
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        } else {
            if let toView = toView, let fromView = fromView {
                containerView.insertSubview(toView, belowSubview: fromView)
                containerView.insertSubview(dimmedBackgroundView, aboveSubview: toView)
            }
            
            guard let fromView = fromView else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }
            
            toView?.layer.transform = scaleTransform
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                toView?.layer.transform = CATransform3DIdentity
                fromView.layer.transform = self.isVertical ? CATransform3DMakeTranslation(0, fromView.bounds.height, 0) : CATransform3DMakeTranslation(fromView.bounds.width, 0, 0)
            }, completion: { _ in
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        }
    }
}
