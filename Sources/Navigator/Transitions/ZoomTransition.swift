//
//  ZoomTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

@objc public class ZoomTransition: Transition {
    
    private lazy var dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
        return view
    }()
    
    public required init() {
        super.init()
        interactiveGestureEdges = [.top, .bottom]
        orientation = .vertical
    }
    
    public override func animateNavigationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        animatePresentationTransition(isShow: isShow, from: fromView, to: toView, completion: completion)
    }
    
    public override func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        let containerView = transitionContext?.containerView
        dimmedBackgroundView.frame = containerView?.frame ?? .zero
        
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeOut))
        
        var scaleTransform = CATransform3DMakeScale(0.9, 0.9, 1)
        scaleTransform.m34 = 1.0 / -500.0
        
        if isShow {
            if let toView = toView {
                containerView?.addSubview(dimmedBackgroundView)
                containerView?.addSubview(toView)
                toView.layer.transform = isVertical ? CATransform3DMakeTranslation(0, toView.bounds.height, 0) : CATransform3DMakeTranslation(toView.bounds.width, 0, 0)
            }
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                toView?.layer.transform = CATransform3DIdentity
                fromView?.layer.transform = scaleTransform
            }, completion: { _ in
                fromView?.layer.transform = CATransform3DIdentity
                self.completeTransition(completion: completion)
            })
        } else {
            if let toView = toView, let fromView = fromView {
                containerView?.insertSubview(toView, belowSubview: fromView)
                containerView?.insertSubview(dimmedBackgroundView, aboveSubview: toView)
            }
            
            guard let fromView = fromView else {
                self.completeTransition(completion: completion)
                return
            }
            
            toView?.layer.transform = scaleTransform
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                toView?.layer.transform = CATransform3DIdentity
                fromView.layer.transform = self.isVertical ? CATransform3DMakeTranslation(0, fromView.bounds.height, 0) : CATransform3DMakeTranslation(fromView.bounds.width, 0, 0)
            }, completion: { _ in
                self.completeTransition(completion: completion)
            })
        }
    }
}
