//
//  Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit

// MARK: - Public
// MARK: -
@objc open class NavigatorParametersKey: NSObject {
    /// View controller class name (For swift, the class name should be "ModuleName.ClassName")
    @objc public static let viewControllerName = "_viewControllerName"
    
    /// Navigation controller class name (Used for embedding the view controller)
    @objc public static let navigationCtrlName = "_navigationCtrlName"
    
    /// @see UIModalTransitionStyle, If has transition class, ignore the style.
    @objc public static let transitionStyle = "_transitionStyle"
    
    /// Transition class name for custom transition animation
    @objc public static let transitionName = "_transitionName"
    
    /// @see NavigatorMode
    @objc public static let mode = "_mode"
    
    /// Navigation or view controller's title
    @objc public static let title = "_title"
    
    /// Fallback view controller will show if no VC found (like 404 Page)
    @objc public static let fallback = "_fallback"
    
    /// Provide a data provider class to mock data
    @objc public static let dataProvider = "_dataProvider"
    
    /// Can be a list of VC names, also can nest a series of VCs with required data
    @objc public static let children = "_children"
}

@objc public enum NavigatorMode: Int {
    case push
    case present
    /// Reset view controller stack when initialize a new VC or deep link
    case reset
}

@objc open class Navigator: NSObject {
    
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
    
