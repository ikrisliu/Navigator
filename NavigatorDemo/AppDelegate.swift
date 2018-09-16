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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let tab1: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
                                    Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        
        let master: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(MasterViewController.self),
                                      Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        let detail: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(DetailViewController.self),
                                      Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        let tab2: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(SplitViewController.self),
                                    Navigator.ParamKey.children: [master, detail]]
        
        let data: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(UITabBarController.self),
                                    Navigator.ParamKey.children: [tab1, tab2]]
        
        Navigator.root.window = window
        Navigator.root.show(data)
        
        return true
    }
}
