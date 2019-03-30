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
        
//        showDeepLink()
        
        return true
    }
    
    func showDeepLink() {
        let splitData = DataModel(vcClass: SplitViewController.self)
        let navData = DataModel(vcClass: UINavigationController.self)
        let vcData = DataModel(vcClass: DetailViewController.self)

        Navigator.root.show(tabData --> splitData --> navData --> vcData)
    }
}
