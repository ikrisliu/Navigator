//
//  DataModel.swift
//  Navigator
//
//  Created by Kris Liu on 2019/1/1.
//  Copyright © 2019 Syzygy. All rights reserved.
//

import UIKit

public typealias CompletionClosure = (Bool, Any?) -> Void

/// Use this data structure to do data passing between two pages
/// Build a linked node for handling universal link and deep link (A => B => C => D)
@objcMembers
public class DataModel: NSObject {
    
    /// View controller class name (For swift, the class name should be "ModuleName.ClassName")
    public let viewController: String?
    
    /// Navigation controller class name (Used for containing the view controller)
    /// If `viewController` is actually UINavigationController or its subclass, ignore this variable.
    public let navigationController: String?
    
    /// See **Navigator.Mode** (push or present)
     /// If is present mode and `navigationController` is nil, will create a navigation controller for `viewController`.
    public var mode: Navigator.Mode = .push
    
    /// Navigation or view controller's title
    public var title: String?
    
    /// See **UIModalTransitionStyle**. If has transition class, ignore the style.
    public var transitionStyle: UIModalTransitionStyle
    
    /// See **UIModalPresentationStyle**. If style is *UIModalPresentationCustom*,
    /// need pass a transition class which creates a custom presentation view controller.
    public var presentationStyle: UIModalPresentationStyle
    
    /// Transition class name for custom transition animation
    public var transitionClass: String?
    
    /// If `presentationStyle` is **UIModalPresentationPopover**, at least pass one of below two parameters.
    public var sourceView: UIView?
    public var sourceRect: NSValue?
    
    /// The presentation view controller's height
    public var preferredPresentationHeight = UIScreen.main.bounds.height / 2
    
    /// Additional data for passing to previous or next view controller. Pass tuple or model for mutiple values.
    public var additionalData: Any?
    
    /// The optional callback to be executed after dimisss view controller.
    public var completion: CompletionClosure?
    
    /// Fallback view controller will show if no VC found (like 404 Page)
    public var fallback: String?
    
    /// Can nest a series of VCs with required data. (e.g. used in TabBarController to contain multiple view controllers)
    public var children: [DataModel]?
    
    /// The next navigating view controller name with required data
    /// Use this variable to build linked node when you handle universal link or deep link
    public private(set) var next: DataModel?
    
    // swiftlint:disable multiline_parameters
    public init(viewController: String? = nil, navigationController: String? = nil, mode: Navigator.Mode = .push, title: String? = nil, additionalData: Any? = nil,
                transitionStyle: UIModalTransitionStyle = .coverVertical, presentationStyle: UIModalPresentationStyle = .fullScreen, transitionClass: String? = nil,
                sourceView: UIView? = nil, sourceRect: NSValue? = nil, completion: CompletionClosure? = nil, fallback: String? = nil, children: [DataModel]? = nil) {
        self.viewController = viewController
        self.mode = mode
        self.title = title
        self.transitionStyle = transitionStyle
        self.presentationStyle = presentationStyle
        self.transitionClass = transitionClass
        self.sourceView = sourceView
        self.sourceRect = sourceRect
        self.additionalData = additionalData
        self.completion = completion
        self.fallback = fallback
        self.children = children
        
        if mode == .present && navigationController == nil {
            self.navigationController = NSStringFromClass(UINavigationController.self)
        } else {
            self.navigationController = navigationController
        }
    }
    // swiftlint:enable multiline_parameters
}

// MARK: Init for ObjC
public extension DataModel {
    
    convenience init(viewController: String) {
        self.init(viewController: viewController, navigationController: nil)
    }
    
    convenience init(viewController: String, navigationController: String) {
        self.init(viewController: viewController, navigationController: navigationController, mode: .push)
    }
    
    convenience init(viewController: String, navigationController: String, mode: Navigator.Mode) {
        self.init(viewController: viewController, navigationController: navigationController, mode: mode, title: nil)
    }
    
    convenience init(viewController: String, navigationController: String, mode: Navigator.Mode, title: String) {
        self.init(viewController: viewController, navigationController: navigationController, mode: mode, title: title, additionalData: nil)
    }
    
    convenience init(viewController: String, navigationController: String, mode: Navigator.Mode, title: String?, additionalData: Any) {
        self.init(viewController: viewController, navigationController: navigationController, mode: mode, title: title, additionalData: additionalData, completion: nil)
    }
    
    convenience init(viewController: String, navigationController: String, mode: Navigator.Mode, title: String?, additionalData: Any?, completion: @escaping CompletionClosure) {
        self.init(viewController: viewController, navigationController: navigationController, mode: mode, title: title, additionalData: additionalData, completion: completion, fallback: nil)
    }
}

// MARK: Custom Operator
infix operator -->: AdditionPrecedence

extension DataModel {
    
    /// Use this custom operator to build navigation data for univeral link and deep link
    public static func --> (left: DataModel, right: DataModel) -> DataModel {
        var curr = left
        while let next = curr.next {
            curr = next
        }
        curr.next = right
        
        return left
    }
}

// MARK: Description
extension DataModel {
    
    private var stringRepresentation: String? {
        var dict: [String: Any] = [:]
        let mirror = Mirror(reflecting: self)
        
        for case let (label?, value) in mirror.children {
            // swiftlint:disable syntactic_sugar
            if case Optional<Any>.some(let rawValue) = value {
                dict[label] = "\(rawValue)"
            }
            // swiftlint:enable syntactic_sugar
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: .prettyPrinted) else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
    
    public override var debugDescription: String {
        var desc = "", indent = ""
        var index = 0
        var curr: DataModel? = self
        
        repeat {
            desc += indent + (curr!.stringRepresentation ?? "")
            curr = curr?.next
            index += 1
            indent = " -->\n"
        } while curr != nil
        
        return desc
    }
}

extension UIModalTransitionStyle: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .coverVertical: return "coverVertical"
        case .flipHorizontal: return "flipHorizontal"
        case .crossDissolve: return "crossDissolve"
        case .partialCurl: return "partialCurl"
        }
    }
}

extension UIModalPresentationStyle: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .fullScreen: return "fullScreen"
        case .pageSheet: return "pageSheet"
        case .formSheet: return "formSheet"
        case .currentContext: return "currentContext"
        case .custom: return "custom"
        case .overFullScreen: return "overFullScreen"
        case .overCurrentContext: return "overCurrentContext"
        case .popover: return "popover"
        case .none: return "none"
        }
    }
}
