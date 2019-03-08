//
//  Navigator+Private.swift
//  Navigator
//
//  Created by Kris Liu on 2018/9/14.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import os.log

// MARK: - Data Stack
extension Navigator {
    
    var stackCount: Int {
        return stack.dictionaryRepresentation().count
    }
    
    var topViewController: UIViewController? {
        return stackCount > 0 ? stack.object(forKey: (stackCount - 1) as NSNumber) : nil
    }
    
    var navigationController: UINavigationController? {
        if let navigationController = topViewController?.navigationController {
            return navigationController
        }
        
        for _ in 0..<stackCount {
            assertionFailure("\(topViewController!) has not been released immediately.")
            popStack()
            
            if let navigationController = topViewController?.navigationController {
                return navigationController
            }
        }
        
        return nil
    }
    
    func stackIndex(of vcName: String) -> Int? {
        guard let objEnumerator = stack.objectEnumerator() else { return nil }
        let keyEnumerator = stack.keyEnumerator()
        
        for (key, value) in zip(keyEnumerator, objEnumerator) {
            if NSStringFromClass(type(of: value as AnyObject)) == vcName {
                return (key as? NSNumber)?.intValue
            }
        }
        
        return nil
    }
    
    func pushStack(_ viewController: UIViewController) {
        stack.setObject(viewController, forKey: stackCount as NSNumber)
    }
    
    @discardableResult
    func popStack(from level: Int = 0) -> UIViewController? {
        let index = max(stackCount - 1 - level, 0)
        guard index < stackCount else { return nil }
        
        let poppedVC = stack.object(forKey: index as NSNumber)
        (index..<stackCount).forEach({ stack.removeObject(forKey: $0 as NSNumber) })
        
        return poppedVC
    }
    
    @discardableResult
    func popStackToRoot() -> UIViewController? {    // Excluding root vc
        return popStack(from: stackCount - 2)
    }
    
    @discardableResult
    func popStackAll() -> UIViewController? {       // Including root vc
        return popStack(from: stackCount - 1)
    }
}

// MARK: - Show View Controllers
extension Navigator {
    
    func showViewControllers() {
        guard let showModel = showModel else { return }
        
        let viewController = createViewController(showModel)
        guard !showTabBarControlerIfExisted(viewController) else { return }
        guard !showSplitViewControllerIfExisted(viewController) else { return }
        guard !showNavigationControlerIfExisted(viewController) else { return }
        guard !showViewControler(viewController) else { return }
    }
    
    func showTabBarControlerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let showModel = showModel else { return false }
        guard let tabVC = viewController as? UITabBarController else { return false }
        
