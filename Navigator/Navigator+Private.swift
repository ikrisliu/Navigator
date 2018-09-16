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
    
    struct DataModel {
        var vcName: String?
        var navName: String?
        var mode: Navigator.Mode = .push
        var transitionStyle: UIModalTransitionStyle = .coverVertical
        var presentationStyle: UIModalPresentationStyle = .fullScreen
        var transitionName: String?
        var sourceView: UIView?
        var sourceRect: CGRect?
        var fallback: String?
        var children: [DataDictionary] = []
    }
    
    var stackCount: Int {
        return stack.dictionaryRepresentation().count
    }
    
    var topViewController: UIViewController? {
        return stackCount > 0 ? stack.object(forKey: (stackCount - 1) as NSNumber) : nil
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
        for key in index..<stackCount {
            stack.removeObject(forKey: key as NSNumber)
        }
        return poppedVC
    }
    
    @discardableResult
    func popStackAll() -> UIViewController? {
        return popStack(from: stackCount-1)
    }
    
    // Convert passed data dictionary to data model
    func dataModelFromDictionay(_ dictionary: DataDictionary) -> DataModel {
        var dataModel = DataModel()
        dataModel.fallback = dictionary[ParamKey.fallback] as? String
        dataModel.vcName = dictionary[ParamKey.viewControllerName] as? String ?? dataModel.fallback
        dataModel.navName = dictionary[ParamKey.navigationCtrlName] as? String
        dataModel.transitionName = dictionary[ParamKey.transitionName] as? String
        dataModel.transitionStyle = dictionary[ParamKey.transitionStyle] as? UIModalTransitionStyle ?? dataModel.transitionStyle
        dataModel.presentationStyle = dictionary[ParamKey.presentationStyle] as? UIModalPresentationStyle ?? dataModel.presentationStyle
        dataModel.sourceView = dictionary[ParamKey.sourceView] as? UIView
        dataModel.sourceRect = dictionary[ParamKey.sourceRect] as? CGRect
        
        if let mode = dictionary[ParamKey.mode] {
            dataModel.mode = mode is NSNumber ? Mode(rawValue: (mode as! NSNumber).intValue)! : mode as! Mode
        }
        
        if let children = dictionary[ParamKey.children] as? [DataDictionary] {
            dataModel.children = children
        } else if let vcNames = dictionary[ParamKey.children] as? [String] {
            dataModel.children = vcNames.map({ [ParamKey.viewControllerName: $0] as DataDictionary })
        }
        
        return dataModel
    }
}

// MARK: - Show View Controllers
extension Navigator {
    
    func showViewControllers() {
        let viewController = createViewController(showModel)
        guard !showTabBarControlerIfExisted(viewController) else { return }
        guard !showSplitViewControllerIfExisted(viewController) else { return }
        guard !showNavigationControlerIfExisted(viewController) else { return }
        guard !showViewControler(viewController) else { return }
    }
    
