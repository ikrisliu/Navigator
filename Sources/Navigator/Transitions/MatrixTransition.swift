//
//  MatrixTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit

@objc public class MatrixTransition: Transition {
    
    public override var animationDuration: TimeInterval {
        1.0
    }
    
    public override func animateNavigationTransition(from fromView: UIView?, to toView: UIView?) {
        animatePresentingTransition(from: fromView, to: toView)
    }
    
    public override func animatePresentingTransition(from fromView: UIView?, to toView: UIView?) {
        let containerView = transitionContext.containerView
        
        let oldSliceViews = createSliceViewsWithView(fromView)
        oldSliceViews.forEach({ fromView?.addSubview($0) })
        
        if let toView = toView {
            toView.frame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            containerView.addSubview(toView)
        }
        
        let newSliceViews = createSliceViewsWithView(toView)
        repositionSliceViews(newSliceViews, fromUp: false)
        newSliceViews.forEach({ toView?.addSubview($0) })
        toView?.isHidden = true
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.repositionSliceViews(oldSliceViews, fromUp: true)
            self.resetYPosForSliceViews(newSliceViews, yPos: fromView?.frame.origin.y ?? 0)
        }, completion: { _ in
            toView?.isHidden = false
            oldSliceViews.forEach({ $0.removeFromSuperview() })
            newSliceViews.forEach({ $0.removeFromSuperview() })
            self.transitionContext.completeTransition(!self.transitionContext.transitionWasCancelled)
        })
    }
    
    private func createSliceViewsWithView(_ view: UIView?) -> [UIView] {
        guard let view = view else { return [] }
        
        let sliceWith: CGFloat = 5.0
        var sliceViews: [UIView] = []
        
        for xPos in stride(from: CGFloat(0), to: view.bounds.width, by: sliceWith) {
            let rect = CGRect(x: xPos, y: 0, width: sliceWith, height: view.bounds.height)
            if let sliceView = view.resizableSnapshotView(from: rect, afterScreenUpdates: true, withCapInsets: .zero) {
                sliceView.frame = rect
                sliceViews.append(sliceView)
            }
        }
        
        return sliceViews
    }
    
    private func repositionSliceViews(_ sliceViews: [UIView], fromUp: Bool) {
        var height: CGFloat = 0
        var isFromUp = fromUp
        for sliceView in sliceViews {
            height = sliceView.bounds.height * random(min: 1.0, max: 4.0)
            sliceView.frame.origin.y += isFromUp ? -height : height
            isFromUp = !isFromUp
        }
    }
    
    private func random(min: CGFloat, max: CGFloat) -> CGFloat {
        CGFloat(arc4random()) / CGFloat(UInt32.max) * (max - min) + min
    }
    
    private func resetYPosForSliceViews(_ sliceViews: [UIView], yPos: CGFloat) {
        sliceViews.forEach({ $0.frame.origin.y = yPos })
    }
}
