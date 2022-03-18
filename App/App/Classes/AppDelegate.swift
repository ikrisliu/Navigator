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
        let search = PageObject(vcClass: SearchViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
        
        let master = PageObject(vcClass: MasterViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
        let detail = PageObject(vcClass: DetailViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
        let contacts = PageObject(vcClass: SplitViewController.self, mode: .reset, options: withChildren(master, detail))
        
        tabPages = PageObject(vcClass: UITabBarController.self, mode: .reset, options: withChildren(search, contacts))
        
        Navigator.root.window = window
        Navigator.root.show(tabPages)
        
        if #available(iOS 15, *) {
            let navAppearance = UINavigationBarAppearance()
            navAppearance.configureWithOpaqueBackground()
//            UINavigationBar.appearance().standardAppearance = navAppearance
//            UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
            
            let tabAppearance = UITabBarAppearance()
            tabAppearance.configureWithOpaqueBackground()
            UITabBar.appearance().standardAppearance = tabAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        } else {
            UINavigationBar.appearance().isTranslucent = false
            UITabBar.appearance().isTranslucent = false
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        let vcPage = PageObject(vcClass: DetailViewController.self)
        let navigator = url.host == "links" ? Navigator.root : Navigator.current
        
        navigator.open(url: url) { (_) -> PageObject? in
            let splitPage = PageObject(vcClass: SplitViewController.self)
            let navPage = PageObject(vcClass: MasterViewController.self)
            
            return url.host == "links" ? self.tabPages => splitPage => navPage => vcPage : vcPage
        }
        
        return true
    }
}
