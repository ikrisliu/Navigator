//
//  AppDelegate.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2021 Crescent. All rights reserved.
//

import UIKit
import Navigator

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private var tabPages: PageObject!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let firstTab = PageObject(vcClass: TabItemViewController.self, navClass: UINavigationController.self)
        
        let master = PageObject(vcClass: MasterViewController.self, navClass: UINavigationController.self)
        let detail = PageObject(vcClass: DetailViewController.self, navClass: UINavigationController.self)
        let secondTab = PageObject(vcClass: SplitViewController.self, children: [master, detail])
        
        tabPages = PageObject(vcClass: UITabBarController.self, mode: .reset, children: [firstTab, secondTab])
        
        Navigator.root.window = window
        Navigator.root.show(tabPages)
        
        UINavigationBar.appearance().isTranslucent = false
        UITabBar.appearance().isTranslucent = false
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let vcPage = PageObject(vcClass: DetailViewController.self)
        let navigator = url.host == "links" ? Navigator.root : Navigator.current
        
        navigator.open(url: url) { (_) -> PageObject? in
            let splitPage = PageObject(vcClass: SplitViewController.self)
            let navPage = PageObject(vcClass: MasterViewController.self)
            
            return url.host == "links" ? self.tabPages --> splitPage --> navPage --> vcPage : vcPage
        }
        
        return true
    }
}