        addChildViewControllersIfExisted(showModel.children, toViewController: tabVC)
        return showViewControler(viewController)
    }
    
    func showSplitViewControllerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let showModel = showModel else { return false }
        guard let splitVC = viewController as? UISplitViewController else { return false }
        
        addChildViewControllersIfExisted(showModel.children, toViewController: splitVC)
        return showViewControler(viewController)
    }
    
    func showNavigationControlerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let showModel = showModel else { return false }
        guard let navVC = viewController as? UINavigationController else { return false }
        
        addChildViewControllersIfExisted(showModel.children, toViewController: navVC)
        return showViewControler(viewController)
    }
    
    // Deep Link
    func showDeepLinkViewControllers(_ data: DataModel) {
        guard let topVC = topViewController else {
            showViewControllers()
            if let next = data.next {
                Navigator.root.showDeepLinkViewControllers(next)
            }
            return
        }
        
        if topVC is UITabBarController || topVC is UISplitViewController {
            let viewControllers = Navigator.childViewControllers(of: topVC)
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == data.viewController })
            
            if let vc = viewController, let index = viewControllers.index(of: vc) {
                (topVC as? UITabBarController)?.selectedIndex = index
            }
            
            if let next = data.next {
                viewController?.navigator?.showDeepLinkViewControllers(next)
            }
            
            return
        }
        
        popStack(from: -1)  // Pop stack until remain 1 root view controller
        
        if let navControler = topViewController?.navigationController {
            navControler.popToRootViewController(animated: false)
        } else {
            topViewController?.dismiss(animated: false, completion: nil)
        }
        
        var next: DataModel? = data
        
        while let nextData = next {
            let viewController = createViewController(nextData)
            p_showViewControler(viewController, dataModel: nextData, animated: nextData.next == nil)
            next = nextData.next
        }
    }
    
    static func childViewControllers(of viewController: UIViewController) -> [UIViewController] {
        var viewControllers: [UIViewController] = []
        
        if let tabVC = viewController as? UITabBarController {
            viewControllers = tabVC.viewControllers ?? []
        } else if let splitVC = viewController as? UISplitViewController {
            viewControllers = splitVC.viewControllers
        }
        
        return viewControllers.map({ ($0 as? UINavigationController)?.topViewController ?? $0 })
    }
    
    // Show view controller by push or present way. If mode is root, show the view controller directly.
    func showViewControler(_ viewController: UIViewController) -> Bool {
        guard let showModel = showModel else { return false }
        
        return p_showViewControler(viewController, dataModel: showModel, animated: showAnimated)
    }
    
    @discardableResult
    func p_showViewControler(_ viewController: UIViewController, dataModel: DataModel, animated: Bool) -> Bool {
        let toVC = viewController.navigationController ?? viewController
        
        // Must set presentation style first for `UIModalPresentationStylePopover`
        toVC.modalPresentationStyle = dataModel.presentationStyle
        p_sendDataBeforeShow(dataModel, fromVC: topViewController, toVC: viewController)
        
        switch dataModel.mode {
        case .push:
            CATransaction.begin()
            CATransaction.setCompletionBlock { self.showCompletion?() }
            setupTransition(dataModel, for: topViewController?.navigationController)
            navigationController?.pushViewController(toVC, animated: animated)
            CATransaction.commit()
            
        case .present:
            setupTransition(dataModel, for: toVC.navigationController ?? toVC)
            topViewController?.present(toVC, animated: animated, completion: showCompletion)
            
        case .reset:
            resetViewController(toVC)
        }
        
        if rootViewController == nil {
            showModel?.mode = .reset
            rootViewController = toVC
        }
        
        viewController.p_navigatorMode = dataModel.mode
        pushStack(viewController)
        
        return true
    }
    
    func resetViewController(_ viewController: UIViewController) {
        var splitViewController = topViewController?.splitViewController
        splitViewController = splitViewController ?? navigationController?.splitViewController
        
        if let splitVC = splitViewController, splitVC.viewControllers.count > 1 {   // iPad
            splitVC.showDetailViewController(viewController, sender: nil)
        } else {
            window = Navigator.root.window
        }
        
        popStackAll()
        setupNavigatorForViewController(viewController)
    }
    
    // Set custom tranistion animation when push or present a view controller
    func setupTransition(_ dataModel: DataModel, for viewController: UIViewController?) {
        if let name = dataModel.transitionClass, !name.isEmpty, let vc = viewController {
            vc.p_navigatorTransition = createTransition(name)
            
            if let nav = vc as? UINavigationController, dataModel.mode == .push {
                nav.delegate = vc.p_navigatorTransition
            } else if dataModel.mode == .present {
                vc.transitioningDelegate = vc.p_navigatorTransition
            }
        } else {
            viewController?.modalTransitionStyle = dataModel.transitionStyle
        }
        
        guard dataModel.presentationStyle == .popover else { return }
        
        viewController?.popoverPresentationController?.sourceView = dataModel.sourceView
        
        if let sourceRect = dataModel.sourceRect {
            viewController?.popoverPresentationController?.sourceRect = sourceRect.cgRectValue
        }
    }
    
    // Create view controller with class name. If need embed it into navigation controller, create one with view controller.
    func createViewController(_ dataModel: DataModel) -> UIViewController {
        let viewController: UIViewController
        
        defer {
            if let navName = dataModel.navigationController, !navName.isEmpty, !(viewController is UINavigationController) {
                if let navType = NSClassFromString(navName) as? UINavigationController.Type {
                    let navigationController = navType.init()
                    navigationController.viewControllers = [viewController]
                    navigationController.navigator = self
                } else {
                    os_log("❌ [Navigator]: Can not find navigation controller class %@ in your modules", navName)
                }
            }
        }
        
        let vcName = dataModel.viewController
        guard !vcName.isEmpty else {
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        
        guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            os_log("❌ [Navigator]: Can not find view controller class %@ in your modules", vcName)
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        
        viewController = vcType.init()
        viewController.navigator = self
        
        return viewController
    }
    
    // Create fallback view controller instance with class name.
    func createFallbackViewController(_ dataModel: DataModel) -> UIViewController {
        guard let vcName = dataModel.fallback, let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            let viewController = Fallback()
            viewController.navigator = self
            return viewController
        }
        
        let viewController = vcType.init()
        viewController.navigator = self
        
        return viewController
    }
    
    // Create custom transition instance with class name.
    func createTransition(_ className: String?) -> Transition? {
        guard let name = className, !name.isEmpty else { return nil }
        guard let type = NSClassFromString(name) as? Transition.Type else {
            os_log("❌ [Navigator]: Can not find transition class %@ in your modules", name)
            return nil
        }
        return type.init()
    }
    
    // Add child view controllers for container view controllers like Navigation/Split/Tab view controller
    func addChildViewControllersIfExisted(_ data: [DataModel]?, toViewController: UIViewController) {
        guard let data = data else { return }
        
        var viewControllers: [UIViewController] = []
        
        for itemModel in data {
            let toVC = createViewController(itemModel)
            
            p_sendDataBeforeShow(itemModel, fromVC: toViewController, toVC: toVC)
            viewControllers.append(toVC.navigationController ?? toVC)
            
            if let children = itemModel.children, !children.isEmpty {
                addChildViewControllersIfExisted(itemModel.children, toViewController: toVC)
            }
        }
        
        guard !viewControllers.isEmpty else { return }
        
        for (idx, vc) in viewControllers.enumerated() {
            let childVC = (vc as? UINavigationController)?.topViewController ?? vc
            let navigator = Navigator()
            
            navigator.setupNavigatorForViewController(vc)
            navigator.pushStack(childVC)
            
            if idx == 0, let navigator = childVC.navigator {
                Navigator._current = navigator
            }
        }
        
        (toViewController as? UITabBarController)?.viewControllers = viewControllers
        (toViewController as? UISplitViewController)?.viewControllers = viewControllers
        (toViewController as? UINavigationController)?.viewControllers = viewControllers
    }
    
    func setupNavigatorForViewController(_ viewController: UIViewController) {
        rootViewController = viewController
        viewController.p_navigatorMode = .reset
        viewController.navigator = self
        viewController.navigationController?.navigator = self
        (viewController as? UINavigationController)?.topViewController?.navigator = self
    }
}

