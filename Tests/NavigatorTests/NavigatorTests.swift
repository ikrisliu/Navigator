//
//  NavigatorTests.swift
//  NavigatorTests
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2021 Crescent. All rights reserved.
//

import XCTest
@testable import Navigator

class NavigatorTests: XCTestCase {
    
    private let vc1 = UITabBarController()
    private let vc2 = UIViewController()
    private let vc3 = UITableViewController()
    private let vc4 = UIViewController()
    private let vc5 = UIViewController()
    
    override func setUp() {
        super.setUp()
        
        Navigator.root.popStackAll()
        Navigator.root.pushStack(vc1)
        Navigator.root.pushStack(vc2)
        Navigator.root.pushStack(vc3)
        Navigator.root.pushStack(vc4)
        Navigator.root.pushStack(vc5)
    }
    
    func testGetStack() {
        XCTAssertEqual(Navigator.root.getStack(from: 0).last, vc5)
        XCTAssertEqual(Navigator.root.getStack(from: 1).last, vc4)
        XCTAssertEqual(Navigator.root.getStack(from: -2).last, vc3)
        XCTAssertEqual(Navigator.root.getStack(from: -1).last, vc2)
        XCTAssertEqual(Navigator.root.getStack(from: 4).last, vc1)
    }
    
    func testDismissLevelFromTop() {
        Navigator.root.popStack(from: 0)
        XCTAssertEqual(Navigator.root.stackCount, 4)
        
        Navigator.root.popStack(from: 1)
        XCTAssertEqual(Navigator.root.stackCount, 2)
    }
    
    func testDismissLevelFromBottom() {
        Navigator.root.popStack(from: -3)
        XCTAssertEqual(Navigator.root.stackCount, 3)
        
        Navigator.root.popStack(from: -1)
        XCTAssertEqual(Navigator.root.stackCount, 1)
    }
    
    func testDismissTo() {
        let vc = Navigator.root.getStack(from: 2).last!
        var index = Navigator.root.stackIndex(of: vc)!
        XCTAssertEqual(index, 2)
        Navigator.root.popStack(from: Navigator.root.stackLevel(index)!)
        XCTAssertEqual(Navigator.root.stackCount, 3)
        
        index = Navigator.root.stackIndex(of: NSStringFromClass(UIViewController.self))!
        XCTAssertEqual(index, 1)
        Navigator.root.popStack(from: Navigator.root.stackLevel(index)!)
        XCTAssertEqual(Navigator.root.stackCount, 2)
    }
}
