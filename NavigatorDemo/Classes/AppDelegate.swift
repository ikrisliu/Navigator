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
        let firstTab = DataModel(viewController: NSStringFromClass(ViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        
        let master = DataModel(viewController: NSStringFromClass(MasterViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        let detail = DataModel(viewController: NSStringFromClass(DetailViewController.self), navigationController: NSStringFromClass(UINavigationController.self))
        let secondTab = DataModel(viewController: NSStringFromClass(SplitViewController.self), children: [master, detail])
        
        let vcData = DataModel(viewController: NSStringFromClass(UITabBarController.self), children: [firstTab, secondTab])
        
        Navigator.root.window = window
        Navigator.root.show(vcData)
        
        return true
    }
}
