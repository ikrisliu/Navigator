//
//  DetailViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class DetailViewController: UIViewController, NavigatorDataProtocol {
    
    func onDataReceiveBeforeShow(_ data: DataModel, fromViewController: UIViewController?) {
        title = data.title ?? "Detail"
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
}

private extension DetailViewController {
    
    @objc dynamic func onTapOpenMaster() {
        splitViewController?.updateMasterVisibility()
    }
    
    @objc dynamic func onTapShowViewControler() {
        let data = DataModel(viewController: NSStringFromClass(TabItemViewController.self), title: String(arc4random()), additionalData: (greeting: "Hello: ", message: arc4random()))
        navigator?.show(data)
    }
    
    @objc dynamic func onTapClose() {
        navigator?.dismiss()
    }
}
