//
//  SplitViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import Navigator

class SplitViewController: UISplitViewController, UISplitViewControllerDelegate {
    
    convenience init() {
        self.init(nibName: nil, bundle: nil)
        tabBarItem = UITabBarItem(tabBarSystemItem: .contacts, tag: 1)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delegate = self
        maximumPrimaryColumnWidth = 300
        
        extendedLayoutIncludesOpaqueBars = true // Set it true because of iOS 14.3 bug
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard displayMode != .primaryHidden else { return }
        preferredDisplayMode = UIDevice.current.orientation.isPortrait ? .primaryOverlay : .allVisible
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }
}

extension UISplitViewController {
    
    func updateMasterVisibility() {
        UIView.animate(withDuration: CATransaction.animationDuration()) {
            let isHidden = self.displayMode == .primaryHidden
            self.preferredDisplayMode = isHidden ? (UIDevice.current.orientation.isPortrait ? .primaryOverlay : .allVisible) : .primaryHidden
        }
    }
}
