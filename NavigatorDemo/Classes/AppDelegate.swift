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
    
    private var tabData: DataModel!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let firstTab = DataModel(vcClass: TabItemViewController.self, navClass: UINavigationController.self)
        
        let master = DataModel(vcClass: MasterViewController.self, navClass: UINavigationController.self)
        let detail = DataModel(vcClass: DetailViewController.self, navClass: UINavigationController.self)
        let secondTab = DataModel(vcClass: SplitViewController.self, children: [master, detail])
        
        tabData = DataModel(vcClass: UITabBarController.self, mode: .reset, children: [firstTab, secondTab])
        
        Navigator.root.window = window
        Navigator.root.show(tabData)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let vcData = DataModel(vcClass: DetailViewController.self)
        let navigator = url.host == "links" ? Navigator.root : Navigator.current
        
        navigator.open(url: url) { (_) -> DataModel in
            let splitData = DataModel(vcClass: SplitViewController.self)
            let navData = DataModel(vcClass: MasterViewController.self)
            
            return url.host == "links" ? self.tabData --> splitData --> navData --> vcData : vcData
        }
        
        return true
    }
}
