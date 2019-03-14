//
//  OverlayPresentationController.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/14.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import Foundation

class OverlayPresentationController: UIPresentationController {
    
    private var preferredHeight: CGFloat
    private let dimmedBackgroundView = UIView()
    
    init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, preferredHeight: CGFloat) {
        self.preferredHeight = preferredHeight
        
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        
        dimmedBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapDimmedBackgroundView)))
    }
    
    override func containerViewWillLayoutSubviews() {
        super.containerViewWillLayoutSubviews()
        
        if let bounds = containerView?.bounds {
            presentedView?.frame = CGRect(x: 0, y: bounds.height - preferredHeight, width: bounds.width, height: preferredHeight)
        }
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

private extension OverlayPresentationController {
    
    @objc dynamic func onTapDimmedBackgroundView() {
        presentingViewController.dismiss(animated: true, completion: nil)
    }
}
