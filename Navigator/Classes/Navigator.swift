//
//  Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import os.log

@objc public class Navigator: NSObject {
    
    /// Use root navigator to open the initial view controller when App launch
    /// Also can use it to open any view controller for quick launch and debug, only need provide VC required data.
    @objc public static let root = Navigator()
    
    /// Use current navigator to open a universal link or deep link, append current page directly.
    @objc public static var current: Navigator {
        if let tabVC = _current.topViewController?.tabBarController {
            if let splitVC = tabVC.selectedViewController as? UISplitViewController {
                return splitVC.viewControllers.last?.navigator ?? _current
            } else {
                return tabVC.selectedViewController?.navigator ?? _current
            }
        } else if let splitVC = _current.topViewController?.splitViewController {
            return splitVC.viewControllers.last?.navigator ?? _current
        } else {
            return _current
        }
    }
    internal static var _current = root
    
    /// NOTE: Must set the window variable first, then call navigator's show method.
    @objc public weak var window: UIWindow?
    @objc internal weak var rootViewController: UIViewController? {
        willSet {
            window?.rootViewController = newValue
            window?.makeKeyAndVisible()
        }
    }
    
    @objc public init(rootViewController: UIViewController? = nil) {
        super.init()
        
        if let vc = rootViewController {
            pushStack(vc)
            self.rootViewController = vc
        }
    }
    
    public typealias CompletionBlock = (() -> Void)
    
    // Private Properties
    var stack: NSMapTable<NSNumber, UIViewController> = NSMapTable.weakToWeakObjects()
    var showAnimated: Bool = true
    var dismissAnimated: Bool = true
    var showCompletion: CompletionBlock?
    var dismissCompletion: CompletionBlock?
    
    weak var showModel: DataModel?
    weak var dismissModel: DataModel?
    
    /// Dismiss which level view controller, level 0 means that dismiss current view controller, level 1 is previous VC. (Default is 0)
    var level: Int = 0
}

public extension Navigator {
    
    /// Show a view controller with required data in dictionary.
    /// Build a linked node with data to handle universal link or deep link (A => B => C => D)
    /// - Note:
    ///   If the view controller is swift class, must add module name as prefix for class name.
    ///
    /// - Parameters:
    ///   - data: The data is required for view controller, can be any type. At least VC class name is required.
    ///   - animated: Whether show view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func show(_ data: DataModel, animated: Bool = true, completion: CompletionBlock? = nil) {
        Navigator._current = self
        
        showModel = data
        showAnimated = animated
        showCompletion = completion
        
        if data.next != nil && data.mode == .reset {
            showDeepLinkViewControllers(data)
        } else {
            showViewControllers()
        }
    }
    
    /// Dismiss any view controller with optional data in dictionary.
    /// (A => B => C => D) -> dismiss(level: 1) -> (A => B)
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous view controller, default is empty.
    ///   - level: Which view controller will be dismissed, default 0 is current VC, 1 is previous one VC.
    ///            If level is equal to -1, it will dimisss to root view controller of current navigator.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc func dismiss(_ data: DataModel? = nil, level: Int = 0, animated: Bool = true, completion: CompletionBlock? = nil) {
        self.level = level
        dismissModel = data
        dismissAnimated = animated
        dismissCompletion = completion
        
        dismissViewControllers()
    }
    
    /// Send data to previous any page before current page dismissed.
    /// The level parameter is same with dismiss method's level parameter.
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous any view controller.
    ///   - level: Send data to which view controller, default 0 is current VC, 1 is previous one VC.
    ///            If level is equal to -1, it will send data to root view controller of current navigator.
    @objc func sendDataBeforeBack(_ data: DataModel?, level: Int = 0) {
        self.level = level

        let lvl = level >= 0 ? level : stackCount + level - 1
        guard let data = data, let poppedVC = popStack(from: lvl) else { return }
        
        let toVC = topViewController ?? poppedVC
        p_sendDataBeforeBack(data, fromVC: poppedVC, toVC: toVC)
        
        pushStack(poppedVC)
    }
    
    /// Send data to previous one page after current page dismissed.
    /// If current page is already dismissed, only send data to previous one page, so can't assign level.
    /// In iOS, user can pop view controller by swipe to right on left screen edge. But can't catch the event.
    /// For this edge case, we can call this method in deinit() to solve data passing issue.
    ///
    /// - Parameter data: The data is passed to previous view controller.
    @objc func sendDataAfterBack(_ data: DataModel?) {
        guard let data = data else { return }
        guard let toVC = topViewController else { return }
        
        p_sendDataAfterBack(data, toVC: toVC)
    }
    
    /// Jump to any view controller only if the vc is already in the navigator stack.
    /// Can jump to another navigator's VC from one navigator. (e.g. jump to any tab in UITabBarController)
    ///
    /// - Parameter vcName: The view controller class name. If it is swift class, must add module name as prefix for class name.
    @objc class func goto(viewController vcName: String) {
        guard let rootVC = root.rootViewController, !root.gotoViewControllerIfExisted(vcName) else { return }
        
        let viewControllers = childViewControllers(of: rootVC)
        
        for vc in viewControllers where vc.navigator != nil {
            if vc.navigator!.gotoViewControllerIfExisted(vcName) {
                break
            }
        }
    }
}

// MARK: - Navigator Mode
public extension Navigator {
    
    @objc(NavigatorMode)
    enum Mode: Int, CustomStringConvertible {
        /// Reset view controller stack when initialize a new VC or deep link
        case reset
        case push
        case present
        // The presentationStyle must be forced with `custom` when mode is overlay
        case overlay
        
        public var description: String {
            switch self {
            case .reset: return "reset"
            case .push: return "push"
            case .present: return "present"
            case .overlay: return "overlay"
            }
        }
    }
}
