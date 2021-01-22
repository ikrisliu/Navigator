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
        interactiveGestureEdges = [.left, .right]
        orientation = .horizontal
    }
    
    public override func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) {
        animatePresentingTransition(from: fromView, to: toView)
    }
    
    public override func animatePresentingTransition(from fromView: UIView?, to toView: UIView?) {
        let containerView = transitionContext.containerView
        let fromTransView = transitionView(in: fromView) ?? fromView
        let fromNavBar = navigationBar(in: fromView)
        let fromTitleView = titleView(in: fromNavBar)
        let toTransView = transitionView(in: toView) ?? toView
        let toNavBar = navigationBar(in: toView)
        let toTitleView = titleView(in: toNavBar)
        
        dimmedBackgroundView.frame = containerView.frame
        
        if isShow {
            if let toView = toView {
                containerView.addSubview(dimmedBackgroundView)
                containerView.addSubview(toView)
                
                self.hideNavigationBar(toNavBar)
                toTransView?.transform = CGAffineTransform(translationX: toView.bounds.width, y: 0)
            }
            
            let translationX = fromView != nil ? -fromView!.bounds.width / 3 : 0

            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                
                fromTransView?.transform = CGAffineTransform(translationX: translationX, y: 0)
                fromTitleView?.transform = CGAffineTransform(translationX: -(fromTitleView?.bounds.width ?? 0), y: 0)
                
                self.showNavigationBar(toNavBar)
                toTransView?.transform = .identity
            }, completion: { _ in
                fromTransView?.transform = .identity
                fromTitleView?.transform = .identity
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
            toTitleView?.transform = CGAffineTransform(translationX: -(toTitleView?.bounds.width ?? 0), y: 0)
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                
                if toNavBar?.isTranslucent == false {
                    self.hideNavigationBar(fromNavBar)
                    fromTransView?.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
                } else {
                    fromView.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
                }
                
                toTransView?.transform = .identity
                toTitleView?.transform = .identity
            }, completion: { _ in
                toTransView?.transform = .identity
                toTitleView?.transform = .identity
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
    
    private func titleView(in navBar: UINavigationBar?) -> UIView? {
        navBar?.topItem?.titleView ?? navBar?.subviews.compactMap({
            subview(clazz: UILabel.self, in: $0)
        }).last
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
    
    private func showNavigationBar(_ navBar: UINavigationBar?) {
        navBar?.subviews.forEach({ $0.alpha = 1.0 })
        if let titleView = self.titleView(in: navBar) {
            titleView.transform = .identity
        }
    }
    
    private func hideNavigationBar(_ navBar: UINavigationBar?) {
        navBar?.subviews.forEach({ $0.alpha = 0.0 })
        if let titleView = self.titleView(in: navBar), let navBar = navBar {
            titleView.transform = CGAffineTransform(translationX: navBar.bounds.width / 2, y: 0)
        }
    }
}
