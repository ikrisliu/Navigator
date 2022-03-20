//
//  Navigatable.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit

/// View controller need implement this protocol for receiving data from previous or next view controller
@objc public protocol Navigatable where Self: UIViewController {
    
    /// Current VC receive page object from previous VC after the current one initialized (before `viewDidLoad`)
    /// - Note: Only called one time after the VC initialized
    @objc optional func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController)
    
    /// Current VC receive data before the current VC show (before `viewDidLoad`)
    /// - Note: May called multiple times since the view appear mutiple times
    @objc optional func onDataReceiveBeforeShow(_ data: PageBizData?, fromVC: UIViewController)
    
    /// Previous VC receive data from current VC after the current one dismiss animation end
    @objc optional func onDataReceiveAfterBack(_ data: PageBizData?)
}
