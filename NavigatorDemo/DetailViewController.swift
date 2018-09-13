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
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showViewControler)))
    }
    
    @objc func showViewControler() {
        let data: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(DetailViewController.self),
                                    Navigator.ParamKey.title: String(arc4random())]
        self.navigator?.show(data)
    }
}
