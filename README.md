# Navigator

[![badge-version](https://img.shields.io/cocoapods/v/SmartNavigator.svg?label=version)](https://github.com/iKrisLiu/Navigator/releases)
![badge-pms](https://img.shields.io/badge/languages-Swift|ObjC-orange.svg)
![badge-languages](https://img.shields.io/badge/supports-Carthage|CocoaPods|SwiftPM-green.svg)
![badge-platforms](https://img.shields.io/cocoapods/p/SmartNavigator.svg?style=flat)

Navigator is a generic navigation framework for view controllers. It can decouple the dependency of different modules/components/view controllers.

## Features
- Data passing between view controllers bidirectional, inject data provider implementation for mocking data.
- Navigation between view controllers with system default or custom transition animation
- Support deep link and universal link
- Goto any view controller of any navigator
- Set context data and share it among view controllers
- Custmize view controller transition animation

## Architecture
<p align="center"><img src ="./Images/Navigator.jpg" /></p>
<p align="center"><img src ="./Images/DataPassing.jpg" /></p>

## Installation
### Swift Package Manager
[Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. To integrate Navigator into your Xcode project, specify it in your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/ikrisliu/Navigator", .upToNextMajor(from: "1.0.0"))
]
```

### CocoaPods
[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. To integrate Navigator into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SmartNavigator', '~> 1.0'
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate Navigator into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "ikrisliu/Navigator" ~> 1.0
```

## Usage
### Initialize Root View Controller

##### NavigatonControler
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Decoupling Way: Recommend to use this way among modules
    // View controller class name (The swift class name should be "ModuleName.ClassName")
    let main = PageObject(vcName: .init(rawValue: "ModuleName.ViewController"), mode: .reset, options: withNavName(.init(rawValue: "UINavigationController"))
    
    // Coupling Way: Recommend to use this way inside one module
    let main = PageObject(vcClass: ViewController.self, navCmode: .reset, options: withNavClass(UINavigationController.self))
    
    // If present view controller without passing any `UINavigationController`, use it as default one.
    Navigator.defaultNavigationControllerClass = UINavigationController.self
    
    Navigator.root.window = window
    Navigator.root.show(main)
    
    return true
}
```

##### SplitViewControler
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let master = PageObject(vcClass: MasterViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
    let detail = PageObject(vcClass: DetailViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
    let split = PageObject(vcClass: SplitViewController.self, mode: .reset, options: withChildren(master, detail))
    
    Navigator.root.window = window
    Navigator.root.show(split)
    
    return true
}
```

##### TabBarControler
```swift
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let firstTab = PageObject(vcClass: TabItemViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
    
    let master = PageObject(vcClass: MasterViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
    let detail = PageObject(vcClass: DetailViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
    let secondTab = PageObject(vcClass: SplitViewController.self, mode: .reset, options: withChildren(master, detail))
    
    let tabs = PageObject(vcClass: UITabBarController.self, mode: .reset, options: withChildren(firstTab, secondTab))
    
    Navigator.root.window = window
    Navigator.root.show(tabs)
    
    return true
}
```

### Show / Dismiss
Supported navigation mode: `Push`, `Present`, `Overlay` and `Goto`

```swift
class ContentPageData : PageExtraData {
    let message: String
    
    init(message: String) {
        self.message = message
    }
}

class DetailViewController: UIViewController {
    let data = ContentPageData(message: "You can pass any type object which need to implement PageExtraData protocol")

    @objc private func onTapShowViewControler() {
        // Decoupling Way
        let page = PageObject(vcName: .init(rawValue: ModuleName.CustomViewController"), mode: .push)
        
        // Coupling Way
        // If present a view contoller without passing any `UINavigationController`, it will use `Navigator.defaultNavigationControllerClass`.
        let page = PageObject(
            vcClass: UIViewController.self,
            mode: .push,
            options:
                withTitle("Hello"),
                withExtraData(data)
        )
        
        navigator?.show(page)
    }
    
    @objc private func onTapShowPopoverViewControler() {
        let size = view.bounds.size
                
        // Show bottom sheet
        let page = PageObject(
            vcClass: UIViewController.self,
            mode: .overlay,
            options: 
                withTitle("Hello"), 
                withExtraData(data)
                withSourceRect(.init(origin: .init(x: 0, y: size.height - 500), size: .init(width: size.width, height: 500)))
        )
        
        // Show center popup
        let page = PageObject(
            vcClass: UIViewController.self,
            mode: .present,
            options:
                withTitle("Hello"),
                withExtraData(data)
                withPresentationStyle(.custom),
                withTransitionClass(FadeTransition.self),
                withSourceRect(.init(origin: .init(x: 20, y: (size.height - 300) / 2), size: .init(width: size.width - 40, height: 300)))
        )
        
        navigator?.show(page)
    }
    
    @objc private func onTapDismissViewControler() {
        navigator?.pop(data)            // Pop the top view controller (like system navigation controller pop)
        navigator?.dismiss(data)        // Dismiss the presented view controller (like system view controller dismiss)
        navigator?.backToRoot(data)     // Back to root view controller of current navigator
        navigator?.backTo(OneViewController.self)   // Back to someone specific view controller which in navigtor stack
    }
}
```

### DeepLink
Use Safari or other approaches to test the deep link

```swift
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
    // Show top view controller base on current vc stack
    let page = PageObject(vcClass: TopViewController.self)
    Navigator.current.deepLink(page)

    // Show top view controller base on current vc stack
    Navigator.current.open(url: url) { _ -> PageObject? in
        // Parse the deep link url to below page object for showing
        return PageObject(vcClass: TopViewController.self)
    }

    // Show a chain of view controllers from root vc
    Navigator.root.open(url: url) { _ -> PageObject? in
        // Parse the deep link url to below page objects for showing
        let root = PageObject(vcClass: MainViewController.self, mode: .reset, options: withNavClass(UINavigationController.self))
        let middle = PageObject(vcClass: MiddleViewController.self)
        let top = PageObject(vcClass: TopViewController.self)

        return root => middle => top
    }

    return true
}
```

### Transition Animation
Create custom transition class inherits the `Transition` class and override below two methods. Then pass transition class with custom transition class name in page object.

```swift
class CustomTransition: Transition {
    @objc open func animatePresentationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) { }
    @objc open func animateNavigationTransition(isShow: Bool, from fromView: UIView?, to toView: UIView?, completion: VoidClosure? = nil) { }
}

class DetailViewController: UIViewController {
    @objc private func onTapShowViewControler() {
        let page = PageObject(vcClass: UIViewController.self, mode: .present, options: withTransitionStyle(.flipHorizontal))
        // or
        let page = PageObject(vcClass: UIViewController.self, mode: .present, options: withTransitionClass(CustomTransition.self))

        navigator?.show(page)
    }
}
```

### Data Passing
```swift
class DetailViewController: UIViewController, Navigatable {
    private var data: PageExtraData?
    
    // Receive page object from previous vc after current vc initialized (before `viewDidLoad`)
    // - Note: Only called one time after vc initialized
    func onPageDidInitialize(_ page: PageObject, fromVC: UIViewController?) {
        title = page.title
        data = page.extraData
    }
    
    // Receive data before the current vc show (before `viewDidLoad`)
    // - Note: May called multiple times since appear mutiple times
    @objc optional func onDataReceiveBeforeShow(_ data: PageExtraData?, fromVC: UIViewController?) {}
    
    // Receive data from next vc before the next vc dismiss start
    @objc optional func onDataReceiveBeforeBack(_ data: PageExtraData?, fromVC: UIViewController?) {}
    
    // Receive data from next vc after the next vc dismiss animation end
    func onDataReceiveAfterBack(_ data: PageExtraData?) {
        self.data = data
    }
}
```

### Context Data
If set context data in view controller A and open view controller B => C by sequence, you can easily get the context data in view controller B or C.

```swift
class ViewControllerA: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setContext(["data": "This is context data."])
    }
}

class ViewControllerC: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        print(context)
    }
}
```
