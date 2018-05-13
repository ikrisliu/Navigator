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
    @objc public static let viewControllerName = "viewControllerName"   // View controller class name (For swift, the class name should be "ModuleName.ClassName")
    @objc public static let navigationCtrlName = "navigationCtrlName"   // Navigation controller class name (Used for embedding the view controller)
    @objc public static let transitionStyle = "transitionStyle"         // @see NavigatorTransitionStyle
    @objc public static let transitionName = "transitionName"           // Transition class name for custom transition animation
    @objc public static let mode = "mode"                               // @see NavigatorMode
    @objc public static let title = "title"                             // Navigation or view controller's title
    @objc public static let fallback = "fallback"                       // Fallback view controller class name if no VC found (e.g. 404 Page)
    @objc public static let children = "children"                       // Can be a list of VC names, also can nest a series of VCs with parameters
}

@objc public enum NavigatorMode: Int {
    case push
    case present
    case root
}

@objc public enum NavigatorTransitionStyle: Int {
    case system     // System default transition style
    case scale
    case circle
    case matrix
    case none
    case custom     // Need provide custom transition class.
}


@objc open class Navigator: NSObject {
    
    @objc open static let rootNavigator = Navigator()
    
    @objc open weak var window: UIWindow? {
        didSet {
            window?.makeKeyAndVisible()
        }
    }
    
    @objc open weak var rootViewController: UIViewController? {
        didSet {
            window?.rootViewController = rootViewController
        }
    }
    
    public typealias CompletionType = (() -> Void)?
    
    private var stack: NSMapTable<NSNumber, UIViewController> = NSMapTable.weakToWeakObjects()
    private var showAnimated: Bool = true
    private var dismissAnimated: Bool = true
    private var showCompletion: CompletionType = nil
    private var dismissCompletion: CompletionType = nil
    private var showModel: DataModel!
    private var dismissModel: DataModel!
    private var level: Int = 0  // Dismiss which level view controller, level 0 means that dismiss current viewcontroller, level 1 is previous VC. (Default is 0)
    
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
    
    
    // Functions
    @objc open func show(_ data: DataDictionary, animated: Bool = true, completion: CompletionType = nil) {
        self.showData = data
        self.showAnimated = animated
        self.showCompletion = completion
        
        showViewControllers()
    }
    
    @objc open func dismiss(_ data: DataDictionary = [:], level: Int = 0, animated: Bool = true, completion: CompletionType = nil) {
        self.level = level
        self.dismissData = data
        self.dismissAnimated = animated
        self.dismissCompletion = completion
        
        dismissViewControllers()
    }
    
    @objc open func sendDataBeforeBack(_ data: DataDictionary, level: Int = 0) {
        guard let poppedVC = popStack(level) else { return }
        let toVC = topViewController ?? poppedVC
        _sendDataBeforeBack(data, fromVC: poppedVC, toVC: toVC)
        pushStack(poppedVC)
    }
    
    @objc open func sendDataAfterBack(_ data: DataDictionary) {
        guard let toVC = topViewController else { return }
        _sendDataAfterBack(data, toVC: toVC)
    }
}

// MARK: - Private
// MARK: -
private struct DataModel {
    var vcName: String?
    var navName: String?
    var mode: NavigatorMode = .push
    var transitionStyle: NavigatorTransitionStyle = .system
    var transitionName: String?
    var fallback: String?
}

private var navigatorModeAssociationKey: UInt8 = 0

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
}

private extension Navigator {
    
    var stackCount: Int {
        return stack.dictionaryRepresentation().count
    }
    
    var topViewController: UIViewController? {
        return stackCount > 0 ? stack.object(forKey: (stackCount - 1) as NSNumber) : nil
    }
    
    func pushStack(_ viewController: UIViewController) {
        viewController.navigatorMode = showModel != nil ? showModel.mode : .root
        stack.setObject(viewController, forKey: stackCount as NSNumber)
    }
    
