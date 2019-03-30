//
//  TabItemViewController.swift
//  NavigatorDemo
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import Navigator

class TabItemViewController: UIViewController, NavigatorDataProtocol {

    private typealias TupleType = (greeting: String, message: UInt32)
    private var dataModel: DataModel?
    private var tuple: TupleType?
    
    func onDataReceiveBeforeShow(_ data: DataModel, fromViewController: UIViewController?) {
        print("Received data before show from \(String(describing: fromViewController)): \(data)")
        
        dataModel = data
        title = data.title ?? "Favorites"
        tuple = data.additionalData as? TupleType
        
        tabBarItem = UITabBarItem(tabBarSystemItem: .favorites, tag: 0)
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "DeepLink", style: .plain, target: self, action: #selector(onDeepLink))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(onHome))
    }
    
    func onDataReceiveAfterBack(_ data: Any?, fromViewController: UIViewController?) {
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
        navigator?.sendDataAfterBack(dataModel)
    }
}

private extension TabItemViewController {
    
    @objc dynamic func onTapShowViewControler() {
        let data = DataModel(vcClass: DetailViewController.self, mode: .present, title: String(arc4random()), additionalData: "Passed a string type data")
        data.transitionName = NSStringFromClass(ScaleTransition.self)
        navigator?.show(data)
    }
    
    @objc dynamic func onHome() {
        navigator?.dismiss(level: -1)
    }
    
    @objc dynamic func onDeepLink() {
        let data = DataModel(vcClass: MasterViewController.self)
        Navigator.current.show(data)
    }
}

extension CGFloat {
    static func random() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
}
