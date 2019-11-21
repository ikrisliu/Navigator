//
//  PushTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2019/11/21.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import UIKit

public class PushTransition: Transition {
    
    private lazy var dimmedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.0
        return view
    }()
    
    public required init() {
        super.init()
        interactiveGestureEnabled = true
        orientation = .horizontal
    }
    
    public override func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) {
        animatePresentingTransition(from: fromView, to: toView)
    }
    
    public override func animatePresentingTransition(from fromView: UIView?, to toView: UIView?) {
        let containerView = transitionContext.containerView
        dimmedBackgroundView.frame = containerView.frame
        
        if isShow {
            if let toView = toView {
                containerView.addSubview(dimmedBackgroundView)
                containerView.addSubview(toView)
                toView.transform = CGAffineTransform(translationX: toView.bounds.width, y: 0)
            }
            
            let translationX = fromView != nil ? -fromView!.bounds.width / 3 : 0
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                toView?.transform = .identity
                fromView?.transform = CGAffineTransform(translationX: translationX, y: 0)
            }, completion: { _ in
                fromView?.transform = .identity
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
            
            let translationX = toView != nil ? -toView!.bounds.width / 3 : 0
            
            toView?.transform = CGAffineTransform(translationX: translationX, y: 0)
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                toView?.transform = .identity
                fromView.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
            }, completion: { _ in
                toView?.transform = .identity
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        }
    }
}
