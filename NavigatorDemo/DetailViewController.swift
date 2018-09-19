//
//  DetailViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class DetailViewController: UIViewController, DataProtocol {
    
    func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?) {
        title = data[Navigator.ParamKey.title] as? String ?? "Detail"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapShowViewControler)))
        
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(onTapOpenMaster))
    }
    
    @objc func onTapOpenMaster() {
        splitViewController?.updateMasterVisibility()
    }
    
    @objc func onTapShowViewControler() {
        let data: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
                                    Navigator.ParamKey.title: String(arc4random()),
                                    Navigator.ParamKey.additionalData: (greeting: "Hello: ", message: arc4random())]
        self.navigator?.show(data)
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
    }
}