// MARK: - Dismiss View Controllers
extension Navigator {
    
    func dismissViewControllers() {
        let level = self.level > 0 ? self.level : stackCount + self.level - 1
        guard let dismissedVC = popStack(from: level) else { return }
        
        if dismissedVC.p_navigatorMode == .present {
            dismissViewController(dismissedVC)
            return
        }
        
        if let nav = dismissedVC.navigationController {
            popViewController(dismissedVC, fromNav: nav)
        } else {
            dismissViewController(dismissedVC.navigationController ?? dismissedVC)
        }
    }
    
    func dismissViewController(_ viewController: UIViewController) {
        // Sometimes the dismissModel will be released, use a local variable which can be catched by block to make data hold a moment.
        let dismissModel = self.dismissModel
        let vc = viewController.presentingViewController ?? viewController
        
        sendDataBeforeBack(dismissModel, level: level)
        
        vc.dismiss(animated: dismissAnimated, completion: {
            self.sendDataAfterBack(dismissModel)
            self.dismissCompletion?()
        })
    }
    
    func popViewController(_ viewController: UIViewController, fromNav: UINavigationController) {
        let dismissModel = self.dismissModel
        
        sendDataBeforeBack(dismissModel, level: level)
        
        if let presentingVC = findPresentingViewController(base: viewController, in: fromNav) {
            presentingVC.dismiss(animated: false, completion: {
                self.popTopViewController(fromNav: fromNav) {
                    self.sendDataAfterBack(dismissModel)
                    self.dismissCompletion?()
                }
            })
        } else {
            popTopViewController(fromNav: fromNav) {
                self.sendDataAfterBack(dismissModel)
            }
        }
    }
    
