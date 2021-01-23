//
//  ParallaxTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2020/12/16.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

@objc public class ParallaxTransition: Transition {
    
    public required init() {
        super.init()
        interactiveGestureEdges = [.left, .right]
        orientation = .horizontal
    }
    
    public override func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) {
        animatePresentingTransition(from: fromView, to: toView)
    }
    
    public override func animatePresentingTransition(from fromView: UIView?, to toView: UIView?) {
        let containerView = transitionContext.containerView
        let fromLayoutContainerView = layoutContainerView(in: fromView)
        
        if isShow {
            if let toView = toView {
                containerView.insertSubview(toView, belowSubview: fromView!)
                toView.transform = CGAffineTransform(translationX: toView.bounds.width / 3, y: 0)
            }
            
            let translationX = fromView != nil ? -fromView!.bounds.width : 0
            
            UIView.animate(withDuration: animationDuration, animations: {
                fromView?.transform = CGAffineTransform(translationX: translationX, y: 0)
                fromLayoutContainerView?.subviews.forEach({
                    $0.transform = CGAffineTransform(translationX: -translationX / 3, y: 0)
                })
                toView?.transform = .identity
            }, completion: { _ in
                fromView?.transform = .identity
                fromLayoutContainerView?.subviews.forEach({ $0.transform = .identity })
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        } else {
            if let toView = toView, let fromView = fromView {
                containerView.insertSubview(toView, belowSubview: fromView)
            }
            
            guard let fromView = fromView else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                return
            }
            
            let translationX = toView != nil ? -toView!.bounds.width / 3 : 0
            toView?.transform = CGAffineTransform(translationX: translationX, y: 0)
            
            UIView.animate(withDuration: animationDuration, animations: {
                fromView.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
                fromLayoutContainerView?.subviews.forEach({
                    $0.transform = CGAffineTransform(translationX: -fromView.bounds.width / 3, y: 0)
                })
                toView?.transform = .identity
            }, completion: { _ in
                toView?.transform = .identity
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        }
    }
    
    private func layoutContainerView(in view: UIView?) -> UIView? {
        if let clazz = NSClassFromString("UILayoutContainerView") {
            return view?.isKind(of: clazz) == true ? view : subview(clazz: clazz, in: view)
        } else {
            return view
        }
    }
    
    private func subview(clazz: AnyClass, in view: UIView?) -> UIView? {
        if let subview = view?.subviews.first(where: { $0.isKind(of: clazz) }) {
            return subview
        } else {
            for subview in view?.subviews ?? [] {
                if let result = self.subview(clazz: clazz, in: subview) {
                    return result
                }
            }
            return nil
        }
    }
}
