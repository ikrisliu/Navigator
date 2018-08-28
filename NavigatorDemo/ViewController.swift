//
//  ViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator


class ViewController: UIViewController, DataProtocol {

    private var data: DataDictionary = [:]
    
    func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?) {
        print("Received data before show from \(String(describing: fromViewController)): \(data)")
        
        self.data = data
        self.title = data[NavigatorParametersKey.title] as? String
        
        guard let tabBarSystemItem = data[NSStringFromClass(UITabBarItem.self)] else { return }
        tabBarItem = UITabBarItem(tabBarSystemItem: tabBarSystemItem as! UITabBarSystemItem, tag: 0)
    }
    
    func onDataReceiveAfterBack(_ data: DataDictionary, fromViewController: UIViewController?) {
        print("Received data after back: \(data)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showViewControler)))
    }
    
    @objc func showViewControler() {
        let data: DataDictionary = [NavigatorParametersKey.viewControllerName : NSStringFromClass(ViewController.self),
                                    NavigatorParametersKey.title : String(arc4random())]
        self.navigator?.show(data)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let para: DataDictionary = [NavigatorParametersKey.viewControllerName : NSStringFromClass(ViewController.self),
                                        NavigatorParametersKey.mode : NavigatorMode.present,
                                        NavigatorParametersKey.title : String(arc4random())]
            self.navigator?.show(para)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            let para: DataDictionary = [NavigatorParametersKey.viewControllerName : NSStringFromClass(ViewController.self),
                                        NavigatorParametersKey.navigationCtrlName : NSStringFromClass(UINavigationController.self),
                                        NavigatorParametersKey.mode : NavigatorMode.present,
                                        NavigatorParametersKey.title : String(arc4random())]
            self.navigator?.show(para)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            let para: DataDictionary = [NavigatorParametersKey.viewControllerName : NSStringFromClass(ViewController.self),
                                        NavigatorParametersKey.title : String(arc4random())]
            self.navigator?.show(para)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.navigator?.dismiss([:], level: 2, animated: true, completion: nil)
        }
    }
    
    deinit {
        print("FREE MEMORY: \(self)")
        navigator?.sendDataAfterBack(data)
    }
}


extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