    func popTopViewController(fromNav: UINavigationController, completion: CompletionType) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { completion?() }
        if let topVC = topViewController, fromNav.viewControllers.contains(topVC) {
            fromNav.popToViewController(topVC, animated: dismissAnimated)
        } else {
            fromNav.popToRootViewController(animated: dismissAnimated)
        }
        CATransaction.commit()
    }
    
    func findPresentingViewController(base viewController: UIViewController, in navController: UINavigationController) -> UIViewController? {
        let baseIndex = navController.viewControllers.index(of: viewController) ?? 0
        
        for (index, vc) in (navController.viewControllers as Array).enumerated() where index >= baseIndex && vc.presentedViewController != nil {
            return vc
        }
        
        return nil
    }
}

// MARK: - Goto View Controller
extension Navigator {
    
    func gotoViewControllerIfExisted(_ vcName: String) -> Bool {
        guard self !== Navigator.root else {
            guard let rootVC = rootViewController else { return false }
            
            let viewControllers = Navigator.childViewControllers(of: rootVC)
            // NOTE: Method `String(describing:)` returned string always doesn't match with `vcName`
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == vcName })
            
            if let vc = viewController, let index = viewControllers.index(of: vc) {
                (rootVC as? UITabBarController)?.selectedIndex = index
                return true
            } else {
                os_log("❌ Can not find view controller class %@ in navigation stack", vcName)
                return false
            }
        }
        
        guard let index = stackIndex(of: vcName) else { return false }
        if index + 1 < stackCount {
            popStack(from: index + 1)
        }
        
        guard let rootVC = Navigator.root.rootViewController else { return false }
        
        let viewControllers = Navigator.childViewControllers(of: rootVC)
        if let rootVC = rootViewController, let index = viewControllers.index(of: rootVC) {
            (rootViewController as? UITabBarController)?.selectedIndex = index
        }
        
        guard let topVC = topViewController else { return false }
        
        if let navControler = topVC.navigationController {
            navControler.popToViewController(topVC, animated: false)
        } else {
            topVC.dismiss(animated: false, completion: nil)
        }
        
        return true
    }
}

// MARK: - Send and Receive Data
extension Navigator {
    
    func p_sendDataBeforeShow(_ data: DataModel, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("➡️ [Navigator]: Send data from %@ before show: %@", String(describing: fromVC), data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeShow?(data, fromViewController: fromVC)
    }
    
    func p_sendDataBeforeBack(_ data: DataModel, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("⬅️ [Navigator]: Send data from %@ before before: %@", String(describing: fromVC), data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeBack?(data, fromViewController: fromVC)
    }
    
    func p_sendDataAfterBack(_ data: DataModel, toVC: UIViewController) {
        os_log("⬅️ [Navigator]: Send data to %@ after before: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveAfterBack?(data, fromViewController: nil)
    }
}
