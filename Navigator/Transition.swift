//
//  Transition.swift
//  Navigator
//
//  Created by Kris Liu on 5/28/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit

// MARK: - Public -
@objc open class Transition: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UINavigationControllerDelegate {
    
    @objc(TransitionOrientation)
    public enum Orientation: Int {
        /// push transition orientation is horizontal, present transition orientation is vertical.
        case `default`
        case horizontal
        case vertical
    }
    
    /// Whether enable gesture to pop/dismiss current view controller, default is false.
    @objc open var interactiveGestureEnabled = true
    @objc open var orientation: Orientation = .default
    @objc public var isVertical: Bool { return orientation == .vertical }
    @objc public private(set) weak var transitionContext: UIViewControllerContextTransitioning!
    
    /// Show or Dismiss
    @objc public private(set) var isShow = false
    /// Present or Push
    @objc public private(set) var isModal = false {
        didSet {
            if orientation == .default {
                orientation = isModal ? .vertical : .horizontal
            }
        }
    }
    
    /// Overwrite this variable to assign a custom animation duration
    @objc open var animationDuration: TimeInterval {
        return transitionDuration(using: transitionContext)
    }
    
    /// For modal present or dismiss, need overwrite by subclass if define a custom transition
    @objc open func animatePresentingTransition(from fromVC: UIViewController, to toVC: UIViewController) { }
    
    /// For navigation push or pop, need overwrite by subclass if define a custom transition
    @objc open func animateNavigationTransition(from fromVC: UIViewController, to toVC: UIViewController) { }
    
    
    @objc required public override init() {
        super.init()
    }
    
    deinit {
        removeInteractiveGesture()
    }
    
    // Private
    // Whether start interaction, different usage with variable interactiveGestureEnabled. Must need this flag.
    private var isInteractive: Bool = false
    private var panGesture: UIPanGestureRecognizer!
    private var startLocation: CGPoint!
    
    private weak var presentedVC: UIViewController?
    private weak var presentingVC: UIViewController?
    private weak var navController: UINavigationController?
}

// MARK: - UIViewControllerAnimatedTransitioning
@objc public extension Transition {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return CATransaction.animationDuration()
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        guard let fromVC = transitionContext.viewController(forKey: .from) else { return }
        guard let toVC = transitionContext.viewController(forKey: .to) else { return }
        
        fromVC.view.frame = transitionContext.initialFrame(for: fromVC)
        toVC.view.frame = transitionContext.finalFrame(for: toVC)
        
        if isModal {
            animatePresentingTransition(from: fromVC, to: toVC)
        } else {
            animateNavigationTransition(from: fromVC, to: toVC)
        }
    }
    
    public func animationEnded(_ transitionCompleted: Bool) {
        isShow = false
        isInteractive = false
    }
}

// MARK: - UIViewControllerTransitioningDelegate
@objc public extension Transition {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isShow = true
        isModal = true
        presentedVC = presented
        presentingVC = presenting
        addInteractiveGestureToViewControllerIfNeeded(viewController: presentedVC!)
        return self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        isShow = false
        return isInteractive ? self : nil
    }
    
//    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        isShowing = true
//        return isInteractive ? self : nil
//    }
    
    /// NOTE: If need custom popover presentation controller, can overwrite this method to provide one.
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return nil
    }
}

// MARK: - UINavigationControllerDelegate
@objc public extension Transition {
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return isInteractive ? self : nil
    }
    
    public func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard operation != .none else { return nil }
        
        navController = navigationController
        let fromIndex = navController?.viewControllers.index(of: fromVC)
        let toIndex = navController?.viewControllers.index(of: toVC)
        isShow = (fromIndex != nil && toIndex != nil && toIndex! > fromIndex!)
        isModal = false
        addInteractiveGestureToViewControllerIfNeeded(viewController: navController!)
        
        return self
    }
}

// MARK: - Private -
// Handle interactive gesture for pop/dismiss current view controller
private extension Transition {
    
    private func addInteractiveGestureToViewControllerIfNeeded(viewController: UIViewController) {
        guard interactiveGestureEnabled else { return }
        
        if isVertical {
            panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
        } else {
            panGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
            (panGesture as! UIScreenEdgePanGestureRecognizer).edges = .left
        }
        viewController.view.addGestureRecognizer(panGesture!)
    }
    
    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        guard let recognizerView = recognizer.view else { return }
        let translation = recognizer.translation(in: recognizerView)
        let velocity = recognizer.velocity(in: recognizerView)
        
        switch recognizer.state {
        case .began:
            isInteractive = true
            startLocation = recognizer.location(in: recognizerView.superview)
            handleViewController(velocity)
            
        case .changed:
            let ratio = isVertical ? (translation.y / recognizerView.bounds.height) : ((translation.x + startLocation.x) / recognizerView.bounds.width)
            update(ratio / 2.0)
            
        case .ended:
            isInteractive = false
            let offset = isVertical ? CGFloat.maximum(velocity.y, translation.y - self.startLocation.y/2) : CGFloat.maximum(velocity.x, translation.x - self.startLocation.x/2)
            let isFinish = self.isVertical ? offset > recognizerView.bounds.height/4 : offset > recognizerView.bounds.width/2
            if (isFinish) {
                finish()
            } else {
                cancel()
            }
            
        case .failed, .cancelled:
            isInteractive = false
            cancel()
            
        default:
            break
        }
    }
    
    private func handleViewController(_ velocity: CGPoint) {
        if isModal {
            if isShow {
                if let vc = presentedVC, velocity.y < 0 {
                    presentingVC?.present(vc, animated: true, completion: nil)
                }
            } else {
                if velocity.y > 0 {
                    presentedVC?.dismiss(animated: true, completion: nil)
                }
            }
        } else {
            if isShow {
                if let vc = presentedVC {
                    navController?.pushViewController(vc, animated: true)
                }
            } else {
                navController?.popViewController(animated: true)
            }
        }
    }
    
    private func removeInteractiveGesture() {
        presentedVC?.view.removeGestureRecognizer(panGesture)
        presentingVC?.view.removeGestureRecognizer(panGesture)
        navController?.view.removeGestureRecognizer(panGesture)
    }
}
