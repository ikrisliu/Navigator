//
//  Transition.swift
//  Navigator
//
//  Created by Kris Liu on 5/28/18.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

// MARK: - Public -
@objc open class Transition: UIPercentDrivenInteractiveTransition {
    
    @objc(TransitionOrientation)
    public enum Orientation: Int {
        /// push transition orientation is horizontal, present transition orientation is vertical.
        case `default`
        case horizontal
        case vertical
    }
    
    /// Whether enable gesture to pop/dismiss current view controller, default is false.
    @objc open var interactiveGestureEdges: UIRectEdge = []
    @objc open var orientation: Orientation = .default
    @objc open var preferredPresentationHeight: CGFloat = 0
    
    @objc public var sourceRect: CGRect = .zero
    
    @objc public var isVertical: Bool { orientation == .vertical }
    @objc public var transitionContext: UIViewControllerContextTransitioning { _transitionContext! }
    private weak var _transitionContext: UIViewControllerContextTransitioning?
    
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
        transitionDuration(using: transitionContext)
    }
    
    /// For modal present or dismiss, need overwrite by subclass if define a custom transition
    @objc open func animatePresentingTransition(from fromView: UIView?, to toVC: UIView?) { }
    
    /// For navigation push or pop, need overwrite by subclass if define a custom transition
    @objc open func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) { }
    
    
    @objc required public override init() {
        super.init()
    }
    
    deinit {
        removeInteractiveGesture()
    }
    
    // MARK: - Private -
    // Whether start interaction, different usage with variable interactiveGestureEdges. Must need this flag.
    private var isInteractionInProgress: Bool = false
    private var leftPanGesture: UIPanGestureRecognizer?
    private var rightPanGesture: UIPanGestureRecognizer?
    private var verticalPanGesture: UIPanGestureRecognizer?
    private var startLocation: CGPoint?
    
    private weak var presentedVC: UIViewController?
    private weak var presentingVC: UIViewController?
    private weak var navController: UINavigationController?
    private weak var panGestureVC: UIViewController?
}

// MARK: - UIViewControllerAnimatedTransitioning
extension Transition: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        CATransaction.animationDuration()
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        _transitionContext = transitionContext
        
        let fromView = transitionContext.view(forKey: .from)
        let toView = transitionContext.view(forKey: .to)
        
        fromView?.frame = transitionContext.initialFrame(for: transitionContext.viewController(forKey: .from)!)
        toView?.frame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
        
        if isModal {
            animatePresentingTransition(from: fromView, to: toView)
        } else {
            animateNavigationTransition(from: fromView, to: toView)
        }
    }
    
    public func animationEnded(_ transitionCompleted: Bool) {
        if isInteractionInProgress && !isShow && _transitionContext?.transitionWasCancelled != true {
            panGestureVC?.didFinishDismissing(.interactiveGesture)
        }
        
        isShow = false
        isInteractionInProgress = false
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension Transition: UIViewControllerTransitioningDelegate {
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        isShow = true
        isModal = true
        presentedVC = presented
        presentingVC = presenting
        
        addInteractiveGestureToViewControllerIfNeeded(viewController: presentedVC)
        
        return type(of: self) == Transition.self ? nil : self
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        type(of: self) == Transition.self ? nil : self
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        isShow = false
        return (isInteractionInProgress && type(of: self) != Transition.self) ? self : nil
    }
    
//    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
//        isShowing = true
//        return (isInteractive && type(of: self) != Transition.self) ? self : nil
//    }
    
    /// - Note: If need custom popover presentation controller, can overwrite this method to provide one.
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PopoverPresentationController(presentedViewController: presented, presenting: presenting, sourceRect: sourceRect, dismissWhenTapOutside: true)
    }
}

// MARK: - UINavigationControllerDelegate
extension Transition: UINavigationControllerDelegate {
    
    public func navigationController(_ navigationController: UINavigationController,
                                     interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        isInteractionInProgress ? self : nil
    }
    
