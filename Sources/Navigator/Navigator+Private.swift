//
//  Navigator+Private.swift
//  Navigator
//
//  Created by Kris Liu on 2018/9/14.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit
import os.log

// MARK: - Page Stack
extension Navigator {
    var stackCount: Int { stack.count }
    
    var navigationController: UINavigationController? {
        if let navigationController = topViewController?.navigationController {
            return navigationController
        }
        
        for _ in 0..<stackCount {
            popStack()
            if let navigationController = topViewController?.navigationController {
                return navigationController
            }
        }
        return nil
    }
    
    func pushStack(_ viewController: UIViewController) {
        stack = stack.filter({ $0.viewController != nil })
        stack.insert(WeakWrapper(viewController), at: 0)
    }
    
    // Pop stack level (0 from top)
    @discardableResult func popStack(from level: Int = 0) -> UIViewController? {
        let viewControllers = getStack(from: level)
        stack.removeFirst(viewControllers.count)
        return viewControllers.last
    }
    
    func getStack(from level: Int = 0) -> [UIViewController] {
        let index = level >= 0 ? level + 1 : max(stackCount + level, 0)
        guard index <= stackCount else { return [] }
        
        return stack.prefix(max(index, 0)).compactMap({ $0.viewController })
    }
    
    @discardableResult
    func popStackAll() -> UIViewController? {       // Including root vc
        return popStack(from: stackCount - 1)
    }
    
    // Calculate stack level (0 from bottom) according to dismiss level (0 from top)
    func stackIndex(of viewController: UIViewController) -> Int? {
        stack.map({ $0.viewController }).firstIndex(of: viewController)
    }
    
    func stackIndex(of vcName: String) -> Int? {
        stack.lastIndex(where: { NSStringFromClass(type(of: $0.viewController as AnyObject)) == vcName })
    }
    
    // Calculate dismiss level according to stack index for `backTo` method
    func stackLevel(_ index: Int) -> Int? {
        let level = index - 1   // Exclude the backTo target VC
        return (level >= 0 && index <= stackCount - 1) ? level : nil
    }
    
    var stackLevelForTopPresentedVC: Int? {
        for idx in (0..<stackCount) {
            if let vc = getStack(from: idx).last, (vc.isDismissable || vc.navigationController?.isDismissable == true) {
                return idx
            }
        }
        return nil
    }
}

// MARK: - Show View Controllers
extension Navigator {
    func showViewControllers(completion: CompletionBlock?) {
        guard let page = showingPage else { return }
        
        let viewController = createViewController(page)
        guard !showTabBarControlerIfExisted(viewController, completion: completion) else { return }
        guard !showSplitViewControllerIfExisted(viewController, completion: completion) else { return }
        guard !showNavigationControlerIfExisted(viewController, completion: completion) else { return }
        guard !showViewControler(viewController, completion: completion) else { return }
    }
    
    func showTabBarControlerIfExisted(_ viewController: UIViewController, completion: CompletionBlock?) -> Bool {
        guard let page = showingPage else { return false }
        guard let tabVC = viewController as? UITabBarController else { return false }
        
        addChildViewControllersIfExisted(page.children, toViewController: tabVC)
        return showViewControler(viewController, completion: completion)
    }
    
    func showSplitViewControllerIfExisted(_ viewController: UIViewController, completion: CompletionBlock?) -> Bool {
        guard let page = showingPage else { return false }
        guard let splitVC = viewController as? UISplitViewController else { return false }
        
        addChildViewControllersIfExisted(page.children, toViewController: splitVC)
        return showViewControler(viewController, completion: completion)
    }
    
    func showNavigationControlerIfExisted(_ viewController: UIViewController, completion: CompletionBlock?) -> Bool {
        guard let page = showingPage else { return false }
        guard let navVC = viewController as? UINavigationController else { return false }
        
        addChildViewControllersIfExisted(page.children, toViewController: navVC)
        return showViewControler(viewController, completion: completion)
    }
    
    // Deep Link
    func showDeepLinkViewControllers(_ page: PageObject) {
        self.showingPage = page
        
        guard let topVC = topViewController else {
            showViewControllers(completion: nil)
            if let next = page.next {
                Navigator.root.showDeepLinkViewControllers(next)
            }
            return
        }
        
        if topVC is UITabBarController || topVC is UISplitViewController {
            guard var next = page.next else { return }
            let viewControllers = Navigator.childViewControllers(of: topVC)
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == next.vcName.rawValue })
            
