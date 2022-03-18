//
//  PushTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2019/11/21.
//  Copyright © 2021 Syzygy. All rights reserved.
//

import UIKit

@objc public class PushTransition: Transition {
    
    private let titleViewMoveFactor: CGFloat = 1.0
    private let titleViewMoveFastFactor: CGFloat = 1.5
    
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
    
    public override func animateNavigationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        animatePresentationTransition(isShow: isShow, from: fromView, to: toView, completion: completion)
    }
    
    public override func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        guard let transitionContext = transitionContext else { return }
        
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        
        var newFromView = fromView ?? fromVC?.view  // Make sure transition view not nil and can do animation
        var newToView = toView ?? toVC?.view        // The same as above
        
        // In order to keep previous view stay when do the transition if previous view controller has custom presentation controller
        newFromView = fromVC?.presentationController?.isKind(of: PopoverPresentationController.self) == true ? nil : newFromView
        newToView = toVC?.presentationController?.isKind(of: PopoverPresentationController.self) == true ? nil : newToView
        
        let containerView = transitionContext.containerView
        let fromTransView = transitionView(in: newFromView) ?? newFromView
        let fromNavBar = navigationBar(in: newFromView)
        let fromTitleView = titleView(in: fromNavBar)
        let toTransView = transitionView(in: newToView) ?? newToView
        let toNavBar = navigationBar(in: newToView)
        let toTitleView = titleView(in: toNavBar)
        
        dimmedBackgroundView.frame = containerView.frame
        
        if isShow {
            if let toView = toView {
                containerView.addSubview(dimmedBackgroundView)
                containerView.addSubview(toView)
                
                self.hideNavigationBar(toNavBar, includingBgView: true, titleTranslationFactor: titleViewMoveFactor)
                toTransView?.transform = CGAffineTransform(translationX: toView.bounds.width, y: 0)
            }
            
            // To avoid naviagtion bar is transparent to below when do the transition (e.g. PDP -> PLP)
            if fromNavBar?.isTranslucent == true {
                let bgView = UIView(frame: containerView.frame)
                bgView.backgroundColor = ((fromVC as? UINavigationController)?.topViewController?.view ?? fromVC?.view)?.backgroundColor
                containerView.insertSubview(bgView, at: 0)
            }
            
            let translationX = fromTransView.map({ -$0.bounds.width / 3 }) ?? 0.0

            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.4
                
                fromTransView?.transform = CGAffineTransform(translationX: translationX, y: 0)
                self.hideNavigationBar(fromNavBar, includingBgView: false, titleTranslationFactor: -self.titleViewMoveFastFactor)
                self.showNavigationBar(toNavBar)
                
                toTransView?.transform = .identity
                toTitleView?.transform = .identity
            }, completion: { _ in
                fromTransView?.transform = .identity
                fromTitleView?.transform = .identity
                self.completeTransition(completion: completion)
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
            
            let translationX = toTransView.map({ -$0.bounds.width / 3 }) ?? 0.0
            
            toTransView?.transform = CGAffineTransform(translationX: translationX, y: 0)
            hideNavigationBar(toNavBar, includingBgView: false, titleTranslationFactor: -titleViewMoveFactor)
            
            UIView.animate(withDuration: animationDuration, animations: {
                self.dimmedBackgroundView.alpha = 0.0
                
                self.hideNavigationBar(fromNavBar, includingBgView: fromNavBar?.isTranslucent == false, titleTranslationFactor: self.titleViewMoveFastFactor)
                fromTransView?.transform = CGAffineTransform(translationX: fromView.bounds.width, y: 0)
                self.showNavigationBar(toNavBar)
                
                toTransView?.transform = .identity
                toTitleView?.transform = .identity
            }, completion: { _ in
                toTransView?.transform = .identity
                toTitleView?.transform = .identity
                self.completeTransition(completion: completion)
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
        }).last(where: { $0.superview?.superview?.isKind(of: UINavigationBar.self) == true })
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
    
    private func hideNavigationBar(_ navBar: UINavigationBar?, includingBgView: Bool, titleTranslationFactor: CGFloat) {
        if includingBgView {
            navBar?.subviews.forEach({ $0.alpha = 0.0 })
        } else {
            // Remove `_UIBarBackground` view, set alpha for other views.
            navBar?.subviews.dropFirst().forEach({ $0.alpha = 0.0 })
        }
        
        if let titleView = self.titleView(in: navBar) {
            titleView.transform = CGAffineTransform(translationX: titleView.bounds.width * titleTranslationFactor, y: 0)
        }
    }
}