    public func navigationController(_ navigationController: UINavigationController,
                                     animationControllerFor operation: UINavigationController.Operation,
                                     from fromVC: UIViewController,
                                     to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard operation != .none else { return nil }
        
        navController = navigationController
        
        let fromIndex = navController?.viewControllers.firstIndex(of: fromVC)
        let toIndex = navController?.viewControllers.firstIndex(of: toVC)
        
        isShow = (fromIndex != nil && toIndex != nil && toIndex! > fromIndex!)
        isModal = false
        
        addInteractiveGestureToViewControllerIfNeeded(viewController: navController)
        
        return self
    }
}

// MARK: - Private -
// Handle interactive gesture for pop/dismiss current view controller
extension Transition {
    
    private func addInteractiveGestureToViewControllerIfNeeded(viewController: UIViewController?) {
        guard let vc = (viewController as? UINavigationController)?.topViewController ?? viewController,
              !interactiveGestureEdges.isEmpty, vc.enableInteractiveDismissGesture else { return }
        panGestureVC = vc

        if interactiveGestureEdges.contains(.left) {
            leftPanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
            (leftPanGesture as? UIScreenEdgePanGestureRecognizer)?.edges = [.left]
            vc.view.addGestureRecognizer(leftPanGesture!)
        }
        if interactiveGestureEdges.contains(.right) {
            rightPanGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
            (rightPanGesture as? UIScreenEdgePanGestureRecognizer)?.edges = [.right]
            vc.view.addGestureRecognizer(rightPanGesture!)
        }
        if interactiveGestureEdges.contains(.top) || interactiveGestureEdges.contains(.bottom) {
            verticalPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(recognizer:)))
            vc.view.addGestureRecognizer(verticalPanGesture!)
        }
    }
    
    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        guard let recognizerView = recognizer.view else { return }
        
        let isReverse = recognizer == rightPanGesture
        let translation = recognizer.translation(in: recognizerView)
        let velocity = recognizer.velocity(in: recognizerView)
        
        var xLocation = startLocation != nil ? startLocation!.x : 0
        let yLocation = startLocation != nil ? startLocation!.y : 0
        
        let xVelocity = isReverse ? -velocity.x : velocity.x
        let yVelocity = velocity.y
        
        switch recognizer.state {
        case .began:
            if panGestureVC?.shouldDismissByInteractiveGesture != true {
                cancel()
                return
            }
            if _transitionContext?.isAnimated == true {
                finish()
                return
            }
            if verticalPanGesture != nil && translation.y < 0 { return }
            
            isInteractionInProgress = true
            startLocation = recognizer.location(in: recognizerView.superview)
            handleViewController()
            
        case .changed:
            guard isInteractionInProgress else { return }
            
            let ratio = isVertical ? (translation.y / recognizerView.bounds.height) : ((abs(translation.x) + xLocation) / recognizerView.bounds.width)
            update(isReverse ? ratio - 1 : ratio)
            
        case .ended:
            guard isInteractionInProgress else { return }
            
            xLocation = isReverse ? recognizerView.bounds.width - xLocation : xLocation
            
            let offset = isVertical ? CGFloat.maximum(yVelocity / 2, translation.y + yLocation) : CGFloat.maximum(xVelocity / 2, abs(translation.x) + xLocation)
            let isFinish = isVertical ? offset > recognizerView.bounds.height / 2 : offset > recognizerView.bounds.width / 2
            
            if isFinish {
                completionSpeed = (1.0 - percentComplete)
                finishAll()
            } else {
                completionSpeed = 0.25
                cancel()
            }
            
        case .failed, .cancelled:
            isInteractionInProgress = false
            cancel()
            
        default:
            break
        }
    }
    
    func finishAll() {
        panGestureVC?.willFinishDismissing(.interactiveGesture)
        finish()
        presentedVC?.navigator?.popStack()  // To avoid the retain cycled vc can't be removed from navigator stack
    }
    
    private func handleViewController() {
        if isModal {
            if isShow {
                if let vc = presentedVC {
                    presentingVC?.present(vc, animated: true, completion: nil)
                }
            } else {
                presentedVC?.dismiss(animated: true, completion: nil)
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
        [leftPanGesture, rightPanGesture, verticalPanGesture].compactMap({ $0 }).forEach {
            presentedVC?.view.removeGestureRecognizer($0)
            presentingVC?.view.removeGestureRecognizer($0)
            navController?.view.removeGestureRecognizer($0)
        }
    }
}