            if let vc = viewController, let index = viewControllers.firstIndex(of: vc) {
                if let tabVC = topVC as? UITabBarController {
                    tabVC.selectedIndex = index
                } else if let nextData = next.next {    // For handling split view controller logic
                    next = nextData
                }
                vc.navigator?.showDeepLinkViewControllers(next)
            } else {
                os_log("❌ [Navigator]: Build wrong navigation vc <%@> stack", next.vcName)
            }
            return
        }
        
        if self == Navigator.root {
            Navigator.current.backToRoot(animated: false)
        }
        
        var next: PageObject? = page
        while let nextPage = next {
            let viewController = createViewController(nextPage)
            p_showViewControler(viewController, page: nextPage, animated: nextPage.next == nil, completion: nil)
            next = nextPage.next
        }
    }
    
    static func childViewControllers(of viewController: UIViewController) -> [UIViewController] {
        var viewControllers: [UIViewController] = []
        
        if let tabVC = viewController as? UITabBarController {
            viewControllers = tabVC.viewControllers ?? []
        } else if let splitVC = viewController as? UISplitViewController {
            viewControllers = splitVC.viewControllers
        }
        
        return viewControllers.map({ ($0 as? UINavigationController)?.viewControllers.first ?? $0 })
    }
    
    // Show view controller by push or present way. If mode is root, show the view controller directly.
    func showViewControler(_ viewController: UIViewController, completion: CompletionBlock?) -> Bool {
        guard let page = showingPage else { return false }
        return p_showViewControler(viewController, page: page, animated: showAnimated, completion: completion)
    }
    
    @discardableResult
    func p_showViewControler(_ viewController: UIViewController, page: PageObject, animated: Bool, completion: CompletionBlock?) -> Bool {
        let toVC = viewController.navigationController ?? viewController
        
        // Must set presentation style first for `UIModalPresentationStylePopover`
        toVC.modalPresentationStyle = page.presentationStyle
        passPageObject(page, fromVC: topViewController, toVC: viewController)
        sendDataBeforeShow(page.extraData, fromVC: topViewController, toVC: viewController)
        
        switch page.mode {
        case .reset:
            resetViewController(toVC, completion: completion)
        case .push:
            setupTransition(page, for: topViewController?.navigationController)
            navigationController?.pushViewController(toVC, animated: animated, completion: completion)
        case .present:
            setupTransition(page, for: toVC)
            topViewController?.present(toVC, animated: animated, completion: completion)
        case .customPush:
            toVC.modalPresentationStyle = viewController.hidesBottomBarWhenPushed ? .fullScreen : .currentContext
            setupTransition(page, for: toVC)
            // NOTE: Always set the animated with true, otherwise, no interactive gesture will be added to presented VC.
            // (If passed in animated parameter is false, PushTransition's animation duration will be close to zero.)
            topViewController?.present(toVC, animated: true, completion: completion)
        case .overlay, .popover:
            if page.transitionClass == nil {
                page.transitionClass = page.mode == .popover ? FadeTransition.self : Transition.self
            }
            setupTransition(page, for: toVC)
            toVC.modalPresentationStyle = .custom
            topViewController?.present(toVC, animated: animated, completion: completion)
        case .goto:
            assertionFailure("Please call navigator `goto` method for showing <\(page.vcName)>")
            return false
        }
        
        if rootViewController == nil {
            showingPage?.mode = .reset
            rootViewController = toVC
        }
        
        pushStack(viewController)
        
        return true
    }
    
    func resetViewController(_ viewController: UIViewController, completion: CompletionBlock?) {
        if let splitVC = topViewController?.splitViewController, splitVC.viewControllers.count > 1 {   // iPad
            splitVC.showDetailViewController(viewController, sender: nil)
        } else {
            window = Navigator.root.window
        }
        
        popStackAll()
        setupNavigatorForViewController(viewController)
        completion?()
    }
    
    // Set custom tranistion animation when push or present a view controller
    func setupTransition(_ page: PageObject, for viewController: UIViewController?) {
        if let transitionClass = page.transitionClass, let vc = viewController {
            vc.p_navigatorTransition = transitionClass.init()
            
            if var sourceRect = page.sourceRect {
                let width = vc.view.bounds.width
                let height = vc.view.bounds.height
                
                switch page.mode {
                case .overlay:  // origin from bottom
                    sourceRect = CGRect(x: 0, y: height - sourceRect.height, width: width, height: sourceRect.height)
                case .popover:  // origin from center
                    if sourceRect.origin == .zero {
                        sourceRect.origin = CGPoint(x: (width - sourceRect.width) / 2, y: (height - sourceRect.height) / 2)
                    }
                case .reset, .goto, .push, .present, .customPush:
                    break
                }
                
                vc.p_navigatorTransition?.sourceRect = sourceRect
            }
            
            if let nav = vc as? UINavigationController, page.mode == .push {
                nav.delegate = vc.p_navigatorTransition
            } else {
                vc.transitioningDelegate = vc.p_navigatorTransition
            }
        } else {
            viewController?.modalTransitionStyle = page.transitionStyle
        }
        
        guard page.presentationStyle == .popover else { return }
        
        viewController?.popoverPresentationController?.sourceView = page.sourceView
        if let sourceRect = page.sourceRect {
            viewController?.popoverPresentationController?.sourceRect = sourceRect
        }
    }
    
    // Create view controller with class name. If need embed it into navigation controller, create one with view controller.
    func createViewController(_ page: PageObject) -> UIViewController {
        let viewController: UIViewController
        
        defer {
            if let navName = page.navName?.rawValue, !navName.isEmpty, !(viewController is UINavigationController) {
                if let navType = NSClassFromString(navName) as? UINavigationController.Type {
                    let navigationController = navType.init()
                    navigationController.viewControllers = [viewController]
                    navigationController.navigator = self
                } else {
                    os_log("❌ [Navigator]: Can not find navigation controller class %@ in your modules", navName)
                }
            }
        }
        
        if let creator = page.vcCreator {
            viewController = creator()
        } else {
            let vcName = page.vcName.rawValue
            guard !vcName.isEmpty else {
                viewController = createFallbackViewController(page)
                return viewController
            }
            guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
                os_log("❌ [Navigator]: Can not find view controller class %@ in your modules", vcName)
                viewController = createFallbackViewController(page)
                return viewController
            }
            viewController = vcType.init()
        }
        
        viewController.navigator = self
        viewController.pageObject = page
        viewController.navigationMode = page.mode
        
        return viewController
    }
    
    // Create fallback view controller instance with class name.
    func createFallbackViewController(_ page: PageObject) -> UIViewController {
        guard let vcType = page.fallback else {
            let viewController = Fallback()
            viewController.navigator = self
            return viewController
        }
        
        let viewController = vcType.init()
        viewController.navigator = self
        
        return viewController
    }
    
    // Add child view controllers for container view controllers like Navigation/Split/Tab view controller
    func addChildViewControllersIfExisted(_ pages: [PageObject]?, toViewController: UIViewController) {
        guard let pages = pages else { return }
        
        var viewControllers: [UIViewController] = []
        
        for page in pages {
            let toVC = createViewController(page)
            passPageObject(page, fromVC: toViewController, toVC: toVC)
            viewControllers.append(toVC.navigationController ?? toVC)
            
            if let children = page.children, !children.isEmpty {
                addChildViewControllersIfExisted(page.children, toViewController: toVC)
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
        viewController.navigationMode = .reset
        viewController.navigator = self
        viewController.navigationController?.navigator = self
        (viewController as? UINavigationController)?.topViewController?.navigator = self
    }
}

// MARK: - Dismiss View Controllers
extension Navigator {
    // Disallow dismiss the root view controller
    func dismissViewControllers(level: Int, completion: CompletionBlock?) {
        if level < 0 && (stackCount + level) <= 0 { return }
        
        let vcs = getStack(from: level).dropLast()  // Remove stack bottom element which needs dismiss with animation
        guard let dismissedVC = popStack(from: level) else { return }
        
        let animatedDismissClosure = {
            if dismissedVC.isDismissable {
                self.dismissViewController(dismissedVC, completion: completion)
            } else if let nav = dismissedVC.navigationController {
                self.popViewController(dismissedVC, fromNav: nav, completion: completion)
            } else {
                completion?()
            }
        }
        
        // NOTE: Bugfix for `backToRoot` method when multiple vcs used different `presentationStyle` on diff iOS system
        if let presentingVC = vcs.last(where: { $0.isFullScreenModalPresentationStyle })?.presentingViewController {
            presentingVC.dismiss(animated: false) {
                animatedDismissClosure()
            }
        } else {
            animatedDismissClosure()
        }
    }
    
    func dismissViewController(_ viewController: UIViewController, completion: CompletionBlock?) {
        let vc = viewController.presentingViewController ?? viewController
        
        // Do not call public method `sendDataBeforeBack` which will lead pop stack twice
        if let data = dismissingData, let topVC = topViewController {
            p_sendDataBeforeBack(data, fromVC: viewController, toVC: topVC)
        }
        
        vc.dismiss(animated: dismissAnimated, completion: {
            self.sendDataAfterBack(self.dismissingData)
            completion?()
        })
    }
    
    func popViewController(_ viewController: UIViewController, fromNav: UINavigationController, completion: CompletionBlock?) {
        if let data = dismissingData, let topVC = topViewController {
            p_sendDataBeforeBack(data, fromVC: viewController, toVC: topVC)
        }
        
        if let presentingVC = findPresentingViewController(base: viewController, in: fromNav) {
            presentingVC.dismiss(animated: false, completion: {
                self.popTopViewController(fromNav: fromNav) {
                    self.sendDataAfterBack(self.dismissingData)
                    completion?()
                }
            })
        } else {
            popTopViewController(fromNav: fromNav) {
                self.sendDataAfterBack(self.dismissingData)
                completion?()
            }
        }
    }
    
    func popTopViewController(fromNav: UINavigationController, completion: CompletionBlock?) {
        if let topVC = topViewController, fromNav.viewControllers.contains(topVC) {
            fromNav.popToViewController(topVC, animated: dismissAnimated, completion: completion)
        } else {
            fromNav.popToRootViewController(animated: dismissAnimated, completion: completion)
        }
    }
    
    func findPresentingViewController(base viewController: UIViewController, in navController: UINavigationController) -> UIViewController? {
        let baseIndex = navController.viewControllers.firstIndex(of: viewController) ?? 0
        return navController.viewControllers.suffix(navController.viewControllers.count - baseIndex).first(where: { $0.presentedViewController != nil })
    }
}

// MARK: - Goto View Controller
extension Navigator {
    func gotoViewControllerIfExisted(_ vcName: String, data: Any? = nil, animated: Bool = true) -> Bool {
        guard self !== Navigator.root else {
            guard let rootVC = rootViewController else { return false }
            
            let viewControllers = Navigator.childViewControllers(of: rootVC)
            // NOTE: Method `String(describing:)` returned string always doesn't match with `vcName`
            let viewController = viewControllers.first(where: { NSStringFromClass(type(of: $0)) == vcName })
            
            if let vc = viewController, let index = viewControllers.firstIndex(of: vc) {
                (rootVC as? UITabBarController)?.selectedIndex = index
                sendDataBeforeShow(data, fromVC: topViewController, toVC: vc)
                Navigator.current.backToRoot(animated: animated)
                return true
            } else {
                os_log("❌ [Navigator]: Can not find view controller class %@ in navigation stack", vcName)
                return false
            }
        }
        
        guard let rootVC = Navigator.root.rootViewController else { return false }
        
        let viewControllers = Navigator.childViewControllers(of: rootVC)
        if let rootVC = rootViewController, let index = viewControllers.firstIndex(of: rootVC),
            let selectedVC = (rootVC as? UITabBarController)?.selectedViewController {
            (rootVC as? UITabBarController)?.selectedIndex = index
            sendDataBeforeShow(data, fromVC: topViewController, toVC: selectedVC)
        }
        
        let previousTopVC = topViewController
        guard let index = stackIndex(of: vcName), index > 0 else { return false }
        guard let poppedVC = popStack(from: index - 1), let toVC = topViewController else { return false }
        
        if let navControler = toVC.navigationController {
            navControler.popToViewController(toVC, animated: animated)
        } else {
            poppedVC.dismiss(animated: animated, completion: nil)
        }
        
        sendDataBeforeShow(data, fromVC: previousTopVC, toVC: toVC)
        return true
    }
}

// MARK: - Send and Receive Data
extension Navigator {
    func passPageObject(_ page: PageObject, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("➡️ [Navigator]: Pass page object from %@ after init: %@", String(describing: fromVC), page)
        guard let navigatableVC = toVC as? Navigatable else { return }
        navigatableVC.onPageDidInitialize?(page, fromVC: fromVC)
    }
    
    func sendDataBeforeShow(_ data: Any?, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("➡️ [Navigator]: Send data from %@ before show: %@", String(describing: fromVC), "\(data ?? "nil")")
        guard let navigatableVC = toVC as? Navigatable else { return }
        navigatableVC.onDataReceiveBeforeShow?(data, fromVC: fromVC)
    }
    
    func p_sendDataBeforeBack(_ data: Any, fromVC: UIViewController?, toVC: UIViewController) {
        os_log("⬅️ [Navigator]: Send data from %@ before back: %@", String(describing: fromVC), "\(data)")
        guard let navigatableVC = toVC as? Navigatable else { return }
        navigatableVC.onDataReceiveBeforeBack?(data, fromVC: fromVC)
    }
    
    func p_sendDataAfterBack(_ data: Any, toVC: UIViewController) {
        os_log("⬅️ [Navigator]: Send data to %@ after back: %@", toVC, "\(data)")
        guard let navigatableVC = toVC as? Navigatable else { return }
        navigatableVC.onDataReceiveAfterBack?(data)
        
        self.dismissingData = nil  // Release reference
    }
}
