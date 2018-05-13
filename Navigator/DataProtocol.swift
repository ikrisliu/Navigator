//
//  DataProtocol.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit

public typealias DataDictionary = [AnyHashable : Any]

@objc public protocol DataProtocol {
    
    @objc optional func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?)
    
    @objc optional func onDataReceiveBeforeBack(_ data: DataDictionary, fromViewController: UIViewController?)
    
    @objc optional func onDataReceiveAfterBack(_ data: DataDictionary, fromViewController: UIViewController?)
}


private var navigatorAssociationKey: UInt8 = 0

@objc public extension UIViewController {
    
    @objc var navigator: Navigator? {
        get {
            return objc_getAssociatedObject(self, &navigatorAssociationKey) as? Navigator
        }
        set {
            objc_setAssociatedObject(self, &navigatorAssociationKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
