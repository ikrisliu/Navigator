//
//  SplitViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class SplitViewController: UISplitViewController, DataProtocol {
    
    func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?) {
        print("Received data before show from \(String(describing: fromViewController)): \(data)")
        
        title = data[Navigator.ParamKey.title] as? String
        tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
