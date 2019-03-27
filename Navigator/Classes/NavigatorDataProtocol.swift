//
//  NavigatorDataProtocol.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit

/// View controller need implement this protocol for receiving data from previous or next view controller
@objc public protocol NavigatorDataProtocol where Self: UIViewController {
    
    /// Receive data from previous page before current page show
    @objc optional func onDataReceiveBeforeShow(_ data: DataModel, fromViewController: UIViewController?)
    
    /// Receive data from next page before next page dismiss start
    @objc optional func onDataReceiveBeforeBack(_ data: DataModel, fromViewController: UIViewController?)
    
    /// Receive data from next page after next page dismiss animation end
    @objc optional func onDataReceiveAfterBack(_ data: DataModel, fromViewController: UIViewController?)
}