    func popStack(_ level: Int = 0) -> UIViewController? {
        let index = max(stackCount - 1 - level, 0)
        guard index < stackCount else { return nil }
        
        let poppedVC = stack.object(forKey: index as NSNumber)
        for i in index..<stackCount where i > 0 {
            stack.removeObject(forKey: i as NSNumber)
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
    
    func dataModelFromDictionay(_ dictionary: DataDictionary) -> DataModel {
        var dataModel = DataModel()
        dataModel.fallback = dictionary[NavigatorParametersKey.fallback] as? String
        dataModel.vcName = dictionary[NavigatorParametersKey.viewControllerName] as? String ?? dataModel.fallback
        dataModel.navName = dictionary[NavigatorParametersKey.navigationCtrlName] as? String
        dataModel.mode = dictionary[NavigatorParametersKey.mode] as? NavigatorMode ?? dataModel.mode
        dataModel.transitionStyle = dictionary[NavigatorParametersKey.transitionStyle] as? NavigatorTransitionStyle ?? dataModel.transitionStyle
        dataModel.transitionName = dictionary[NavigatorParametersKey.transitionName] as? String
        return dataModel
    }
}

// MARK: - Show View Controllers
// MARK: -
private extension Navigator {
    
    func showViewControllers() {
        guard let viewController = createViewController(showModel) else { return }
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
    
    func showViewControler(_ viewController: UIViewController) -> Bool {
        _sendDataBeforeShow(showData, fromVC: topViewController, toVC: viewController)
        
        let toVC = viewController.navigationController ?? viewController
        
        switch showModel.mode {
        case .push:
            topViewController?.navigationController?.pushViewController(toVC, animated: showAnimated)
        case .present:
            topViewController?.present(toVC, animated: showAnimated, completion: showCompletion)
        default:
            rootViewController = toVC
        }
        
        rootViewController = rootViewController ?? toVC
        pushStack(viewController)
        
        return true
    }
    
    /**
     * Create view controller with class name. If need embed it into navigation controller, create one with view controller.
     */
    func createViewController(_ dataModel: DataModel) -> UIViewController? {
        guard let vcName = dataModel.vcName, !vcName.isEmpty else { return nil }
        guard let vcType = NSClassFromString(vcName) as? UIViewController.Type else {
            print("ZZZ: Can not find view controller class \(vcName) in your modules")
            return nil
        }
        let viewController = vcType.init()
        viewController.navigator = self
        
        if let navName = dataModel.navName, !navName.isEmpty {
            guard let navType = NSClassFromString(navName) as? UINavigationController.Type else {
                print("ZZZ: Can not find navigation controller class \(vcName) in your modules")
                return viewController
            }
            let navigationController = navType.init()
            navigationController.viewControllers = [viewController]
            navigationController.navigator = self
        }
        
        return viewController
    }
    
    func addChildViewControllersIfExisted(_ data: Any, toViewController: UIViewController) {
        var viewControllers: [UIViewController] = []
        
        if let vcNames = data as? [String] {
            for vcName in vcNames {
                var dataModel = DataModel()
                dataModel.vcName = vcName
                guard let toVC = createViewController(dataModel) else { continue }
                
                let dataDict = [NavigatorParametersKey.viewControllerName : vcName]
                _sendDataBeforeShow(dataDict, fromVC: toViewController, toVC: toVC)
                viewControllers.append(toVC.navigationController ?? toVC)
            }
        } else if let list = data as? [DataDictionary] {
            for item in list {
                guard let toVC = createViewController(dataModelFromDictionay(item)) else { continue }
                
                _sendDataBeforeShow(item, fromVC: toViewController, toVC: toVC)
                viewControllers.append(toVC.navigationController ?? toVC)
            }
        }
        
        guard !viewControllers.isEmpty else { return }
        
        for viewController in viewControllers {
            let vc = (viewController as? UINavigationController)?.topViewController ?? viewController
            vc.navigator = Navigator()
            vc.navigator!.pushStack(vc)
            vc.navigator!.rootViewController = viewController
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
        let toVC = topViewController ?? dismissedVC
        
        _sendDataBeforeBack(dismissData, fromVC: dismissedVC, toVC: toVC)
        
        if dismissedVC.navigatorMode == .present {
            dismissViewController(dismissedVC)
            return
        }
        
        if let nav = dismissedVC.navigationController {
            popViewController(dismissedVC, fromNav: nav)
        } else {
            dismissViewController(dismissedVC.navigationController ?? dismissedVC)
        }
        
        _sendDataAfterBack(dismissData, toVC: toVC)
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
            presentingVC.dismiss(animated: dismissAnimated, completion: {
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
