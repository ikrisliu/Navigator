//
//  Navigatable.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit

/// View controller need implement this protocol for receiving data from previous or next view controller
@objc public protocol Navigatable where Self: UIViewController {
    
    /// Receive page object from previous vc after current vc initialized (before `viewDidLoad`)
    /// - Note: Only called one time after vc initialized
    @objc optional func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController?)
    
    /// Receive data before the current vc show (before `viewDidLoad`)
    /// - Note: May called multiple times since appear mutiple times
    @objc optional func onDataReceiveBeforeShow(_ data: Any?, fromVC: UIViewController?)
    
    /// Receive data from next vc before the next vc dismiss start
    @objc optional func onDataReceiveBeforeBack(_ data: Any?, fromVC: UIViewController?)
    
    /// Receive data from next vc after the next vc dismiss animation end
    @objc optional func onDataReceiveAfterBack(_ data: Any?)
}
