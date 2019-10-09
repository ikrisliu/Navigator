//
//  MasterViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Crescent. All rights reserved.
//

import UIKit
import Navigator

class MasterViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Master"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
        
        let overlay = UIBarButtonItem(title: "Overlay", style: .plain, target: self, action: #selector(onOverlay))
        let popover = UIBarButtonItem(title: "Popover", style: .plain, target: self, action: #selector(onPopover))
        
        navigationItem.rightBarButtonItems = [overlay, popover]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 30
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
        
        let title: String! = tableView.cellForRow(at: indexPath)?.textLabel?.text
        let navClass = UIDevice.current.userInterfaceIdiom == .pad ? UINavigationController.self : nil
        let mode: Navigator.Mode = UIDevice.current.userInterfaceIdiom == .pad ? .reset : .push
        let dict = ["from": "\(self)", "message": "Passed a dictionary type data"]
        let page = PageObject(vcClass: DetailViewController.self, navClass: navClass, mode: mode, title: title, extraData: dict)
        
        navigator?.show(page)
    }
}

private extension MasterViewController {
    
    @objc dynamic func onOverlay() {
        let page = PageObject(vcClass: DetailViewController.self, mode: .overlay, title: String(arc4random()), extraData: (self, "Passed a tuple type data"))
        page.transitionClass = CircleTransition.self
        navigator?.show(page)
    }
    
    @objc dynamic func onPopover() {
        let page = PageObject(vcClass: DetailViewController.self, mode: .popover, title: String(arc4random()), extraData: (self, "Passed a tuple type data"))
        navigator?.show(page)
    }
}
