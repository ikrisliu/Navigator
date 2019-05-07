//
//  UIViewController+Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/7.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import UIKit

extension UIViewController {
    
    /// Add a navigator variable for each view controller(VC) instance. So VC can open other VCs by navigator to decouple.
    ///   - If the VC is instantiated and opened by navigator, it can use navigator to open other VCs.
    ///   - If the VC is instantiated and opened by old way(push/present), the navigator will be nil, can't use navigator to open other VCs.
    @objc public internal(set) var navigator: Navigator? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigator) as? Navigator
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc public internal(set) var navigatorMode: Navigator.Mode {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigatorMode) as? Navigator.Mode ?? .push
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorMode, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// Custom view controllers can override this variable to determine if need respond the deep linking.
    /// If return true, it will do nothing when open App via deep linking.
    @objc open var ignoreDeepLinking: Bool { return false }
}

extension UIViewController {
    
    private enum AssociationKey {
        static var navigator: UInt8 = 0
        static var navigatorMode: UInt8 = 0
        static var navigatorTransition: UInt8 = 0
    }
    
    var p_navigatorTransition: Transition? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigatorTransition) as? Transition
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorTransition, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
