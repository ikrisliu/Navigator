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
        let fstTab: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
                                      Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        
        let master: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(MasterViewController.self),
                                      Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        let detail: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(DetailViewController.self),
                                      Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self)]
        let secTab: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(SplitViewController.self),
                                      Navigator.ParamKey.children: [master, detail]]
        
        let vcData: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(UITabBarController.self),
                                      Navigator.ParamKey.children: [fstTab, secTab]]
        
        Navigator.root.window = window
        Navigator.root.show(vcData)
        
        print(String(describing: URLSession.self))
        print(NSStringFromClass(URLSession.self))
        
        return true
    }
}
