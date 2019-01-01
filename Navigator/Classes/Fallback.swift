//
//  Fallback.swift
//  Navigator
//
//  Created by Kris Liu on 2018/8/27.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit
import os.log

@objc open class Fallback: UIViewController, DataProtocol {
    
    public func onDataReceiveBeforeShow(_ data: DataModel, fromViewController: UIViewController?) {
        title = data.title
        os_log("ZZZ: Received data from %@ before show: %@", String(describing: fromViewController), data)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "404"
        titleLabel.textColor = UIColor.lightGray
        titleLabel.font = UIFont.boldSystemFont(ofSize: 72)
        titleLabel.textAlignment = .center
        titleLabel.layer.shadowOpacity = 0.7
        titleLabel.layer.shadowRadius = 1.0
        titleLabel.layer.shadowColor = UIColor.black.cgColor
        titleLabel.layer.shadowOffset = CGSize(width: 0, height: 3)
        view.addSubview(titleLabel)
        
        titleLabel.centerXAnchor.constraint(equalTo: titleLabel.superview!.centerXAnchor).isActive = true
        titleLabel.centerYAnchor.constraint(equalTo: titleLabel.superview!.centerYAnchor).isActive = true
    }
}
