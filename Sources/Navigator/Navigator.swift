//
//  Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import os.log

@objc public class Navigator: NSObject {
    
    /// Use root navigator to open the initial view controller when App launch
    /// Also can use it to open any view controller for quick launch and debug, only need provide pageObject required data.
    @objc public static let root = Navigator()
    
    /// - Note: Only if open App via deep linking, use the current navigator. It will append new page to current vc stack.
    @objc public static var current: Navigator {
        var navigator = _current
        if let tabVC = _current.topViewController?.tabBarController {
            if let splitVC = tabVC.selectedViewController as? UISplitViewController {
                navigator = splitVC.viewControllers.last?.navigator ?? _current
            } else {
                navigator = tabVC.selectedViewController?.navigator ?? _current
            }
        } else if let splitVC = _current.topViewController?.splitViewController {
            navigator = splitVC.viewControllers.last?.navigator ?? _current
        }
        
        return navigator
    }
    internal static var _current = root
    
    /// - Note: Must set the window variable first, then call navigator's show method.
    @objc public weak var window: UIWindow? {
        willSet {
            // Make sure swizzle method only call once for working
            if self == Navigator.root && window != newValue {
                UIViewController.swizzleViewDidDisappear()
            }
        }
    }
    
    @objc public internal(set) weak var rootViewController: UIViewController? {
        willSet {
            // Avoid memory leak, if exists presented view controler, reset root view controller will lead memory lead.
            Navigator.current.backToRoot(animated: false)
            
            window?.rootViewController = newValue
            window?.makeKeyAndVisible()
        }
    }
    
    @objc public var viewControllers: [UIViewController] {
        stack.compactMap({ $0.viewController })
    }
    
    @objc public init(rootViewController: UIViewController? = nil) {
        super.init()
        
        if let vc = rootViewController {
            pushStack(vc)
            self.rootViewController = vc
        }
    }
    
    // Private Properties
    private var _stack = [WeakWrapper]()
    var stack: [WeakWrapper] {
        get { _stack.filter({ $0.viewController != nil }) }
        set { _stack = newValue }
    }
    
    var showAnimated: Bool = true
    var dismissAnimated: Bool = true
    
    weak var showingPage: PageObject?
    var dismissingData: PageBizData?
}

// MARK: - Show or Dismiss
public extension Navigator {
    
    typealias CompletionBlock = (() -> Void)
    
    /// Show a view controller with required page object.
    /// Build a linked node with page object to handle universal link or deep link (A => B => C => D)
    /// - Note:
    ///   If the view controller is swift class, must add module name as prefix for class name.
    ///
    /// - Parameters:
    ///   - page: The page object is required for view controller, at least VC class name is required.
    ///   - animated: Whether show view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func open(_ page: PageObject, animated: Bool = true, completion: CompletionBlock? = nil) {
        Navigator._current = self
        
        showingPage = page
        showAnimated = animated
        
        showViewControllers(completion: completion)
    }
    
    /// Dismiss the view controller which navigation mode is present with optional data.
    /// - Note: It's same with system view controller dismiss method.
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous view controller, default is nil.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func close(_ data: PageBizData? = nil, animated: Bool = true, completion: CompletionBlock? = nil) {
        guard stackCount > 1 else { return }
        
        dismissingData = data
        dismissAnimated = animated
        
        dismiss(data, animated: animated, completion: completion)
    }
    
    /// Dismiss view controllers with the specified view controller instance.
    ///
    /// - Parameters:
    ///   - viewController: The VC that you want to be at the top of the stack. This VC must currently be on the navigation stack.
    ///   - data: The data is passed to previous view controller, default is nil.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func backTo(viewController: UIViewController, data: PageBizData? = nil, animated: Bool = true, completion: CompletionBlock? = nil) {
        guard let index = stackIndex(of: viewController), let level = stackLevel(index) else { return }
        
        dismiss(data, level: level, animated: animated, completion: completion)
    }
    
    /// Dismiss view controllers until the specified VC is at the top of the navigation stack.
    /// If there are many view controllers that are same name in the stack, it will only dismiss the first one.
    ///
    /// - Parameters:
    ///   - vcName: The VC that you want to be at the top of the stack. This VC must currently be on the navigation stack.
    ///   - data: The data is passed to previous view controller, default is nil.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func backTo(vcName: UIViewController.Name, data: PageBizData? = nil, animated: Bool = true, completion: CompletionBlock? = nil) {
        guard let index = stackIndex(of: vcName.rawValue), let level = stackLevel(index) else { return }
        
        dismiss(data, level: level, animated: animated, completion: completion)
    }
    
    @objc func backTo(vcClass: UIViewController.Type, data: PageBizData? = nil, animated: Bool = true, completion: CompletionBlock? = nil) {
        backTo(vcName: .init(NSStringFromClass(vcClass)), data: data, animated: animated, completion: completion)
    }
    
    /// Dismiss all view controllers and back to the root view controller.
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous view controller, default is nil.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func backToRoot(data: PageBizData? = nil, animated: Bool = true, completion: CompletionBlock? = nil) {
        dismiss(data, level: -1, animated: animated, completion: completion)
    }
    
    /// Jump to any view controller only if the vc is already in the navigator stack.
    /// Can jump to another navigator's VC from one navigator. (e.g. jump to any tab in UITabBarController)
    ///
    /// - Parameters:
    ///   - vcName: The view controller class name. If it is swift class, must add module name as prefix for class name.
    ///   - data: The data is passed to target view controller, default is nil.
    ///   - animated: Whether show view controller with animation, default is true.
    @objc class func goto(vcName: UIViewController.Name, data: PageBizData? = nil, animated: Bool = true) {
        guard let rootVC = root.rootViewController, !root.gotoViewControllerIfExisted(vcName.rawValue, data: data) else { return }
        
        let viewControllers = childViewControllers(of: rootVC)
        
        for vc in viewControllers where vc.navigator != nil {
            if vc.navigator!.gotoViewControllerIfExisted(vcName.rawValue, data: data) {
                break
            }
        }
    }
    
    @objc class func goto(vcClass: UIViewController.Type, data: PageBizData? = nil, animated: Bool = true) {
        goto(vcName: .init(NSStringFromClass(vcClass)), data: data, animated: animated)
    }
}

