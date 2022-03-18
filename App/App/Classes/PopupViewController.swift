//
//  PopupViewController.swift
//  Navigator.App
//
//  Created by Kris Liu on 2022/3/17.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit

class PopupViewController: DetailViewController {
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("\(PopupViewController.self) did disappear")
    }
    
    override func onTapShowViewControler() {
        print("Tap on \(PopupViewController.self)")
    }
}
