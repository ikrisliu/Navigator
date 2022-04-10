//
//  MasterViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import Navigator

class ContentPageBizData : PageBizData, CustomStringConvertible {
    let from: UIViewController
    let message: String
    
    init(from: UIViewController, message: String) {
        self.from = from
        self.message = message
    }
    
    var description: String {
        message
    }
}

class MasterViewController: UITableViewController, UIGestureRecognizerDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Master"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        
        let bottomSheet = UIBarButtonItem(title: "Bottom Sheet", style: .plain, target: self, action: #selector(onBottomSheet))
        let popup = UIBarButtonItem(title: "Popup", style: .plain, target: self, action: #selector(onPopup))

        navigationItem.leftBarButtonItem = popup
        navigationItem.rightBarButtonItem = bottomSheet
        
        setContext(["data": "This is context data."])
        
//        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("\(MasterViewController.self) did disappear")
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        30
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = String(arc4random())
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UIDevice.current.orientation == .portrait {
            splitViewController?.updateMasterVisibility()
        }
        
        navigator?.open(
            .init(
                vcClass: DetailViewController.self,
                mode: UIDevice.current.userInterfaceIdiom == .pad ? .reset : .push,
                options:
                    .navClass(UIDevice.current.userInterfaceIdiom == .pad ? UINavigationController.self : nil),
                    .title((tableView.cellForRow(at: indexPath)?.textLabel?.text!)!),
                    .bizData(ContentPageBizData(from: self, message: "Show detail view controller"))
            )
        )
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        navigationController?.topViewController?.enableInteractiveDismissGesture == true &&
        navigationController?.topViewController?.shouldDismissByInteractiveGesture == true
    }
}

private extension MasterViewController {
    
    @objc dynamic func onBottomSheet() {
        let size = view.bounds.size
        navigator?.open(
            .init(
                vcClass: PopupViewController.self,
                mode: .overlay,
                options:
                    .navClass(UINavigationController.self),
                    .title("Bottom Sheet"),
                    .bizData(ContentPageBizData(from: self, message: "Show bottom sheet by overlay mode")),
                    .sourceRect(.init(origin: .init(x: 0, y: size.height / 2), size: .init(width: size.width, height: size.height / 2)))
            )
        )
    }
    
    @objc dynamic func onPopup() {
        let size = view.bounds.size
        navigator?.open(
            .init(
                vcClass: PopupViewController.self,
                mode: .present,
                options:
                    .title("Popup"),
                    .bizData(ContentPageBizData(from: self, message: "Show center popup")),
                    .presentationStyle(.custom),
                    .transitionClass(FadeTransition.self),
                    .sourceRect(.init(origin: .init(x: 20, y: (size.height - 300) / 2), size: .init(width: size.width - 40, height: 300)))
            )
        )
    }
}
