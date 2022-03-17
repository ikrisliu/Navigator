//
//  MasterViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2021 Crescent. All rights reserved.
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

class MasterViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Master"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        
        let overlay = UIBarButtonItem(title: "Overlay", style: .plain, target: self, action: #selector(onOverlay))
        let popover = UIBarButtonItem(title: "Popup", style: .plain, target: self, action: #selector(onPopup))
        
        navigationItem.rightBarButtonItems = [overlay, popover]
        
        setContext(["data": "This is context data."])
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
            PageObject(
                vcClass: DetailViewController.self,
                mode: UIDevice.current.userInterfaceIdiom == .pad ? .reset : .push,
                options:
                    withNavClass(UIDevice.current.userInterfaceIdiom == .pad ? UINavigationController.self : nil),
                    withTitle((tableView.cellForRow(at: indexPath)?.textLabel?.text!)!),
                    withExtraData(ContentPageExtraData(from: self, message: "Show detail view controller"))
            )
        )
    }
}

private extension MasterViewController {
    
    @objc dynamic func onOverlay() {
        navigator?.show(
            PageObject(
                vcClass: PopupViewController.self,
                mode: .overlay,
                options:
                    withTitle(String(arc4random())),
                    withExtraData(ContentPageExtraData(from: self, message: "Show popup view controller by overlay mode")),
                    withTransitionClass(CircleTransition.self),
                    withSourceRect(.init(origin: .zero, size: .init(width: 0, height: UIScreen.main.bounds.size.height / 2)))
            )
        )
    }
    
    @objc dynamic func onPopup() {
        let size = UIScreen.main.bounds.size
        navigator?.show(
            PageObject(
                vcClass: PopupViewController.self,
                mode: .present,
                options:
                    withTitle(String(arc4random())),
                    withExtraData(ContentPageExtraData(from: self, message: "Show center popup view controller")),
                    withPresentationStyle(.custom),
                    withTransitionClass(FadeTransition.self),
                    withSourceRect(.init(origin: .init(x: 20, y: (size.height - 300) / 2), size: .init(width: size.width - 40, height: 300)))
            )
        )
    }
}

extension FadeTransition {
    
    public override func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        PopoverPresentationController(presentedViewController: presented, presenting: presenting, sourceRect: sourceRect, dismissWhenTapOutside: true)
    }
}
