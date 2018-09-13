//
//  Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import os.log

// MARK: - PUBLIC -
@objc public class Navigator: NSObject {
    
    /// Use root navigator to open the initial view controller when App launch
    /// Also can use it to open any view controller for quick launch and debug, only need provide VC required data.
    @objc public static let root = Navigator()
    
    /// Use current navigator to open a universal link or deep link, append current page directly.
    @objc public class var current: Navigator {
        if let tabVC = _current.topViewController?.tabBarController {
            return tabVC.selectedViewController?.navigator ?? _current
        } else {
            return _current
        }
    }
    private static var _current = root
    
    /// NOTE: Must set the window variable first, then call navigator's show method.
    @objc public weak var window: UIWindow?
    @objc private(set) weak var rootViewController: UIViewController? {
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
        
        self.showData = data
        self.showAnimated = animated
        self.showCompletion = completion
        
        if self === Navigator.root && showModel.mode == .reset {
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
    ///   - animated: Whether dismiss view controller with animation, default is true.
    ///   - completion: The optional callback to be executed after animation is completed.
    @objc public func dismiss(_ data: DataDictionary = [:], level: Int = 0, animated: Bool = true, completion: CompletionType = nil) {
        self.level = level
        self.dismissData = data
        self.dismissAnimated = animated
        self.dismissCompletion = completion
        
        dismissViewControllers()
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
    private var stack: NSMapTable<NSNumber, UIViewController> = NSMapTable.weakToWeakObjects()
    private var showAnimated: Bool = true
    private var dismissAnimated: Bool = true
    private var showCompletion: CompletionType = nil
    private var dismissCompletion: CompletionType = nil
    private var showModel: DataModel!
    private var dismissModel: DataModel!
    /// Dismiss which level view controller, level 0 means that dismiss current view controller, level 1 is previous VC. (Default is 0)
    private var level: Int = 0
    
    private var showData: DataDictionary = [:] {
        didSet {
            showModel = dataModelFromDictionay(showData)
        }
    }
    private var dismissData: DataDictionary = [:] {
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
        
        /// See **UIModalTransitionStyle**. If has transition class, ignore the style.
        @objc public static let transitionStyle = "_transitionStyle"
        
        /// See **UIModalPresentationStyle**. If style is *UIModalPresentationCustom*,
        /// need pass a transition class which creates a custom presentation view controller.
        @objc public static let presentationStyle = "_presentationStyle"
        
        /// Transition class name for custom transition animation
        @objc public static let transitionName = "_transitionName"
        
        /// See **Navigator.Mode**
        @objc public static let mode = "_mode"
        
        /// Navigation or view controller's title
        @objc public static let title = "_title"
        
        /// If `presentationStyle` is **UIModalPresentationPopover**, at least pass one of below two parameters.
        @objc public static let sourceView = "_sourceView"  // UIView instance
        @objc public static let sourceRect = "_sourceRect"
        
        /// Fallback view controller will show if no VC found (like 404 Page)
        @objc public static let fallback = "_fallback"
        
        /// Provide a data provider class to mock data
        @objc public static let dataProvider = "_dataProvider"
        
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


// MARK: - PRIVATE -
private extension UIViewController {
    @objc var _navigatorMode: Navigator.Mode {
        get {
            let rawValue = objc_getAssociatedObject(self, &AssociationKey.navigatorMode) as! Int
            return Navigator.Mode(rawValue: rawValue)!
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorMode, newValue.rawValue as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc var _navigatorTransition: Transition? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigatorTransition) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorTransition, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private extension Navigator {
    
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
private extension Navigator {
    
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
            if let splitVC = topViewController?.splitViewController {
                splitVC.showDetailViewController(toVC, sender: nil)
            }
            popStackAll()
            setupNavigatorForViewController(toVC)
        }
        
        if rootViewController == nil {
            showModel.mode = .reset
            rootViewController = toVC
        }
        
        viewController._navigatorMode = showModel.mode
        pushStack(viewController)
        
        return true
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
private extension Navigator {
    
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
private extension Navigator {
    
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
private extension Navigator {
    
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
