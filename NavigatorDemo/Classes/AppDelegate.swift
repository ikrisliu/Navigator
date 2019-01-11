//
//  AppDelegate.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let firstTab = DataModel(viewController: NSStringFromClass(TabItemViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        
        let master = DataModel(viewController: NSStringFromClass(MasterViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        let detail = DataModel(viewController: NSStringFromClass(DetailViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        let secondTab = DataModel(viewController: NSStringFromClass(SplitViewController.self), children: [master, detail])
        
        let tabData = DataModel(viewController: NSStringFromClass(UITabBarController.self), mode: .reset, children: [firstTab, secondTab])
        let splitData = DataModel(viewController: NSStringFromClass(SplitViewController.self))
        let navData = DataModel(viewController: NSStringFromClass(UINavigationController.self))
        let vcData = DataModel(viewController: NSStringFromClass(DetailViewController.self))
        
        Navigator.root.window = window
//        Navigator.root.show(tabData)
        Navigator.root.show(tabData --> splitData --> navData --> vcData)
        
        return true
    }
}
