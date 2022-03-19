//
//  PopoverPresentationController.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/14.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit

@objc open class PopoverPresentationController: UIPresentationController {
    
    private var sourceRect: CGRect
    private let dimmedBackgroundView = UIView()
    
    public init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, sourceRect: CGRect) {
        self.sourceRect = sourceRect
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        let contentVC = (presentedViewController as? UINavigationController)?.topViewController ?? presentedViewController
        if contentVC.pageObject?.dismissWhenTapOutside == true {
            dimmedBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapDimmedBackgroundView)))
        }
    }
    
    public override var frameOfPresentedViewInContainerView: CGRect {
        sourceRect
    }
    
    public override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        containerView?.setNeedsLayout()
    }
    
    public override func presentationTransitionWillBegin() {
        guard let containerView = self.containerView else { return }
        
        containerView.addSubview(self.dimmedBackgroundView)
        dimmedBackgroundView.backgroundColor = .black
        dimmedBackgroundView.frame = containerView.bounds
        
        dimmedBackgroundView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmedBackgroundView.alpha = 0.4
        }, completion: nil)
    }
    
    public override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmedBackgroundView.alpha = 0.0
        }, completion: nil)
    }
    
    public override func dismissalTransitionDidEnd(_ completed: Bool) {
        dimmedBackgroundView.removeFromSuperview()
    }
}

private extension PopoverPresentationController {
    
    @objc dynamic func onTapDimmedBackgroundView() {
        let contentVC = (presentedViewController as? UINavigationController)?.topViewController ?? presentedViewController
        
        contentVC.navigator?.close {
            contentVC.didBackOrClose(.tapOutside)
        }
    }
}
