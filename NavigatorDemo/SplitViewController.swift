//
//  SplitViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate, DataProtocol {
    
    func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?) {
        print("Received data before show from \(String(describing: fromViewController)): \(data)")
        
        title = data[Navigator.ParamKey.title] as? String
        tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        maximumPrimaryColumnWidth = 300
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard displayMode != .primaryHidden else { return }
        preferredDisplayMode = UIDevice.current.orientation.isPortrait ? .primaryOverlay : .allVisible
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}
