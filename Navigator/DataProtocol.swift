//
//  DataProtocol.swift
//  Navigator
//
//  Created by Kris Liu on 5/11/18.
//  Copyright © 2018 Syzygy. All rights reserved.
//

import UIKit

// MARK: - Data Dictionary
infix operator =>: AdditionPrecedence

/// Use this data structure to do data passing between two pages
/// Build a linked node for handling universal link and deep link (A => B => C => D)
@objc public class DataDictionary: NSObject, ExpressibleByDictionaryLiteral {

    @objc public private(set) var data: [String: Any] = [:]
    
    /// The next navigating view controller name with required data
    /// Use this variable to build linked node when you handle universal link or deep link
    @objc public var next: DataDictionary?
    
    @objc public var count: Int {
        return data.count
    }
    
    @objc public var isEmpty: Bool {
        return data.isEmpty
    }
    
    @objc public subscript(key: String) -> Any? {
        return data[key]
    }
    
    @objc public override var description: String {
        var desc = "", indent = ""
        var index = 0
        var curr: DataDictionary? = self
        repeat {
            desc += indent + curr!.data.description
            curr = curr?.next
            index += 1
            indent = "\n" + String(repeating: "  ", count: index)
        } while curr != nil
        return desc
    }
    
    @objc public override var debugDescription: String {
        return self.description
    }
    
    public required init(dictionaryLiteral elements: (String, Any)...) {
        for (key, value) in elements {
            data[key] = value
        }
    }
    
    /// For Objective-C usage
    @objc public static func dataWithDictionary(_ dictionary: [String: Any]) -> DataDictionary {
        return DataDictionary(dictionary)
    }
    
    @objc public required init(_ dictionary: [String: Any]) {
        data = dictionary
    }
    
    /// Use this custom operator to define navigation data for univeral linka and deep link
    public static func => (left: DataDictionary, right: DataDictionary) -> DataDictionary {
        var data = left
        if left.isEmpty {
            data = right
        } else {
            var curr = left
            while let next = curr.next {
                curr = next
            }
            curr.next = right
        }
        return data
    }
}


// MARK: - Data Protocol
/// View controller need implement this protocol for receiving data from previous or next view controller
@objc public protocol DataProtocol where Self: UIViewController {
    
    /// Receive data from previous page before current page show
    @objc optional func onDataReceiveBeforeShow(_ data: DataDictionary, fromViewController: UIViewController?)
    
    /// Receive data from next page before next page dismiss start
    @objc optional func onDataReceiveBeforeBack(_ data: DataDictionary, fromViewController: UIViewController?)
    
    /// Receive data from next page after next page dismiss animation end
    @objc optional func onDataReceiveAfterBack(_ data: DataDictionary, fromViewController: UIViewController?)
}