    /**
     * Show a view controler with required data in dictionary.
     * Build a linked node with data to handle universal link or deep link (A => B => C => D)
     * @param data The data is required for view controller, can be any type. At least VC class name is required.
     * @param animated Whether show view controller with animation, default is true
     * @param completion The optional callaback to be executed after animation is completed.
     */
    @objc open func show(_ data: DataDictionary, animated: Bool = true, completion: CompletionType = nil) {
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
    
    /**
     * Dismiss any view controler with optional data in dictionary.
     * (A => B => C => D) -> dismiss(level: 1) -> (A => B)
     * @param data Pass data to previous view controller, default is empty.
     * @param level Which view contoller will be dismissed, default 0 is current VC, 1 is previous one VC.
     * @param animated Whether dismiss view controller with animation, default is true
     * @param completion The optional callaback to be executed after animation is completed.
     */
    @objc open func dismiss(_ data: DataDictionary = [:], level: Int = 0, animated: Bool = true, completion: CompletionType = nil) {
        self.level = level
        self.dismissData = data
        self.dismissAnimated = animated
        self.dismissCompletion = completion
        
        dismissViewControllers()
    }
    
    /**
     * Send data to previous any page before current page dismissed.
     * The level paramater is same with dismiss method's level parameter.
     */
    @objc open func sendDataBeforeBack(_ data: DataDictionary, level: Int = 0) {
        guard let poppedVC = popStack(level) else { return }
        let toVC = topViewController ?? poppedVC
        _sendDataBeforeBack(data, fromVC: poppedVC, toVC: toVC)
        pushStack(poppedVC)
    }
    
    /**
     * Send data to previous one page after current page dismissed.
     * If current page is already dismissed, only send data to previous one page, so can't assign level.
     * In iOS, user can pop view controller by swipe to right on left screen edge. But can't catch the event.
     * For this edge case, we can call this method in deinit() to solve data passing issue.
     */
    @objc open func sendDataAfterBack(_ data: DataDictionary) {
        guard let toVC = topViewController else { return }
        _sendDataAfterBack(data, toVC: toVC)
    }
    
    // Private
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

// MARK: - Private
// MARK: -
private struct DataModel {
    var vcName: String?
    var navName: String?
    var mode: NavigatorMode = .push
    var transitionStyle: UIModalTransitionStyle = .coverVertical
    var transitionName: String?
    var fallback: String?
}

private var navigatorModeAssociationKey: UInt8 = 0
private var navigatorTransitionAssociationKey: UInt8 = 0

private extension UIViewController {
    @objc var navigatorMode: NavigatorMode {
        get {
            let rawValue = objc_getAssociatedObject(self, &navigatorModeAssociationKey) as! Int
            return NavigatorMode(rawValue: rawValue)!
        }
        set {
            objc_setAssociatedObject(self, &navigatorModeAssociationKey, newValue.rawValue as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc var navigatorTransition: Transition? {
        get {
            return objc_getAssociatedObject(self, &navigatorTransitionAssociationKey) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &navigatorTransitionAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

private extension Navigator {
    
    var stackCount: Int {
        return stack.dictionaryRepresentation().count
    }
    
    var topViewController: UIViewController? {
        return stackCount > 0 ? stack.object(forKey: (stackCount - 1) as NSNumber) : nil
    }
    
    func pushStack(_ viewController: UIViewController) {
        viewController.navigatorMode = showModel != nil ? showModel.mode : .reset
        stack.setObject(viewController, forKey: stackCount as NSNumber)
    }
    
    @discardableResult
    func popStack(_ level: Int = 0) -> UIViewController? {
        let index = max(stackCount - 1 - level, 0)
        guard index < stackCount else { return nil }
        
        let poppedVC = stack.object(forKey: index as NSNumber)
        for key in index..<stackCount where key > 0 {
            stack.removeObject(forKey: key as NSNumber)
        }
        return poppedVC
    }
    
    var children: [Any] {
        if let classNames = showData[NavigatorParametersKey.children] as? [String] {
            return classNames
        } else {
            return (showData[NavigatorParametersKey.children] as? [DataDictionary]) ?? []
        }
    }
    
    /// Convert passed data dictionary to data model
    func dataModelFromDictionay(_ dictionary: DataDictionary) -> DataModel {
        var dataModel = DataModel()
        dataModel.fallback = dictionary[NavigatorParametersKey.fallback] as? String
        dataModel.vcName = dictionary[NavigatorParametersKey.viewControllerName] as? String ?? dataModel.fallback
        dataModel.navName = dictionary[NavigatorParametersKey.navigationCtrlName] as? String
        dataModel.mode = dictionary[NavigatorParametersKey.mode] as? NavigatorMode ?? dataModel.mode
        dataModel.transitionStyle = dictionary[NavigatorParametersKey.transitionStyle] as? UIModalTransitionStyle ?? dataModel.transitionStyle
        dataModel.transitionName = dictionary[NavigatorParametersKey.transitionName] as? String
        return dataModel
    }
}

// MARK: - Show View Controllers
// MARK: -
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
        addChildViewControllersIfExisted(children, toViewController: tabVC)
        return showViewControler(viewController)
    }
    
    func showSplitViewControllerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let splitVC = viewController as? UISplitViewController else { return false }
        addChildViewControllersIfExisted(children, toViewController: splitVC)
        return showViewControler(viewController)
    }
    
    func showNavigationControlerIfExisted(_ viewController: UIViewController) -> Bool {
        guard let navVC = viewController as? UINavigationController else { return false }
        addChildViewControllersIfExisted(children, toViewController: navVC)
        return showViewControler(viewController)
    }
    
    /// Deep Link
    func showDeepLinkViewControllers(_ data: DataDictionary) {
        guard let topVC = topViewController else { return }
        if topVC is UITabBarController || topVC is UISplitViewController {
            let viewControllers = topVC is UITabBarController ? (topVC as! UITabBarController).viewControllers! : (topVC as! UISplitViewController).viewControllers
            let rootVC: UIViewController? = viewControllers.filter({ String(describing: $0) != showModel.vcName }).first
            if let rootVC = rootVC {
                (topVC as? UITabBarController)?.selectedIndex = viewControllers.index(of: rootVC) ?? 0
            }
            rootVC?.navigator?.showDeepLinkViewControllers(data)
            return
        }
        
        while stackCount > 1 {
            popStack()
        }
        
        if let navControler = topViewController?.navigationController {
            navControler.popToRootViewController(animated: false)
        } else {
            topViewController?.dismiss(animated: false, completion: nil)
        }
        
        var next: DataDictionary? = data
        while let nextData = next {
            let dataModel = dataModelFromDictionay(nextData)
            let viewController = createViewController(dataModel)
            _showViewControler(viewController, data: nextData, animated: nextData.next == nil)
            next = nextData.next
        }
    }
    
    /// Show view controller by push or present way. If mode is root, show the view controller directly.
    func showViewControler(_ viewController: UIViewController) -> Bool {
        return _showViewControler(viewController, data: showData, animated: showAnimated)
    }
    
    @discardableResult
    func _showViewControler(_ viewController: UIViewController, data: DataDictionary, animated: Bool) -> Bool {
        _sendDataBeforeShow(data, fromVC: topViewController, toVC: viewController)
        
        let dataModel = dataModelFromDictionay(data)
        let toVC = viewController.navigationController ?? viewController
        
        switch dataModel.mode {
        case .push:
            setupTransition(dataModel, for: topViewController?.navigationController)
            topViewController?.navigationController?.pushViewController(toVC, animated: animated)
        case .present:
            setupTransition(dataModel, for: toVC)
            topViewController?.present(toVC, animated: animated, completion: nil)
        default:
            break
        }
        
        if rootViewController == nil {
            showModel.mode = .reset
            rootViewController = toVC
        }
        pushStack(viewController)
        
        return true
    }
    
    /// Set custom tranistion animation when push or present a view controller
    func setupTransition(_ dataModel: DataModel, for viewController: UIViewController?) {
        if let name = dataModel.transitionName, !name.isEmpty, let vc = viewController {
            vc.navigatorTransition = createTransition(name)
            if vc is UINavigationController {
                (vc as! UINavigationController).delegate = vc.navigatorTransition
            } else {
                vc.transitioningDelegate = vc.navigatorTransition
            }
        } else {
            viewController?.modalTransitionStyle = dataModel.transitionStyle
        }
    }
    
    /// Create view controller with class name. If need embed it into navigation controller, create one with view controller.
    func createViewController(_ dataModel: DataModel) -> UIViewController {
        var viewController: UIViewController!
        defer {
            if let navName = dataModel.navName, !navName.isEmpty {
                if let navType = NSClassFromString(navName) as? UINavigationController.Type {
                    let navigationController = navType.init()
                    navigationController.viewControllers = [viewController]
                    navigationController.navigator = self
                } else {
                    print("ZZZ: Can not find navigation controller class \(navName) in your modules")
                }
            }
        }
        
        guard let vcName = dataModel.vcName, !vcName.isEmpty else {
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            print("ZZZ: Can not find view controller class \(vcName) in your modules")
            viewController = createFallbackViewController(dataModel)
            return viewController
        }
        viewController = vcType.init()
        viewController.navigator = self
        
        return viewController
    }
    
    /// Create fallback view controller instance with class name.
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
    
    /// Create custom transition instance with class name.
    func createTransition(_ className: String?) -> Transition? {
        guard let name = className, !name.isEmpty else { return nil }
        guard let type = NSClassFromString(name) as? Transition.Type else {
            print("ZZZ: Can not find transition class \(name) in your modules")
            return nil
        }
        return type.init()
    }
    
    /// Add child view controllers for container view controllers like Navigation/Split/Tab view controller
    func addChildViewControllersIfExisted(_ data: Any, toViewController: UIViewController) {
        var viewControllers: [UIViewController] = []
        
        if let vcNames = data as? [String] {
            for vcName in vcNames {
                var dataModel = DataModel()
                dataModel.vcName = vcName
                let toVC = createViewController(dataModel)
                let dataDict: DataDictionary = [NavigatorParametersKey.viewControllerName : vcName]
                _sendDataBeforeShow(dataDict, fromVC: toViewController, toVC: toVC)
                viewControllers.append(toVC.navigationController ?? toVC)
            }
        } else if let list = data as? [DataDictionary] {
            for item in list {
                let toVC = createViewController(dataModelFromDictionay(item))
                _sendDataBeforeShow(item, fromVC: toViewController, toVC: toVC)
                viewControllers.append(toVC.navigationController ?? toVC)
            }
        }
        
        guard !viewControllers.isEmpty else { return }
        
        for (idx, viewController) in viewControllers.enumerated() {
            let vc = (viewController as? UINavigationController)?.topViewController ?? viewController
            vc.navigatorMode = .reset
            vc.navigator = Navigator()
            vc.navigator?.pushStack(vc)
            vc.navigator?.rootViewController = viewController
            vc.navigationController?.navigator = vc.navigator
            
            if (idx == 0) {
                Navigator._current = vc.navigator!
            }
        }
        
        (toViewController as? UITabBarController)?.viewControllers = viewControllers
        (toViewController as? UISplitViewController)?.viewControllers = viewControllers
        (toViewController as? UINavigationController)?.viewControllers = viewControllers
    }
}

// MARK: - Dismiss View Controllers
// MARK: -
private extension Navigator {
    
    func dismissViewControllers() {
        guard let dismissedVC = popStack(level) else { return }
        
        if dismissedVC.navigatorMode == .present {
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
        vc.dismiss(animated: dismissAnimated, completion: {
            self._sendDataAfterBack(self.dismissData, toVC: viewController)
            self.dismissCompletion?()
        })
    }
    
    func popViewController(_ viewController: UIViewController, fromNav: UINavigationController) {
        if fromNav.visibleViewController === viewController {
            fromNav.popToViewController(topViewController!, animated: dismissAnimated)
        } else {
            let presentingVC = presentingViewController(base: viewController, in: fromNav)
            presentingVC.dismiss(animated: false, completion: {
                fromNav.popToViewController(self.topViewController!, animated: self.dismissAnimated)
            })
        }
    }
    
    func presentingViewController(base viewController: UIViewController, in navController: UINavigationController) -> UIViewController {
        let baseIndex = navController.viewControllers.index(of: viewController) ?? 0
        for (index, vc) in (navController.viewControllers as Array).enumerated() where index >= baseIndex && vc.presentedViewController != nil {
            return vc
        }
        return viewController
    }
}

// MARK: - Send and Receive Data
// MARK: -
private extension Navigator {
    
    func _sendDataBeforeShow(_ data: DataDictionary, fromVC: UIViewController?, toVC: UIViewController) {
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeShow?(data, fromViewController: fromVC)
    }
    
    func _sendDataBeforeBack(_ data: DataDictionary, fromVC: UIViewController?, toVC: UIViewController) {
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveBeforeBack?(data, fromViewController: fromVC)
    }
    
    func _sendDataAfterBack(_ data: DataDictionary, toVC: UIViewController) {
        guard let dataProtocolVC = toVC as? DataProtocol else { return }
        dataProtocolVC.onDataReceiveAfterBack?(data, fromViewController: nil)
    }
}
