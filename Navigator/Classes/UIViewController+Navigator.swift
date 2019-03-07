//
//  UIViewController+Navigator.swift
//  Navigator
//
//  Created by Kris Liu on 2019/3/7.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import Foundation

/// Add a navigator variable for each view controller(VC) instance. So VC can open other VCs by navigator to decouple.
///   - If the VC is instantiated and opened by navigator, it can use navigator to open other VCs.
///   - If the VC is instantiated and opened by old way(push/present), the navigator will be nil, can't use navigator to open other VCs.
public extension UIViewController {
    
    @objc var navigator: Navigator? {
        get {
            return objc_getAssociatedObject(self, &AssociationKey.navigator) as? Navigator
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigator, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIViewController {
    
    enum AssociationKey {
        static var navigator: UInt8 = 0
        static var navigatorMode: UInt8 = 0
        static var navigatorTransition: UInt8 = 0
    }
    
    var p_navigatorMode: Navigator.Mode {
        get {
            let rawValue = objc_getAssociatedObject(self, &AssociationKey.navigatorMode) as! Int
            return Navigator.Mode(rawValue: rawValue)!
        }
        set {
            objc_setAssociatedObject(self, &AssociationKey.navigatorMode, newValue.rawValue as NSNumber, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
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
