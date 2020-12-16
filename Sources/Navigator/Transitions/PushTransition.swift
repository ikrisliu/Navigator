//
//  PushTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2019/11/21.
//  Copyright © 2021 Syzygy. All rights reserved.
//

import UIKit

@objc public class PushTransition: Transition {
    
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
        let fromTransView = transitionView(in: fromView) ?? fromView
        let toTransView = transitionView(in: toView) ?? toView
        let fromNavBar = navigationBar(in: fromView)
        let toNavBar = navigationBar(in: toView)
        
        dimmedBackgroundView.frame = containerView.frame
        
        if isShow {
            if let toView = toView {
                containerView.addSubview(dimmedBackgroundView)
                containerView.addSubview(toView)
                
                self.setNavigationBarAlpha(navBar: toNavBar, alpha: 0.0)
                toTransView?.transform = CGAffineTransform(translationX: toView.bounds.width, y: 0)
            }
            
            let translationX = fromView != nil ? -fromView!.bounds.width / 3 : 0
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                
                fromTransView?.transform = CGAffineTransform(translationX: translationX, y: 0)
                
                self.setNavigationBarAlpha(navBar: toNavBar, alpha: 1.0)
                toTransView?.transform = .identity
            }, completion: { _ in
                fromTransView?.transform = .identity
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
            toTransView?.transform = CGAffineTransform(translationX: translationX, y: 0)
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                
                self.setNavigationBarAlpha(navBar: fromNavBar, alpha: 0.0)
                fromTransView?.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
                
                toTransView?.transform = .identity
            }, completion: { _ in
                self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
            })
        }
    }
    
    private func transitionView(in view: UIView?) -> UIView? {
        if let clazz = NSClassFromString("UINavigationTransitionView") {
            return subview(clazz: clazz, in: view)
        } else {
            return view
        }
    }
    
    private func navigationBar(in view: UIView?) -> UINavigationBar? {
        subview(clazz: UINavigationBar.self, in: view) as? UINavigationBar
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
    
    private func setNavigationBarAlpha(navBar: UINavigationBar?, alpha: CGFloat) {
        navBar?.subviews.forEach({ $0.alpha = alpha })
    }
}
