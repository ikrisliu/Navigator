//
//  DetailViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2021 Crescent. All rights reserved.
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
        
        if navigationMode == .customPush {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(onDismiss))
        }
        
        print("Context data: \(context)")
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = String(arc4random())
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 32)
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    override var hidesBottomBarWhenPushed: Bool {
        get { false }
        set { super.hidesBottomBarWhenPushed = newValue }
    }
    
    override func onSystemBack() {
        debugPrint("onSystemBack")
    }
    
    override func willFinishDismissing(_ action: DismissAction) {
        debugPrint("willFinishDismissing - \(action.rawValue)")
    }
    
    override func didFinishDismissing(_ action: DismissAction) {
        debugPrint("didFinishDismissing - \(action.rawValue)")
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
    }
    
    override var ignoreDeepLinking: Bool { true }
}

private extension DetailViewController {
    
    @objc dynamic func onTapOpenMaster() {
        splitViewController?.updateMasterVisibility()
    }
    
    @objc dynamic func onTapShowViewControler() {
        guard navigationMode != .overlay, navigationMode != .popover else {
            navigator?.dismiss()
            return
        }
        
        let page = PageObject(vcCreator: { TabItemViewController() }, mode: .customPush, title: String(arc4random()), extraData: (greeting: "Hello: ", message: arc4random()))
        navigator?.show(page)
    }
}
