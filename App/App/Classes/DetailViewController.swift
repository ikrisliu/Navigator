//
//  DetailViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import Navigator

class DetailViewController: UIViewController, Navigatable {
    
    func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController) {
        title = page.title ?? "Detail"
        debugPrint("Received additional data: \(String(describing: page.bizData))")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: .random(), green: .random(), blue: .random(), alpha: 1.0)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTapShowViewControler)))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(onTapOpenMaster))
        }
        
        if [.present, .overlay].contains(navigationMode) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(onClose))
        }
        
        debugPrint("Context data: \(context)")
        
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
    
    override var shouldDismissByInteractiveGesture: Bool {
        true
    }
    
    override func didBackOrClose(_ action: DismissAction) {
        debugPrint("\(#function) by \(action)")
        navigator?.sendDataAfterBack(ContentPageBizData(from: self, message: "Back from results page"))
    }
    
    deinit {
        debugPrint("FREE MEMORY: \(self)")
    }
    
    override var ignoreDeepLinking: Bool { true }
}

extension DetailViewController {
    
    @objc dynamic func onTapOpenMaster() {
        splitViewController?.updateMasterVisibility()
    }
    
    @objc open dynamic func onTapShowViewControler() {
        navigator?.open(
            .init(
                vcCreator: { SearchViewController() },
                mode: .present,
                options:
                    .navClass(UINavigationController.self),
                    .title("Search"),
                    .transitionClass(ZoomTransition.self),
                    .bizData(ContentPageBizData(from: self, message: "Search view controller"))
            )
        )
    }
}
