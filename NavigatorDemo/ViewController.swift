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
        
        title = data[Navigator.ParamKey.title] as? String ?? "Favorites"
        tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
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
        let data: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
                                    Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self),
                                    Navigator.ParamKey.mode: Navigator.Mode.present,
                                    Navigator.ParamKey.transitionName: NSStringFromClass(ScaleTransition.self),
                                    Navigator.ParamKey.title: String(arc4random())]
        self.navigator?.show(data)

//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            let para: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
//                                        Navigator.ParamKey.mode: Navigator.Mode.present,
//                                        Navigator.ParamKey.transitionStyle: UIModalTransitionStyle.flipHorizontal,
//                                        Navigator.ParamKey.title: String(arc4random())]
//            self.navigator?.show(para)
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            let para: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
//                                        Navigator.ParamKey.navigationCtrlName: NSStringFromClass(UINavigationController.self),
//                                        Navigator.ParamKey.mode: Navigator.Mode.present,
//                                        Navigator.ParamKey.title: String(arc4random())]
//            self.navigator?.show(para)
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            let para: DataDictionary = [Navigator.ParamKey.viewControllerName: NSStringFromClass(ViewController.self),
//                                        Navigator.ParamKey.title: String(arc4random())]
//            self.navigator?.show(para)
//        }
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            self.navigator?.dismiss([:], level: 2, animated: true, completion: nil)
//        }
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
        navigator?.sendDataAfterBack(data)
    }
}


extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
