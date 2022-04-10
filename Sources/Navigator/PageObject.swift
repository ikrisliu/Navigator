//
//  PageObject.swift
//  Navigator
//
//  Created by Kris Liu on 2019/1/1.
//  Copyright © 2022 Gravity. All rights reserved.
//

import UIKit

public typealias CompletionClosure = (Bool, Any?) -> Void
public typealias ViewControllerCreator = () -> UIViewController

@objc public protocol PageBizData { }

public enum PageOption {
    case navName(UIViewController.Name?)
    case navClass(UIViewController.Type?)
    case title(String)
    case bizData(PageBizData)
    case callback(CompletionClosure)
    case transitionStyle(UIModalTransitionStyle)
    case presentationStyle(UIModalPresentationStyle)
    case transitionClass(Transition.Type)
    case sourceView(UIView)
    case sourceRect(CGRect)
    case dismissWhenTapOutside(Bool)
    case fallback(UIViewController.Type)
    case children([PageObject])
}

/// Use this data structure to do data passing between two pages
/// Build a linked node for handling universal link and deep link (A => B => C => D)
@objcMembers
public class PageObject: NSObject {
    
    /// View controller class name (For swift, the class name should be "ModuleName.ClassName")
    public fileprivate(set) var vcName: UIViewController.Name
    
    /// Create a view controller instance instead of vcName, if use this closure, vcName should be `UIViewController.Name.invalid`
    public fileprivate(set) var vcCreator: ViewControllerCreator?
    
    /// Navigation controller class name (Used for containing the view controller)
    /// If `viewController` is actually UINavigationController or its subclass, ignore this variable.
    public fileprivate(set) var navName: UIViewController.Name?
    
    /// See **Navigator.Mode** (push, present and so on)
     /// If is `present` mode and `navName` is nil, will create a navigation controller for the content view controller.
    public internal(set) var mode: Navigator.Mode = .push
    
    /// Navigation or view controller's title
    public fileprivate(set) var title: String?
    
    /// Business data for passing to previous or next view controller. Pass tuple, dictionary or model for mutiple values.
    public fileprivate(set) var bizData: PageBizData?
    
    /// The optional callback to be executed after dimisss view controller.
    public fileprivate(set) var callback: CompletionClosure?
    
    /// See **UIModalTransitionStyle**. If has transition class, ignore the style.
    public fileprivate(set) var transitionStyle: UIModalTransitionStyle = .coverVertical
    
    /// See **UIModalPresentationStyle**. If style is *UIModalPresentationCustom*,
    /// need pass a transition class which creates a custom presentation view controller.
    public fileprivate(set) var presentationStyle: UIModalPresentationStyle = .fullScreen
    
    /// Transition class type for custom transition animation. If navigator mode is `customPush`, the transition class will be `PushTransition` by default.
    public fileprivate(set) var transitionClass: Transition.Type?
    
    /// If `presentationStyle` is **UIModalPresentationPopover**, at least pass the `sourceRect`.
    public fileprivate(set) var sourceView: UIView?
    public fileprivate(set) var sourceRect: CGRect?
    
    /// Determine if the view controller can be dismissed by tapping vc's outside
    public fileprivate(set) var dismissWhenTapOutside: Bool = true
    
    /// Fallback view controller will show if no VC found (like 404 Page)
    public fileprivate(set) var fallback: UIViewController.Type = FallbackViewController.self
    
    /// Can contain a series of VCs with required data. (e.g. used in TabBarController to contain multiple view controllers)
    public fileprivate(set) var children: [PageObject]?
    
    /// The next navigating view controller name with required data
    /// Use this variable to build linked node when you handle universal link or deep link
    public internal(set) var next: PageObject?
    
    
    /// Data model's designated initializer
    /// If need decouple view controller classes, should call below initializers by passing class Name.
    ///
    /// - Parameters:
    ///   - vcName: View controller class name (For swift, the class name should be "ModuleName.ClassName")
    ///   - mode: See **Navigator.Mode** (push, present and so on)
    ///   - options: Enum options for setting the page object's properties
    private init(vcName: UIViewController.Name, mode: Navigator.Mode = .push, options: [PageOption]) {
        self.vcName = vcName
        self.mode = mode
        
        switch mode {
        case .overlay:
            self.transitionClass = OverlayTransition.self
        case .push, .present, .goto, .reset:
            break
        }
        
        super.init()
        
        for option in options {
            switch option {
            case .navName(let navName):
                self.navName = navName
            case .navClass(let navClass):
                self.navName = navClass.flatMap({ .init(NSStringFromClass($0)) }) ?? nil
            case .title(let title):
                self.title = title
            case .bizData(let bizData):
                self.bizData = bizData
            case .callback(let callback):
                self.callback = callback
            case .transitionStyle(let transitionStyle):
                self.transitionStyle = transitionStyle
            case .presentationStyle(let presentationStyle):
                self.presentationStyle = presentationStyle
            case .transitionClass(let transitionClass):
                self.transitionClass = transitionClass
            case .sourceView(let sourceView):
                self.sourceView = sourceView
            case .sourceRect(let sourceRect):
                self.sourceRect = sourceRect
            case .dismissWhenTapOutside(let dismissWhenTapOutside):
                self.dismissWhenTapOutside = dismissWhenTapOutside
            case .fallback(let fallback):
                self.fallback = fallback
            case .children(let children):
                self.children = children
            }
        }
    }
    
    public convenience init(vcName: UIViewController.Name, mode: Navigator.Mode = .push, options: PageOption...) {
        self.init(vcName: vcName, mode: mode, options: options)
    }
    
    public convenience init(vcClass: UIViewController.Type, mode: Navigator.Mode = .push, options: PageOption...) {
        self.init(vcName: .init(NSStringFromClass(vcClass)), mode: mode, options: options)
    }
    
    public convenience init(vcCreator: @escaping ViewControllerCreator, mode: Navigator.Mode = .push, options: PageOption...) {
        self.init(vcName: .empty, mode: mode, options: options)
        self.vcCreator = vcCreator
    }
}

// MARK: - Custom Operator
infix operator =>: AdditionPrecedence

extension PageObject {
    
    /// Use this custom operator to build navigation data for univeral link and deep link
    public static func => (left: PageObject, right: PageObject) -> PageObject {
        var curr = left
        while let next = curr.next {
            curr = next
        }
        curr.next = right
        
        return left
    }
}

// MARK: - Description
extension PageObject {
    
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
    
    public override var description: String { debugDescription }
    
    public override var debugDescription: String {
        var desc = "", indent = ""
        var index = 0
        var curr: PageObject? = self
        
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
        case .automatic: return "automatic"
        default: fatalError()
        }
    }
}
