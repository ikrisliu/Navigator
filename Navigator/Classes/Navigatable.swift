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
    
    /// Receive data from previous page before current page show
    @objc optional func onPageObjectReceiveBeforeShow(_ page: PageObject, fromVC: UIViewController?)
    
    /// Receive data from next page before next page dismiss start
    @objc optional func onDataReceiveBeforeBack(_ data: Any?, fromVC: UIViewController?)
    
    /// Receive data from next page after next page dismiss animation end
    @objc optional func onDataReceiveAfterBack(_ data: Any?, fromVC: UIViewController?)
}
