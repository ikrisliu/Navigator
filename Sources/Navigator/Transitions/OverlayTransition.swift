//
//  OverlayTransition.swift
//  
//
//  Created by Kris Liu on 2022/3/17.
//

import UIKit

/// - NOTE: This transition only work for navigation mode with `overlay`
@objc public class OverlayTransition : Transition {
    
    public override func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) {
        guard let fromView = fromView, let toView = toView else { return }
        
        if isShow {
            let finalFrame = toView.frame
            fromView.alpha = 0.0
            toView.frame.origin = .init(x: 0, y: fromView.bounds.size.height)
            
            UIView.animate(withDuration: animationDuration, animations: {
                fromView.alpha = 0.4
                toView.frame = finalFrame
            }, completion: { _ in
                self.completeTransition(completion: completion)
            })
        } else {
            UIView.animate(withDuration: animationDuration, animations: {
                fromView.frame.origin = .init(x: 0, y: toView.bounds.size.height)
                toView.alpha = 0.0
            }, completion: { _ in
                self.completeTransition(completion: completion)
            })
        }
    }
}
