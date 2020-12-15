//
//  UIViewController+Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/7.
//  Copyright © 2019 Crescent. All rights reserved.
//

import UIKit

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
    
    @objc static let invalid = UIViewController.Name("")
    @objc static let defaultNavigation = UIViewController.Name(NSStringFromClass(Navigator.defaultNavigationControllerClass))
}

private enum AssociationKey {
    static var navigator: UInt8 = 0
    static var navigatorMode: UInt8 = 0
    static var navigatorTransition: UInt8 = 0
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
    
    @objc public internal(set) var navigatorMode: Navigator.Mode {
        get {
            objc_getAssociatedObject(self, &AssociationKey.navigatorMode) as? Navigator.Mode ?? .push
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorMode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
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
    
    /// Custom view controllers can override this variable to determine if need respond the deep linking.
    /// If return true, it will do nothing when open App via deep linking.
    @objc open var ignoreDeepLinking: Bool { false }
}

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

extension UIViewController {
    
    var isDismissable: Bool {
        navigatorMode == .present || navigatorMode == .overlay || navigatorMode == .popover
    }
    
    var p_navigatorTransition: Transition? {
        get {
            objc_getAssociatedObject(self, &AssociationKey.navigatorTransition) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorTransition, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
