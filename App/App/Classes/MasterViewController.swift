//
//  MasterViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit
import Navigator

class ContentPageExtraData : PageExtraData, CustomStringConvertible {
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
        
        navigator?.show(
            .init(
                vcClass: DetailViewController.self,
                mode: UIDevice.current.userInterfaceIdiom == .pad ? .reset : .push,
                options:
                    withNavClass(UIDevice.current.userInterfaceIdiom == .pad ? UINavigationController.self : nil),
                    withTitle((tableView.cellForRow(at: indexPath)?.textLabel?.text!)!),
                    withExtraData(ContentPageExtraData(from: self, message: "Show detail view controller"))
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
        navigator?.show(
            .init(
                vcClass: PopupViewController.self,
                mode: .overlay,
                options:
                    withTitle(String(arc4random())),
                    withExtraData(ContentPageExtraData(from: self, message: "Show bottom sheet by overlay mode")),
                    withSourceRect(.init(origin: .init(x: 0, y: size.height / 2), size: .init(width: size.width, height: size.height / 2)))
            )
        )
    }
    
    @objc dynamic func onPopup() {
        let size = view.bounds.size
        navigator?.show(
            .init(
                vcClass: PopupViewController.self,
                mode: .present,
                options:
                    withTitle(String(arc4random())),
                    withExtraData(ContentPageExtraData(from: self, message: "Show center popup")),
                    withPresentationStyle(.custom),
                    withTransitionClass(FadeTransition.self),
                    withSourceRect(.init(origin: .init(x: 20, y: (size.height - 300) / 2), size: .init(width: size.width - 40, height: 300)))
            )
        )
    }
}
