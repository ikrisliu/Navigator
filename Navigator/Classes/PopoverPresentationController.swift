//
//  PopoverPresentationController.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/14.
//  Copyright © 2019 Crescent. All rights reserved.
//

import UIKit

class PopoverPresentationController: UIPresentationController {
    
    private var sourceRect: CGRect
    private let dimmedBackgroundView = UIView()
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, sourceRect: CGRect, dismissWhenTapOutside: Bool = true) {
        self.sourceRect = sourceRect
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        if dismissWhenTapOutside {
            dimmedBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapDimmedBackgroundView)))
        }
    }
    
    override var frameOfPresentedViewInContainerView: CGRect {
        return sourceRect
    }
    
    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        containerView?.setNeedsLayout()
    }
    
    override func presentationTransitionWillBegin() {
        guard let containerView = self.containerView else { return }
        
        containerView.addSubview(self.dimmedBackgroundView)
        dimmedBackgroundView.backgroundColor = .black
        dimmedBackgroundView.frame = containerView.bounds
        
        dimmedBackgroundView.alpha = 0
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmedBackgroundView.alpha = 0.4
        }, completion: nil)
    }
    
    override func dismissalTransitionWillBegin() {
        presentingViewController.transitionCoordinator?.animate(alongsideTransition: { _ in
            self.dimmedBackgroundView.alpha = 0.0
        }, completion: nil)
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        dimmedBackgroundView.removeFromSuperview()
    }
}

private extension PopoverPresentationController {
    
    @objc dynamic func onTapDimmedBackgroundView() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}
