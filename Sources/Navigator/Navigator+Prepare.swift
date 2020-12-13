//
//  Navigator+Prepare.swift
//  Navigator
//
//  Created by Kris Liu on 2019/12/23.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import UIKit

@objc public class HandlerName: NSObject, RawRepresentable {
    
    public private(set) var rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
    
    required public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public override var description: String {
        rawValue
    }
    
    public override var hash: Int {
        rawValue.hash
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        if let other = object as? HandlerName {
            return self.rawValue == other.rawValue
        } else {
            return false
        }
    }
}

@objc public protocol NavigationHandlerable {
    
    typealias CompletionBlock = ((PageObject?, Error?) -> Void)

    init()
    func execute(data: Any?, completion: CompletionBlock?)
}

public extension Navigator {
    
    /// Prepare navigation data and handling logic before show any page
    /// - Parameters:
    ///   - data: The data is passed to the navigated page, can be any type.
    ///   - handlerName: The handler class name is to determine show which page. It must implement `NavigationHandlerable` protocol.
    ///   - completion: The optional callback to be executed after navigation is completed.
    @objc static func prepare(_ data: Any? = nil, handlerName: HandlerName, completion: NavigationHandlerable.CompletionBlock? = nil) {
        if let classType = NSClassFromString(handlerName.rawValue) as? NavigationHandlerable.Type {
            classType.init().execute(data: data, completion: completion)
        }
    }
    
    @objc static func prepare(_ data: Any? = nil, handlerClass: NavigationHandlerable.Type, completion: NavigationHandlerable.CompletionBlock? = nil) {
        prepare(data, handlerName: .init(NSStringFromClass(handlerClass)), completion: completion)
    }
}
