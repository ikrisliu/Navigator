//
//  MasterViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 2018/9/13.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class MasterViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Master"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: String(describing: UITableViewCell.self))
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
        let navController = UIDevice.current.userInterfaceIdiom == .pad ? NSStringFromClass(UINavigationController.self) : nil
        let mode: Navigator.Mode = UIDevice.current.userInterfaceIdiom == .pad ? .reset : .push
        let data = DataModel(viewController: NSStringFromClass(DetailViewController.self), navigationController: navController, mode: mode, title: title)
        
        navigator?.show(data)
    }
}
