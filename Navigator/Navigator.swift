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
            return tabVC.selectedViewController?.navigator ?? _current
        } else {
            return _current
        }
    }
    internal static var _current = root
    
    /// NOTE: Must set the window variable first, then call navigator's show method.
    @objc public weak var window: UIWindow?
    @objc internal weak var rootViewController: UIViewController? {
        didSet {
            window?.rootViewController = rootViewController
            window?.makeKeyAndVisible()
        }
    }
    
    public typealias CompletionType = (() -> Void)?
    
    /// Show a view controller with required data in dictionary.
    /// Build a linked node with data to handle universal link or deep link (A => B => C => D)
    /// - Note:
    ///   If the view controller is swift class, must add module name as prefix for class name.
    ///
    /// - Parameters:
    ///   - data: The data is required for view controller, can be any type. At least VC class name is required.
    ///   - animated: Whether show view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc public func show(_ data: DataDictionary, animated: Bool = true, completion: CompletionType = nil) {
        Navigator._current = self
        
        showData = data
        showAnimated = animated
        showCompletion = completion
        
        if self === Navigator.root && showModel.mode == .reset {
            showDeepLinkViewControllers(data)
        } else {
            showViewControllers()
        }
        
        showData.removeAll()
    }
    
    /// Dismiss any view controller with optional data in dictionary.
    /// (A => B => C => D) -> dismiss(level: 1) -> (A => B)
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous view controller, default is empty.
    ///   - level: Which view controller will be dismissed, default 0 is current VC, 1 is previous one VC.
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc public func dismiss(_ data: DataDictionary = [:], level: Int = 0, animated: Bool = true, completion: CompletionType = nil) {
        self.level = level
        dismissData = data
        dismissAnimated = animated
        dismissCompletion = completion
        
        dismissViewControllers()
        
        dismissData.removeAll()
    }
    
    /// Send data to previous any page before current page dismissed.
    /// The level parameter is same with dismiss method's level parameter.
    ///
    /// - Parameters:
    ///   - data: The data is passed to previous any view controller.
    ///   - level: Send data to which view controller, default 0 is current VC, 1 is previous one VC.
    @objc public func sendDataBeforeBack(_ data: DataDictionary, level: Int = 0) {
        guard !data.isEmpty else { return }
        guard let poppedVC = popStack(from: level) else { return }
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
    @objc public func sendDataAfterBack(_ data: DataDictionary) {
        guard !data.isEmpty else { return }
        guard let toVC = topViewController else { return }
        p_sendDataAfterBack(data, toVC: toVC)
    }
    
    /// Jump to any view controller only if the vc is already in the navigator stack.
    /// Can jump to another navigator's VC from one navigator. (e.g. jump to any tab in UITabBarController)
    ///
    /// - Parameter vcName: The view controller class name. If it is swift class, must add module name as prefix for class name.
    @objc public class func goto(viewController vcName: String) {
        guard !root.gotoViewControllerIfExisted(vcName) else { return }
        
        let viewControllers = childViewControllers(of: root.rootViewController!)
        
        for vc in viewControllers where vc.navigator != nil {
            if vc.navigator!.gotoViewControllerIfExisted(vcName) {
                break
            }
        }
    }
    
    // Private Properties
    var stack: NSMapTable<NSNumber, UIViewController> = NSMapTable.weakToWeakObjects()
    var showAnimated: Bool = true
    var dismissAnimated: Bool = true
    var showCompletion: CompletionType = nil
    var dismissCompletion: CompletionType = nil
    var showModel: DataModel!
    var dismissModel: DataModel!
    /// Dismiss which level view controller, level 0 means that dismiss current view controller, level 1 is previous VC. (Default is 0)
    var level: Int = 0
    
    var showData: DataDictionary = [:] {
        didSet {
            showModel = dataModelFromDictionay(showData)
        }
    }
    var dismissData: DataDictionary = [:] {
        didSet {
            dismissModel = dataModelFromDictionay(dismissData)
        }
    }
}

// MARK: - Navigator Parameter Key
extension Navigator {
    
    @objc(NavigatorParamKey)
    public class ParamKey: NSObject {
        /// View controller class name (For swift, the class name should be "ModuleName.ClassName")
        @objc public static let viewControllerName = "_viewControllerName"
        
        /// Navigation controller class name (Used for embedding the view controller)
        @objc public static let navigationCtrlName = "_navigationCtrlName"
        
        /// See **Navigator.Mode**
        @objc public static let mode = "_mode"
        
        /// Navigation or view controller's title
        @objc public static let title = "_title"
        
        /// See **UIModalTransitionStyle**. If has transition class, ignore the style.
        @objc public static let transitionStyle = "_transitionStyle"
        
        /// See **UIModalPresentationStyle**. If style is *UIModalPresentationCustom*,
        /// need pass a transition class which creates a custom presentation view controller.
        @objc public static let presentationStyle = "_presentationStyle"
        
        /// Transition class name for custom transition animation
        @objc public static let transitionName = "_transitionName"
        
        /// If `presentationStyle` is **UIModalPresentationPopover**, at least pass one of below two parameters.
        @objc public static let sourceView = "_sourceView"  // UIView instance
        @objc public static let sourceRect = "_sourceRect"
        
        /// Fallback view controller will show if no VC found (like 404 Page)
        @objc public static let fallback = "_fallback"
        
        /// Provide a data provider class to mock data
        @objc public static let dataProvider = "_dataProvider"
        
        /// Additional data for passing to previous or next view controller. Pass tuple for mutiple values.
        @objc public static let additionalData = "_additionalData"
        
        /// Can be a list of VC names, also can nest a series of VCs with required data
        @objc public static let children = "_children"
    }
}

// MARK: - Navigator Mode
extension Navigator {
    
    @objc(NavigatorMode)
    public enum Mode: Int {
        case push
        case present
        /// Reset view controller stack when initialize a new VC or deep link
        case reset
    }
}

// MARK: - Associated Property
/// Add a navigator variable for each view controller(VC) instance. So VC can open other VCs by navigator to decouple.
///   - If the VC is instantiated and opened by navigator, it can use navigator to open other VCs.
///   - If the VC is instantiated and opened by old way(push/present), the navigator will be nil, can't use navigator to open other VCs.
extension UIViewController {
    
    enum AssociationKey {
        static var navigator: UInt8 = 0
        static var navigatorMode: UInt8 = 0
        static var navigatorTransition: UInt8 = 0
    }
    
    @objc public var navigator: Navigator? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigator) as? Navigator
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
