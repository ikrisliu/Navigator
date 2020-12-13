//
//  TabItemViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit
import Navigator

class TabItemViewController: UIViewController, Navigatable {

    private typealias TupleType = (greeting: String, message: UInt32)
    private var page: PageObject?
    private var tuple: TupleType?
    
    func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController?) {
        print("Received data before show from \(String(describing: fromVC)): \(page)")
        
        self.page = page
        title = page.title ?? "Favorites"
        tuple = page.extraData as? TupleType
        
        tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(onHome))
    }
    
    func onDataReceiveAfterBack(_ data: Any?) {
        print("Received data after back: \(data ?? "nil")")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapShowViewControler)))
        
        guard let tuple = tuple else { return }
        let label = UILabel()
        label.frame = view.frame
        label.autoresizingMask = [.flexibleWidth, .flexibleWidth]
        label.textAlignment = .center
        label.text = tuple.greeting + String(tuple.message)
        view.addSubview(label)
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
        navigator?.sendDataAfterBack(page?.extraData)
    }
}

private extension TabItemViewController {
    
    @objc dynamic func onTapShowViewControler() {
        let page = PageObject(vcClass: DetailViewController.self, mode: .present, title: String(arc4random()), extraData: "Passed a string type data")
//        page.transitionClass = ScaleTransition.self
        page.transitionClass = MatrixTransition.self
        navigator?.show(page)
    }
    
    @objc dynamic func onHome() {
        navigator?.backToRoot()
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
