//
//  SearchViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import Navigator

class SearchViewController: UIViewController, Navigatable {

    private typealias TupleType = (greeting: String, message: UInt32)
    private var pageData: ContentPageExtraData?
    
    func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController) {
        print("Received data before show from \(fromVC): \(page)")
        
        title = page.title ?? "Favorites"
        pageData = page.extraData as? ContentPageExtraData
        
        tabBarItem = UITabBarItem(tabBarSystemItem: .search, tag: 0)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(onHome))
    }
    
    func onDataReceiveAfterBack(_ data: PageExtraData?) {
        debugPrint("Received data after back: \(String(describing: data))")
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
        
        if let data = pageData {
            label.text = data.message
        } else {
            label.text = String(arc4random())
        }
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
    }
}

private extension SearchViewController {
    
    @objc dynamic func onTapShowViewControler() {
        navigator?.open(
            .init(
                vcClass: ResultViewController.self,
                mode: .push,
                options:
                    withTitle("Results"),
                    withExtraData(ContentPageExtraData(from: self, message: "Show result view controller"))
            )
        )
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
