//
//  TabItemViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2021 Crescent. All rights reserved.
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
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        if let tuple = tuple {
            label.text = tuple.greeting + String(tuple.message)
        } else {
            label.text = String(arc4random())
        }
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
        navigator?.sendDataAfterBack(page?.extraData)
    }
}

private extension TabItemViewController {
    
    @objc dynamic func onTapShowViewControler() {
        let page = PageObject(vcClass: DetailViewController.self, mode: .present, title: String(arc4random()), extraData: "Passed a string type data")
        page.transitionClass = PushTransition.self
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
