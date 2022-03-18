//
//  MatrixTransition.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/25.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

@objc public class MatrixTransition: Transition {
    
    public override var animationDuration: TimeInterval {
        1.0
    }
    
    public override func animateNavigationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        animatePresentationTransition(isShow: isShow, from: fromView, to: toView, completion: completion)
    }
    
    public override func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        guard let transitionContext = transitionContext else { return }
        let containerView = transitionContext.containerView
        
        if let toView = toView {
            toView.frame = transitionContext.finalFrame(for: transitionContext.viewController(forKey: .to)!)
            containerView.addSubview(toView)
        }
        
        let sliceViews = createSliceViewsWithView(toView)
        repositionSliceViews(sliceViews, fromUp: false)
        sliceViews.forEach({ fromView?.addSubview($0) })
        
        toView?.isHidden = true
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
            self.resetYPosForSliceViews(sliceViews, yPos: toView?.frame.origin.y ?? 0)
        }, completion: { _ in
            toView?.isHidden = false
            sliceViews.forEach({ $0.removeFromSuperview() })
            self.completeTransition(completion: completion)
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
