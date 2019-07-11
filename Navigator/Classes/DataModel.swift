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
    public let vcName: UIViewController.Name
    
    /// Navigation controller class name (Used for containing the view controller)
    /// If `viewController` is actually UINavigationController or its subclass, ignore this variable.
    public let navName: UIViewController.Name?
    
    /// See **Navigator.Mode** (push, present and so on)
     /// If is present mode and `navigationController` is nil, will create a navigation controller for `viewController`.
    public var mode: Navigator.Mode = .push
    
    /// Navigation or view controller's title
    public var title: String?
    
    /// Additional data for passing to previous or next view controller. Pass tuple, dictionary or model for mutiple values.
    public var additionalData: Any?
    
    /// The optional callback to be executed after dimisss view controller.
    public var completion: CompletionClosure?
    
    /// See **UIModalTransitionStyle**. If has transition class, ignore the style.
    public var transitionStyle: UIModalTransitionStyle = .coverVertical
    
    /// See **UIModalPresentationStyle**. If style is *UIModalPresentationCustom*,
    /// need pass a transition class which creates a custom presentation view controller.
    public var presentationStyle: UIModalPresentationStyle = .fullScreen
    
    /// Transition class type for custom transition animation
    public var transitionClass: Transition.Type?
    
    /// If `presentationStyle` is **UIModalPresentationPopover**, at least pass the `sourceRect`.
    public var sourceView: UIView?
    public var sourceRect: CGRect?
    
    /// Fallback view controller will show if no VC found (like 404 Page)
    public var fallback: UIViewController.Type?
    
    /// Can contain a series of VCs with required data. (e.g. used in TabBarController to contain multiple view controllers)
    public var children: [DataModel]?
    
    /// The next navigating view controller name with required data
    /// Use this variable to build linked node when you handle universal link or deep link
    public internal(set) var next: DataModel?
    
    
    /// Data model's designated initializer
    /// If need decouple view controller classes, should call below initializers by passing class Name.
    ///
    /// - Parameters:
    ///   - viewController: View controller class name (For swift, the class name should be "ModuleName.ClassName")
    ///   - navigationController: Navigation controller class name (Used for containing the view controller)
    ///   - mode: See **Navigator.Mode** (push, present and so on)
    ///   - title: Navigation or view controller's title
    ///   - additionalData: Additional data for passing to previous or next view controller. Pass tuple, dictionary or model for mutiple values.
    ///   - children: Can contain a series of VCs with required data. (e.g. used in TabBarController to contain multiple view controllers)
    public init(vcName: UIViewController.Name, navName: UIViewController.Name? = nil, mode: Navigator.Mode = .push, title: String? = nil, additionalData: Any? = nil, children: [DataModel]? = nil) {
        self.vcName = vcName
        self.mode = mode
        self.title = title
        self.additionalData = additionalData
        self.children = children
        
        if mode == .present && navName == nil {
            self.navName = .init(NSStringFromClass(Navigator.defaultNavigationControllerClass))
        } else {
            self.navName = navName
        }
        
        let size = UIScreen.main.bounds.size
        
        if mode == .overlay {
            sourceRect = CGRect(origin: .zero, size: .init(width: 0, height: size.height / 2))
        } else if mode == .popover {
            sourceRect = CGRect(origin: .zero, size: .init(width: size.width - 20, height: size.height / 3))
        }
    }
}

// MARK: - Convenience Initializer
public extension DataModel {
    
    convenience init(vcName: UIViewController.Name, mode: Navigator.Mode = .push, title: String? = nil, additionalData: Any) {
        self.init(vcName: vcName, navName: nil, mode: mode, title: title, additionalData: additionalData)
    }
    
    convenience init(vcName: UIViewController.Name, navName: UIViewController.Name? = nil, title: String? = nil, children: [DataModel]) {
        self.init(vcName: vcName, navName: navName, mode: .reset, title: title, children: children)
    }
    
    /// Data model's convenience initializer.
    /// If don't need decouple view controller classes, should call below convenience initializers.
    ///
    /// - Parameters:
    ///   - vcClass: View controller class type
    ///   - navClass: Navigation controller class type
    ///   - mode: See **Navigator.Mode** (push, present and so on)
    ///   - title: Navigation or view controller's title
    ///   - additionalData: Additional data for passing to previous or next view controller. Pass tuple, dictionary or model for mutiple values.
    ///   - children: Can contain a series of VCs with required data. (e.g. used in TabBarController to contain multiple view controllers)
    convenience init(vcClass: UIViewController.Type,
                     navClass: UIViewController.Type? = nil,
                     mode: Navigator.Mode = .push,
                     title: String? = nil,
                     additionalData: Any? = nil,
                     children: [DataModel]? = nil) {
        self.init(vcName: .init(NSStringFromClass(vcClass)),
                  navName: navClass != nil ? .init(NSStringFromClass(navClass!)) : nil,
                  mode: mode, title: title, additionalData: additionalData, children: children)
    }
    
    convenience init(vcClass: UIViewController.Type, mode: Navigator.Mode = .push, title: String? = nil, additionalData: Any) {
        self.init(vcClass: vcClass, navClass: nil, mode: mode, title: title, additionalData: additionalData)
    }
    
    convenience init(vcClass: UIViewController.Type, navClass: UINavigationController.Type? = nil, title: String? = nil, children: [DataModel]) {
        self.init(vcClass: vcClass, navClass: navClass, mode: .reset, title: title, children: children)
    }
}

// MARK: - Custom Operator
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

// MARK: - Description
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
    
    public override var description: String { return debugDescription }
    
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

// MARK: - TransitionStyle
extension UIModalTransitionStyle: CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .coverVertical: return "coverVertical"
        case .flipHorizontal: return "flipHorizontal"
        case .crossDissolve: return "crossDissolve"
        case .partialCurl: return "partialCurl"
        @unknown default: fatalError()
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
        @unknown default: fatalError()
        }
    }
}
