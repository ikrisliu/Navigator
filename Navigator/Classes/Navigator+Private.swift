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
        for (key, value) in zip(stack.keyEnumerator(), stack.objectEnumerator()!) {
            if NSStringFromClass(type(of: value as AnyObject)) == vcName {
                return (key as! NSNumber).intValue
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
    func popStackAll() -> UIViewController? {
        return popStack(from: stackCount-1)
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
        guard let topVC = topViewController else { return }
        
        if topVC is UITabBarController || topVC is UISplitViewController {
            let viewControllers = Navigator.childViewControllers(of: topVC)
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == showModel!.viewController })
            if let vc = viewController, let index = viewControllers.index(of: vc) {
                (topVC as? UITabBarController)?.selectedIndex = index
            }
            viewController?.navigator?.showDeepLinkViewControllers(data)
            return
        }
        
        popStack(from: stackCount-2)    // Pop stack until remain 1 element
        
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
        
        if viewController is UITabBarController {
            viewControllers = (viewController as! UITabBarController).viewControllers!
        } else if viewController is UISplitViewController {
            viewControllers = (viewController as! UISplitViewController).viewControllers
        }
        
        return viewControllers.map({ $0 is UINavigationController ? ($0 as! UINavigationController).topViewController! : $0 })
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
            setupTransition(dataModel, for: topViewController?.navigationController)
            navigationController?.pushViewController(toVC, animated: animated)
            
        case .present:
            setupTransition(dataModel, for: toVC.navigationController ?? toVC)
            topViewController?.present(toVC, animated: animated, completion: nil)
            
        case .reset:
            resetViewController(toVC)
        }
        
        if rootViewController == nil {
            showModel!.mode = .reset
            rootViewController = toVC
        }
        
        viewController._navigatorMode = showModel!.mode
        pushStack(viewController)
        
        return true
    }
    
    func resetViewController(_ viewController: UIViewController) {
        var splitViewController = topViewController?.splitViewController
        splitViewController = splitViewController ?? navigationController?.splitViewController
        
        guard let splitVC = splitViewController else {
            window = Navigator.root.window
            popStackAll()
            setupNavigatorForViewController(viewController)
            return
        }
        
        if splitVC.viewControllers.count == 1 {     // For Phone
            (splitVC.viewControllers.first as? UINavigationController)?.pushViewController(viewController, animated: true)
        } else {
            splitVC.showDetailViewController(viewController, sender: nil)
            popStackAll()
            setupNavigatorForViewController(viewController)
        }
    }
    
    // Set custom tranistion animation when push or present a view controller
    func setupTransition(_ dataModel: DataModel, for viewController: UIViewController?) {
        if let name = dataModel.transitionClass, !name.isEmpty, let vc = viewController {
            vc._navigatorTransition = createTransition(name)
            
            if dataModel.mode == .push {
                (vc as! UINavigationController).delegate = vc._navigatorTransition
            } else if dataModel.mode == .present {
                vc.transitioningDelegate = vc._navigatorTransition
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
        var viewController: UIViewController!
        
        defer {
            if let navName = dataModel.navigationController, !navName.isEmpty {
                if let navType = NSClassFromString(navName) as? UINavigationController.Type {
                    let navigationController = navType.init()
                    navigationController.viewControllers = [viewController]
                    navigationController.navigator = self
                } else {
                    os_log("🧭❌ Can not find navigation controller class %@ in your modules", navName)
                }
            }
        }
        
        let vcName = dataModel.viewController
        guard !vcName.isEmpty else {
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        
        guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            os_log("🧭❌ Can not find view controller class %@ in your modules", vcName)
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
            os_log("🧭❌ Can not find transition class %@ in your modules", name)
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
            
            if idx == 0 {
                Navigator._current = childVC.navigator!
            }
        }
        
        (toViewController as? UITabBarController)?.viewControllers = viewControllers
        (toViewController as? UISplitViewController)?.viewControllers = viewControllers
        (toViewController as? UINavigationController)?.viewControllers = viewControllers
    }
    
    func setupNavigatorForViewController(_ viewController: UIViewController) {
        rootViewController = viewController
        viewController._navigatorMode = .reset
        viewController.navigator = self
        viewController.navigationController?.navigator = self
        (viewController as? UINavigationController)?.topViewController?.navigator = self
    }
}

// MARK: - Dismiss View Controllers
extension Navigator {
    
    func dismissViewControllers() {
        guard let dismissedVC = popStack(from: level) else { return }
        
        if dismissedVC._navigatorMode == .present {
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
        let vc = viewController.presentingViewController ?? viewController
        
        self.sendDataBeforeBack(dismissModel, level: level)
        
        vc.dismiss(animated: dismissAnimated, completion: {
            self.sendDataAfterBack(self.dismissModel)
            self.dismissCompletion?()
        })
    }
    
    func popViewController(_ viewController: UIViewController, fromNav: UINavigationController) {
        if fromNav.visibleViewController === viewController {
            self.sendDataBeforeBack(dismissModel, level: level)
            
            self.popTopViewController(fromNav: fromNav) {
                self.sendDataAfterBack(self.dismissModel)
            }
        } else {
            let presentingVC = presentingViewController(base: viewController, in: fromNav)
            
            self.sendDataBeforeBack(dismissModel, level: level)
            
            presentingVC.dismiss(animated: false, completion: {
                self.popTopViewController(fromNav: fromNav) {
                    self.sendDataAfterBack(self.dismissModel)
                }
            })
        }
    }
    
    func popTopViewController(fromNav: UINavigationController, completion: CompletionType) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { completion?() }
        
        if fromNav.viewControllers.contains(topViewController!) {
            fromNav.popToViewController(topViewController!, animated: dismissAnimated)
        } else {
            fromNav.popToRootViewController(animated: dismissAnimated)
        }
        
        CATransaction.commit()
    }
    
    func presentingViewController(base viewController: UIViewController, in navController: UINavigationController) -> UIViewController {
        let baseIndex = navController.viewControllers.index(of: viewController) ?? 0
        
        for (index, vc) in (navController.viewControllers as Array).enumerated() where index >= baseIndex && vc.presentedViewController != nil {
            return vc
        }
        
        return viewController
    }
}

// MARK: - Goto View Controller
extension Navigator {
    
    func gotoViewControllerIfExisted(_ vcName: String) -> Bool {
        guard self !== Navigator.root else {
            let viewControllers = Navigator.childViewControllers(of: self.rootViewController!)
            
            // NOTE: Method `String(describing:)` returned string always doesn't match with `vcName`
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == vcName })
            
            if let vc = viewController, let index = viewControllers.index(of: vc) {
                (rootViewController as? UITabBarController)?.selectedIndex = index
                return true
            }
            
            return false
        }
        
        guard let index = stackIndex(of: vcName) else { return false }
        if index+1 < stackCount {
            popStack(from: index+1)
        }
        
        let viewControllers = Navigator.childViewControllers(of: Navigator.root.rootViewController!)
        if let index = viewControllers.index(of: rootViewController!) {
            (rootViewController as? UITabBarController)?.selectedIndex = index
        }
        
        if let navControler = topViewController?.navigationController {
            navControler.popToViewController(topViewController!, animated: false)
        } else {
            topViewController?.dismiss(animated: false, completion: nil)
        }
        
        return true
    }
}

// MARK: - Send and Receive Data
extension Navigator {
    
    func p_sendDataBeforeShow(_ data: DataModel, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("🧭 Send data to %@ before show: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeShow?(data, fromViewController: fromVC)
    }
    
    func p_sendDataBeforeBack(_ data: DataModel, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("⬅️ Send data to %@ before before: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeBack?(data, fromViewController: fromVC)
    }
    
    func p_sendDataAfterBack(_ data: DataModel, toVC: UIViewController) {
        os_log("⬅️ Send data to %@ after before: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveAfterBack?(data, fromViewController: nil)
    }
}

// MARK: - Associated Properties
private extension UIViewController {
    var _navigatorMode: Navigator.Mode {
        get {
            let rawValue = objc_getAssociatedObject(self, &AssociationKey.navigatorMode) as! Int
            return Navigator.Mode(rawValue: rawValue)!
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorMode, newValue.rawValue as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var _navigatorTransition: Transition? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigatorTransition) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorTransition, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
