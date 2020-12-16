//
//  UINavigationController+Transition.swift
//  Navigator
//
//  Created by Kris Liu on 2019/8/1.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: Navigator.CompletionBlock?) {
        pushViewController(viewController, animated: animated)
        handleAnimateCompletion(animated: animated, completion: completion)
    }
    
    func popViewController(animated: Bool, completion: Navigator.CompletionBlock?) {
        popViewController(animated: animated)
        handleAnimateCompletion(animated: animated, completion: completion)
    }
    
    func popToViewController(_ viewController: UIViewController, animated: Bool, completion: Navigator.CompletionBlock?) {
        popToViewController(viewController, animated: animated)
        handleAnimateCompletion(animated: animated, completion: completion)
    }
    
    func popToRootViewController(animated: Bool, completion: Navigator.CompletionBlock?) {
        popToRootViewController(animated: animated)
        handleAnimateCompletion(animated: animated, completion: completion)
    }
    
    private func handleAnimateCompletion(animated: Bool, completion: Navigator.CompletionBlock?) {
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in completion?() }
        } else {
            completion?()
        }
    }
}