private extension Navigator {
    
    /// Dismiss any view controller with optional data from level.
    /// (A => B => C => D) -> dismiss(level: 1) -> (A => B)
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous view controller, default is nil.
    ///   - level: Which view controller will be dismissed, default 0 is current VC, 1 is previous one VC.
    ///            If level is equal to -1, it will dimisss to root view controller of current navigator.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    func dismiss(_ data: PageBizData? = nil, level: Int = 0, animated: Bool = true, completion: CompletionBlock? = nil) {
        guard stackCount > 1 else { return }
        
        dismissingData = data
        dismissAnimated = animated
        
        dismissViewControllers(level: level, completion: completion)
    }
}

// MARK: - Deep Link
public extension Navigator {
    
    /// Deep link to a view controller with required page object.
    /// Build a linked node with page object to handle universal link or deep link (A => B => C => D)
    ///   - If use `Navigator.root.deepLink()`, it will build view controllers from root view controller, the mode should be `reset`.
    ///   - If use `Navigator.current.deepLink()`, it will show deep linking VCs base on current visible view controller.
    ///     If the mode is `goto`, should use `Navigator.current.deepLink()`.
    ///
    /// - Parameter page: The page object is required for view controller, at least VC class name is required.
    @objc func deepLink(_ page: PageObject) {
        guard topViewController?.ignoreDeepLinking == false else { return }
        
        if page.mode == .goto {
            if self != Navigator.current {
                assertionFailure("Should use `Navigator.current` to call this deep link method")
            }
            
            Navigator.goto(vcName: page.vcName, data: page.bizData, animated: false)
            
            if let nextPage = page.next {
                Navigator.current.showDeepLinkViewControllers(nextPage)
                nextPage.next = nil // Make sure linked all page objects free
            }
        } else {
            if (self == Navigator.root && page.mode != .reset) || (self != Navigator.root && page.mode == .reset) {
                assertionFailure("Should use `reset` mode when use `Navigator.root` call deep link method")
            }
            
            if page.next != nil {
                showDeepLinkViewControllers(page)
                page.next = nil
            } else {
                open(page)
            }
        }
    }

    typealias DeepLinkHandler = ((URL) -> PageObject?)
    
    /// Use this method to open the specified resource. If the specified URL scheme is handled by another app, iOS launches that app and passes the URL to it.
    ///
    /// - Parameters:
    ///   - url: The resource identified by this URL may be local to the current app or it may be one that must be provided by a different app.
    ///          UIKit supports many common schemes, including the http, https, tel, facetime, and mailto schemes.
    ///   - handler: The handler is for parsing the url and return a page object for navigator show. If handler is nil, will open URL by UIApplication.
    @objc func open(url: URL, handler: DeepLinkHandler? = nil) {
        if let handler = handler {
            if let page = handler(url) {
                self.deepLink(page)
            }
        } else {
            UIApplication.shared.open(url)
        }
    }
    
    /// Returns a Boolean value indicating whether an app is available to handle a URL scheme.
    @objc class func canOpenURL(_ url: URL) -> Bool {
        UIApplication.shared.canOpenURL(url)
    }
}

// MARK: - Send Data
public extension Navigator {
    
    /// Send business data to previous one page after current page dismissed.
    /// In iOS, user can pop view controller by swipe to right on left screen edge. But can't catch the touch event.
    /// For this edge case, we can call this method in `didBackOrClose` to solve data passing issue.
    /// - Note: If the `back` is system push back and call this method in `didBackOrClose`,
    /// the data sent target is current VC, not the previous VC, so need use `isSystemPushBack != true` to get the previous VC.
    ///
    /// - Parameter data: The data is passed to previous view controller.
    @objc func sendDataAfterBack(_ data: PageBizData) {
        guard let toVC = stack.first(where: { $0.viewController?.isSystemPushBack != true })?.viewController else { return }
        
        p_sendDataAfterBack(data, toVC: toVC)
    }
    
    @objc var topViewController: UIViewController? {
        stack.first?.viewController
    }
}

// MARK: - Navigator Mode
public extension Navigator {
    
    @objc(NavigatorMode)
    enum Mode: Int, CustomStringConvertible {
        /// Reset view controller stack when initialize a new VC or deep link
        case reset
        /// Change tab in tab controller
        case goto
        case push
        case present
        /// Add child view controller via `OverlayTransition` animation by default
        case overlay
        
        public var description: String {
            switch self {
            case .reset: return "reset"
            case .goto: return "goto"
            case .push: return "push"
            case .present: return "present"
            case .overlay: return "overlay"
            }
        }
    }
}

// MARK: - Weak Wrapper
class WeakWrapper {
    
    weak var viewController: UIViewController?
    
    init(_ viewController: UIViewController) {
        self.viewController = viewController
    }
}
