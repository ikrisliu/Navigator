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
    
    static let invalid = UIViewController.Name("")
    static let defaultNavigation = UIViewController.Name(NSStringFromClass(Navigator.defaultNavigationControllerClass))
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
    
    /// Custom view controllers can override this variable to determine if need respond the deep linking.
    /// If return true, it will do nothing when open App via deep linking.
    @objc open var ignoreDeepLinking: Bool { false }
    
    var isDismissable: Bool {
        navigatorMode == .present || navigatorMode == .overlay || navigatorMode == .popover
    }
}

extension UIViewController {
    
    private enum AssociationKey {
        static var navigator: UInt8 = 0
        static var navigatorMode: UInt8 = 0
        static var navigatorTransition: UInt8 = 0
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
