//
//  DetailViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit
import Navigator

class DetailViewController: UIViewController, Navigatable {
    
    func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController?) {
        title = page.title ?? "Detail"
        print("Received additional data: \(page.extraData ?? "")")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapShowViewControler)))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(onTapOpenMaster))
        }
        
        if navigatorMode == .present {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(onTapClose))
        }
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
    }
    
    override var ignoreDeepLinking: Bool { return true }
}

private extension DetailViewController {
    
    @objc dynamic func onTapOpenMaster() {
        splitViewController?.updateMasterVisibility()
    }
    
    @objc dynamic func onTapShowViewControler() {
        guard navigatorMode != .overlay, navigatorMode != .popover else {
            navigator?.dismiss()
            return
        }
        
        let page = PageObject(vcClass: TabItemViewController.self, title: String(arc4random()), extraData: (greeting: "Hello: ", message: arc4random()))
        navigator?.show(page)
    }
    
    @objc dynamic func onTapClose() {
        navigator?.dismiss("\(self) is dismissed")
    }
}