    func showTabBarControlerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let tabVC = viewController as? UITabBarController else { return false }
        addChildViewControllersIfExisted(showModel.children, toViewController: tabVC)
        return showViewControler(viewController)
    }
    
    func showSplitViewControllerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let splitVC = viewController as? UISplitViewController else { return false }
        addChildViewControllersIfExisted(showModel.children, toViewController: splitVC)
        return showViewControler(viewController)
    }
    
    func showNavigationControlerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let navVC = viewController as? UINavigationController else { return false }
        addChildViewControllersIfExisted(showModel.children, toViewController: navVC)
        return showViewControler(viewController)
    }
    
    // Deep Link
    func showDeepLinkViewControllers(_ data: DataDictionary) {
        guard let topVC = topViewController else { return }
        if topVC is UITabBarController || topVC is UISplitViewController {
            let viewControllers = Navigator.childViewControllers(of: topVC)
            let viewController: UIViewController? = viewControllers.filter({ NSStringFromClass(type(of: $0)) == showModel.vcName }).first
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
        
        var next: DataDictionary? = data
        while let nextData = next {
            let dataModel = dataModelFromDictionay(nextData)
            let viewController = createViewController(dataModel)
            p_showViewControler(viewController, data: nextData, animated: nextData.next == nil)
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
        return p_showViewControler(viewController, data: showData, animated: showAnimated)
    }
    
    @discardableResult
    func p_showViewControler(_ viewController: UIViewController, data: DataDictionary, animated: Bool) -> Bool {
        let dataModel = dataModelFromDictionay(data)
        let toVC = viewController.navigationController ?? viewController
        
        // Must set presentation style first for `UIModalPresentationStylePopover`
        toVC.modalPresentationStyle = dataModel.presentationStyle
        p_sendDataBeforeShow(data, fromVC: topViewController, toVC: viewController)
        
        switch dataModel.mode {
        case .push:
            setupTransition(dataModel, for: topViewController?.navigationController)
            topViewController?.navigationController?.pushViewController(toVC, animated: animated)
        case .present:
            setupTransition(dataModel, for: toVC.navigationController ?? toVC)
            topViewController?.present(toVC, animated: animated, completion: nil)
        case .reset:
            resetViewController(toVC)
        }
        
        if rootViewController == nil {
            showModel.mode = .reset
            rootViewController = toVC
        }
        
        viewController._navigatorMode = showModel.mode
        pushStack(viewController)
        
        return true
    }
    
    func resetViewController(_ viewController: UIViewController) {
        guard let splitVC = topViewController?.splitViewController else {
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
        if let name = dataModel.transitionName, !name.isEmpty, let vc = viewController {
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
            viewController?.popoverPresentationController?.sourceRect = sourceRect
        }
    }
    
    // Create view controller with class name. If need embed it into navigation controller, create one with view controller.
    func createViewController(_ dataModel: DataModel) -> UIViewController {
        var viewController: UIViewController!
        defer {
            if let navName = dataModel.navName, !navName.isEmpty {
                if let navType = NSClassFromString(navName) as? UINavigationController.Type {
                    let navigationController = navType.init()
                    navigationController.viewControllers = [viewController]
                    navigationController.navigator = self
                } else {
                    os_log("ZZZ: Can not find navigation controller class %@ in your modules", navName)
                }
            }
        }
        
        guard let vcName = dataModel.vcName, !vcName.isEmpty else {
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            os_log("ZZZ: Can not find view controller class %@ in your modules", vcName)
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
            os_log("ZZZ: Can not find transition class %@ in your modules", name)
            return nil
        }
        return type.init()
    }
    
    // Add child view controllers for container view controllers like Navigation/Split/Tab view controller
    func addChildViewControllersIfExisted(_ data: [DataDictionary], toViewController: UIViewController) {
        var viewControllers: [UIViewController] = []
        
        for item in data {
            let dataModel = dataModelFromDictionay(item)
            let toVC = createViewController(dataModel)
            p_sendDataBeforeShow(item, fromVC: toViewController, toVC: toVC)
            viewControllers.append(toVC.navigationController ?? toVC)
            
            if !dataModel.children.isEmpty {
                addChildViewControllersIfExisted(dataModel.children, toViewController: toVC)
            }
        }
        
        guard !viewControllers.isEmpty else { return }
        
        for (idx, vc) in viewControllers.enumerated() {
            let childVC = (vc as? UINavigationController)?.topViewController ?? vc
            
            let navigator = Navigator()
            navigator.setupNavigatorForViewController(vc)
            navigator.pushStack(childVC)
            
            if (idx == 0) {
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
        self.sendDataBeforeBack(dismissData, level: level)
        vc.dismiss(animated: dismissAnimated, completion: {
            self.sendDataAfterBack(self.dismissData)
            self.dismissCompletion?()
        })
    }
    
    func popViewController(_ viewController: UIViewController, fromNav: UINavigationController) {
        if fromNav.visibleViewController === viewController {
            self.sendDataBeforeBack(dismissData, level: level)
            self.popTopViewController(fromNav: fromNav) {
                self.sendDataAfterBack(self.dismissData)
            }
        } else {
            let presentingVC = presentingViewController(base: viewController, in: fromNav)
            self.sendDataBeforeBack(dismissData, level: level)
            presentingVC.dismiss(animated: false, completion: {
                self.popTopViewController(fromNav: fromNav) {
                    self.sendDataAfterBack(self.dismissData)
                }
            })
        }
    }
    
    func popTopViewController(fromNav: UINavigationController, completion:CompletionType) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { completion?() }
        fromNav.popToViewController(topViewController!, animated: dismissAnimated)
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
            let viewController = viewControllers.filter({ NSStringFromClass(type(of: $0)) == vcName }).first
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
    
    func p_sendDataBeforeShow(_ data: DataDictionary, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("ZZZ: Send data to %@ before show: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeShow?(data, fromViewController: fromVC)
    }
    
    func p_sendDataBeforeBack(_ data: DataDictionary, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("ZZZ: Send data to %@ before before: %@", toVC, data)
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeBack?(data, fromViewController: fromVC)
    }
    
    func p_sendDataAfterBack(_ data: DataDictionary, toVC: UIViewController) {
        os_log("ZZZ: Send data to %@ after before: %@", toVC, data)
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
