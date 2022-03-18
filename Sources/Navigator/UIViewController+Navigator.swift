//
//  UIViewController+Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/7.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit

// MARK: - UIViewController.Name
extension UIViewController {
    
    @objc public class Name: NSObject, RawRepresentable {
        public private(set) var rawValue: String
        
        public init(_ rawValue: String) {
            self.rawValue = rawValue
        }
        
        required public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public override var description: String {
            rawValue
        }
        
        public override var hash: Int {
            rawValue.hash
        }
        
        public override func isEqual(_ object: Any?) -> Bool {
            if let other = object as? Name {
                return self.rawValue == other.rawValue
            } else {
                return false
            }
        }
    }
}

public extension UIViewController.Name {
    
    @objc static let empty = UIViewController.Name("")
    @objc static let defaultNavigation = UIViewController.Name(NSStringFromClass(Navigator.defaultNavigationControllerClass))
}

// MARK: - Open Methods
@objc public enum DismissAction: Int {
    case tap
    case tapOutside // For `overlay` or `popover` mode
    case interactiveGesture
}

extension UIViewController {
    
    /// If enable interactive dismiss gesture for presented view controller which must have custom animation transition
    @objc open var enableInteractiveDismissGesture: Bool { true }
    
    /// If should dismiss view controller which mode must be `customPush` when triggered an interactive pan gesture
    /// - NOTE: Should override the variable in subclass, do not call this variable directly.
    @objc open var shouldDismissByInteractiveGesture: Bool { true }
    
    /// Custom view controllers can override this variable to determine if need respond the deep linking.
    /// If return true, it will do nothing when open App via deep linking.
    @objc open var ignoreDeepLinking: Bool { false }
    
    /// When create a left navigation bar button item and navigation mode is `push`, you should use this method as target `selector`.
    @objc open func onPop() {
        navigator?.pop { [weak self] in
            self?.didFinishPopOrDismiss(.tap)
        }
    }
    
    /// When create a left navigation bar button item, you should use this method as target `selector`.
    @objc open func onDismiss() {
        navigator?.dismiss { [weak self] in
            self?.didFinishPopOrDismiss(.tap)
        }
    }
    
    @objc open func didFinishPopOrDismiss(_ action: DismissAction) { }
}

// MARK: - Public Properties
private enum AssociationKey {
    static var navigator: UInt8 = 0
    static var navigationMode: UInt8 = 0
    static var animationTransition: UInt8 = 0
    static var dimmedBackgroundView: UInt8 = 0
    static var pageObject: UInt8 = 0
    static var contextData: UInt8 = 0
}

extension UIViewController {
    
    /// Add a navigator variable for each view controller(VC) instance. So VC can open other VCs by navigator to decouple.
    ///   - If the VC is instantiated and opened by navigator, it can use navigator to open other VCs.
    ///   - If the VC is instantiated and opened by old way(push/present), the navigator will be nil, can't use navigator to open other VCs.
    @objc public internal(set) var navigator: Navigator? {
        get {
            objc_getAssociatedObject(self, &AssociationKey.navigator) as? Navigator
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc public internal(set) var navigationMode: Navigator.Mode {
        get {
            objc_getAssociatedObject(self, &AssociationKey.navigationMode) as? Navigator.Mode ?? .reset
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigationMode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc public internal(set) var pageObject: PageObject? {
        get {
            objc_getAssociatedObject(self, &AssociationKey.pageObject) as? PageObject
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.pageObject, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

// MARK: - Context Data
/// Context data which cross view controllers for the same navigator
extension UIViewController {
    
    @objc public func setContext(_ data: [String: Any]) {
        objc_setAssociatedObject(self, &AssociationKey.contextData, data, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private var _context: [String: Any] {
        objc_getAssociatedObject(self, &AssociationKey.contextData) as? [String: Any] ?? [:]
    }
    
    /// Get all context data, if has same key among view controllers, use the newest value which nearest from the current view controller.
    @objc public var context: [String: Any] {
        guard let vcs = navigator?.stack.compactMap({ $0.viewController }) else { return [:] }
        guard let index = vcs.firstIndex(of: self) else { return [:] }
        
        return vcs.prefix(through: index).map({ $0._context }).reduce([:]) { (result, dict) -> [String: Any] in
            result.merging(dict) { (_, new) in new }
        }
    }
    
    public func context<T>(forKey: String) -> [T]? {
        navigator?.stack.compactMap { $0.viewController?._context[forKey] } as? [T]
    }
}

// MARK: - Internal
extension UIViewController {
    
    var isPresent: Bool {
        switch navigationMode {
        case .present:
            return true
        case .reset, .goto, .push, .overlay:
            return false
        }
    }
    
    var isOverlay: Bool {
        switch navigationMode {
        case .overlay:
            return true
        case .reset, .goto, .push, .present:
            return false
        }
    }
    
    var isFullScreenModalPresentationStyle: Bool {
        modalPresentationStyle == .fullScreen || navigationController?.modalPresentationStyle == .fullScreen
    }
    
    var animationTransition: Transition? {
        get {
            objc_getAssociatedObject(self, &AssociationKey.animationTransition) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.animationTransition, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private(set) var dimmedBackgroundView: UIView? {
        get {
            objc_getAssociatedObject(self, &AssociationKey.dimmedBackgroundView) as? UIView
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.dimmedBackgroundView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func addDimmedBackgroundView() {
        let dimmedBackgroundView = UIView()
        dimmedBackgroundView.backgroundColor = .black
        dimmedBackgroundView.frame = view.bounds
        self.dimmedBackgroundView = dimmedBackgroundView
        view.addSubview(dimmedBackgroundView)
        
        dimmedBackgroundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTouchDimmedBgView)))
        dimmedBackgroundView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onTouchDimmedBgView)))
    }
    
    func removeDimmedBackgroundView() {
        dimmedBackgroundView?.removeFromSuperview()
        dimmedBackgroundView = nil
    }
    
    @objc dynamic private func onTouchDimmedBgView() {
        if children.last?.pageObject?.dismissWhenTapOutside == true {
            onDismiss()
        }
    }
    
    static func swizzleViewDidDisappear() {
        let originalMethod = class_getInstanceMethod(Self.self, #selector(viewDidDisappear(_:)))!
        let swizzledMethod = class_getInstanceMethod(Self.self, #selector(swizzle_viewDidDisappear(_:)))!
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    @objc dynamic private func swizzle_viewDidDisappear(_ animated: Bool) {
        swizzle_viewDidDisappear(animated)
        
        if isMovingFromParent {
            didFinishPopOrDismiss(.tap)
        }
    }
}
