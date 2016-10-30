/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Cartography

// MARK: - TabbedViewController

public final class TabbedViewController: UIViewController {

    public typealias Tab = TabbedView.Tab
    public typealias TabViewBinding = TabbedView.TabViewBinding
    public typealias TabbedViewControllerBinding = TabBinding<UIViewController>

    fileprivate var tabMappings: [Tab: TabbedViewControllerBinding] = [:]
    public var tabBindings: [TabbedViewControllerBinding] = [] {
        didSet {
            self.tabbedView.tabBindings = self.tabBindings.map { viewControllerBinding in
                return TabViewBinding(
                    tab: viewControllerBinding.tab,
                    action: {
                        switch viewControllerBinding.action {
                        case .performAction(let action):
                            return .performAction(action: action)

                        case .displayContent(let retrieveViewController):
                            return .displayContent(retrieveContent: { [weak self] tab in
                                guard
                                    let sSelf = self,
                                    let viewController = retrieveViewController(tab) else { return nil }
                                sSelf.activeViewController = viewController
                                return viewController.view
                                })
                        }
                    }())
            }
            self.tabMappings = self.tabBindings.reduce([:]) { partial, binding in
                var dict = partial
                dict[binding.tab] = binding
                return dict
            }
        }
    }

    public weak var delegate: TabbedViewControllerDelegate?

    public fileprivate(set) var activeViewController: UIViewController?

    public fileprivate(set) weak var tabbedView: TabbedView!
    public var tabBarView: TabBarView {
        return self.tabbedView.tabBarView
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.loadViewIfNeeded()
    }

    override public func loadView() {
        let tabbedView = TabbedView()
        self.view = tabbedView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.tabbedView = self.view as! TabbedView
        self.tabbedView.translatesAutoresizingMaskIntoConstraints = false
        self.tabbedView.delegate = self
    }
}

// MARK: - TabbedViewControllerDelegate

public protocol TabbedViewControllerDelegate: class {

    func tabbedViewController(_ tabbedViewController: TabbedViewController, isTabEnabled tab: TabBarView.Tab?) -> Bool
    func tabbedViewController(_ tabbedViewController: TabbedViewController, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?)
    func tabbedViewController(_ tabbedViewController: TabbedViewController, willRemove viewController: UIViewController, for tab: TabBarView.Tab)
    func tabbedViewController(_ tabbedViewController: TabbedViewController, didRemove viewController: UIViewController, for tab: TabBarView.Tab)
    func tabbedViewController(_ tabbedViewController: TabbedViewController, willAdd viewController: UIViewController, for tab: TabBarView.Tab)
    func tabbedViewController(_ tabbedViewController: TabbedViewController, didAdd viewController: UIViewController, for tab: TabBarView.Tab)
    func tabbedViewController(_ tabbedViewController: TabbedViewController, constrain view: UIView, inContainer containerView: UIView, for tab: TabBarView.Tab)
}

// MARK: - TabbedViewController: TabbedViewDelegate

extension TabbedViewController: TabbedViewDelegate {

    public func tabbedView(_ tabbedView: TabbedView, isTabEnabled tab: TabBarView.Tab?) -> Bool {
        return self.delegate?.tabbedViewController(self, isTabEnabled: tab) ?? true
    }

    public func tabbedView(_ tabbedView: TabbedView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) {
        self.delegate?.tabbedViewController(self, didChangeFromTab: fromTab, toTab: toTab)
    }

    public func tabbedView(_ tabbedView: TabbedView, willRemove view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabbedViewController(self, willRemove: viewController, for: tab)
        viewController.willMove(toParentViewController: nil)
    }

    public func tabbedView(_ tabbedView: TabbedView, didRemove view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        viewController.removeFromParentViewController()
        self.activeViewController = nil
        self.delegate?.tabbedViewController(self, didRemove: viewController, for: tab)
    }

    public func tabbedView(_ tabbedView: TabbedView, willAdd view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabbedViewController(self, willAdd: viewController, for: tab)
        self.addChildViewController(viewController)
    }

    public func tabbedView(_ tabbedView: TabbedView, didAdd view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        viewController.didMove(toParentViewController: self)
        self.delegate?.tabbedViewController(self, didAdd: viewController, for: tab)
    }

    public func tabbedView(_ tabbedView: TabbedView, constrain view: UIView, inContainer containerView: UIView, for tab: TabBarView.Tab) {
        self.delegate?.tabbedViewController(self, constrain: view, inContainer: containerView, for: tab)
    }
}

// MARK: - TabbedView

public final class TabbedView: UIView {

    public typealias Tab = TabBarView.Tab
    public typealias TabViewBinding = TabBinding<UIView>

    fileprivate weak var containerView: UIView!
    public fileprivate(set) weak var tabBarView: TabBarView!

    fileprivate var tabMappings: [Tab: TabViewBinding] = [:]
    public var tabBindings: [TabViewBinding] = [] {
        didSet {
            self.tabBarView.tabs = self.tabBindings.map({ $0.tab })
            self.tabMappings = self.tabBindings.reduce([:]) { partial, binding in
                var dict = partial
                dict[binding.tab] = binding
                return dict
            }
        }
    }

    public weak var delegate: TabbedViewDelegate?

    public fileprivate(set) var activeView: UIView?

    public enum TabBarAlignment {
        case top(CGFloat)
        case bottom(CGFloat)
    }

    fileprivate var tabBarConstraintGroup = ConstraintGroup()
    public var tabBarAlignment: TabBarAlignment = .top(0) {
        didSet {
            self.tabBarConstraintGroup = constrain(self, self.tabBarView, replace: self.tabBarConstraintGroup) { superview, tabBarView in
                tabBarView.left == superview.left
                tabBarView.right == superview.right
                switch self.tabBarAlignment {
                case .top(let inset):
                    tabBarView.top == superview.top + inset
                case .bottom(let inset):
                    tabBarView.bottom == superview.bottom + inset
                }
            }
        }
    }

    fileprivate var tabBarHeightConstraintGroup = ConstraintGroup()
    public var tabBarHeight: CGFloat = -1 {
        didSet {
            guard self.tabBarHeight != oldValue else { return }
            self.tabBarHeightConstraintGroup = constrain(self.tabBarView, replace: self.tabBarHeightConstraintGroup) { tabBarView in
                tabBarView.height == self.tabBarHeight
            }
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let containerView = UIView()
        self.addAndConstrainView(containerView)
        self.containerView = containerView

        let tabBarView = TabBarView()
        tabBarView.delegate = self
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tabBarView)
        self.tabBarView = tabBarView

        self.tabBarAlignment = .bottom(0)
        self.tabBarHeight = 60
    }
}

// MARK: - TabbedViewDelegate

public protocol TabbedViewDelegate: class {

    func tabbedView(_ tabbedView: TabbedView, isTabEnabled tab: TabBarView.Tab?) -> Bool
    func tabbedView(_ tabbedView: TabbedView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?)
    func tabbedView(_ tabbedView: TabbedView, willRemove view: UIView, for tab: TabBarView.Tab)
    func tabbedView(_ tabbedView: TabbedView, didRemove view: UIView, for tab: TabBarView.Tab)
    func tabbedView(_ tabbedView: TabbedView, willAdd view: UIView, for tab: TabBarView.Tab)
    func tabbedView(_ tabbedView: TabbedView, didAdd view: UIView, for tab: TabBarView.Tab)
    func tabbedView(_ tabbedView: TabbedView, constrain view: UIView, inContainer containerView: UIView, for tab: TabBarView.Tab)
}

// MARK: - TabbedView: TabBarViewDelegate

extension TabbedView: TabBarViewDelegate {

    public func tabBarView(_ tabBarView: TabBarView, shouldChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) -> Bool {
        let shouldChange = self.delegate?.tabbedView(self, isTabEnabled: toTab) ?? true
        guard shouldChange else { return false }

        // TODO: Animation injection
        if let activeView = self.activeView, let tab = fromTab {
            self.delegate?.tabbedView(self, willRemove: activeView, for: tab)
            activeView.removeFromSuperview()
            self.activeView = nil
            self.delegate?.tabbedView(self, didRemove: activeView, for: tab)
        }

        guard
            let tab = toTab,
            let binding = self.tabMappings[tab] else { return false }

        switch binding.action {
        case .performAction(let action):
            action(tab)
            return false

        case .displayContent(let retrieveView):
            guard let view = retrieveView(tab) else { return false }
            self.delegate?.tabbedView(self, willAdd: view, for: tab)
            self.containerView.addSubview(view)
            self.delegate?.tabbedView(self, constrain: view, inContainer: self.containerView, for: tab)
            self.activeView = view
            self.delegate?.tabbedView(self, didAdd: view, for: tab)
            return true
        }
    }

    public func tabBarView(_ tabBarView: TabBarView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) {
        self.delegate?.tabbedView(self, didChangeFromTab: fromTab, toTab: toTab)
    }
}

public enum TabAction<ContentType> {

    public typealias Tab = TabBarView.Tab
    public typealias PerformAction = (Tab) -> Void
    public typealias RetrieveContent = (Tab) -> ContentType?

    case performAction(action: PerformAction)
    case displayContent(retrieveContent: RetrieveContent)

    fileprivate var isPerformAction: Bool {
        switch self {
        case .performAction(_): return true
        default: return false
        }
    }

    fileprivate var isDisplayContent: Bool {
        switch self {
        case .displayContent(_): return true
        default: return false
        }
    }
}

public struct TabBinding<ContentType>: Hashable {

    public typealias Tab = TabBarView.Tab

    public var tab: Tab
    public var action: TabAction<ContentType>

    public init(tab: Tab, action: TabAction<ContentType>) {
        self.tab = tab
        self.action = action
    }

    // MARK: Hashable conformance

    public var hashValue: Int {
        return self.tab.hashValue
    }

    public static func ==<ContentType> (lhs: TabBinding<ContentType>, rhs: TabBinding<ContentType>) -> Bool {
        return lhs.tab == rhs.tab
    }
}

// MARK: - TabBarView

public final class TabBarView: UIView {

    public struct Tab: Hashable {

        public var tag: String
        public var view: UIView
        public var delegate: TabBarViewTabDelegate?

        public init(tag: String, view: UIView, delegate: TabBarViewTabDelegate? = nil) {
            self.tag = tag
            self.view = view
            self.delegate = delegate ?? (view as? TabBarViewTabDelegate)
        }

        // MARK: Hashable conformance

        public var hashValue: Int {
            return self.tag.hashValue
        }

        public static func == (lhs: Tab, rhs: Tab) -> Bool {
            return lhs.tag == rhs.tag
        }
    }

    fileprivate final class TabManager {

        unowned let tabBarView: TabBarView
        let tab: Tab
        let index: Int

        let tabView = UIView()
        let tapGestureRecognizer = UITapGestureRecognizer()

        init(tabBarView: TabBarView, tab: Tab, index: Int) {
            self.tabBarView = tabBarView
            self.tab = tab
            self.index = index

            self.tabView.translatesAutoresizingMaskIntoConstraints = false
            self.tabView.addAndConstrainView(self.tab.view)

            self.tapGestureRecognizer.addTarget(self, action: #selector(self.tabViewDidTap(_:)))
            self.tabView.addGestureRecognizer(self.tapGestureRecognizer)
        }

        dynamic func tabViewDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
            if tapGestureRecognizer.state == .ended {
                self.tabBarView.didTapView(for: self)
            }
        }

        func uninstall() {
            self.tabView.removeGestureRecognizer(self.tapGestureRecognizer)
            self.tabView.removeFromSuperview()
            self.tab.view.removeFromSuperview()
        }
    }

    public var tabs: [Tab] {
        get { return self.tabManagers.map({ $0.tab }) }
        set(newTabs) {
            self.tabManagers = newTabs.enumerated().map({ TabManager(tabBarView: self, tab: $1, index: $0) })
            self._selectedIndex = nil
            self.desiredIndex = self.tabManagers.isEmpty ? nil : 0
            self.forceTabReselection = true
            self.setNeedsLayout()
        }
    }

    fileprivate var tabManagers: [TabManager] = [] {
        willSet {
            self.tabManagers.forEach { tabManager in
                tabManager.uninstall()
            }
        }
        didSet {
            self.tabManagers.forEach { tabManager in
                self.stackView.addArrangedSubview(tabManager.tabView)
            }
        }
    }

    fileprivate weak var stackView: UIStackView!

    public weak var delegate: TabBarViewDelegate?

    fileprivate var forceTabReselection = false
    fileprivate var dirtySelection = false
    fileprivate var desiredIndex: Int?

    fileprivate var _selectedIndex: Int?
    public var selectedIndex: Int? {
        get {
            if self.dirtySelection { return self.desiredIndex }
            return self._selectedIndex
        }
        set { self.setDesiredIndex(newValue) }
    }

    fileprivate func setDesiredIndex(_ index: Int?, needsLayout: Bool = true) {
        if let index = index, index < 0 || index >= self.tabManagers.count {
            self.desiredIndex = nil
        } else {
            self.desiredIndex = index
        }

        self.dirtySelection = (self.desiredIndex != self._selectedIndex)

        if needsLayout && self.dirtySelection {
            self.setNeedsLayout()
        }
    }

    fileprivate func updateSelectedIndexIfNecessary() {
        guard self.dirtySelection || self.forceTabReselection else { return }

        let currentTabManager = self.tabManager(forIndex: self._selectedIndex)
        let desiredTabManager = self.tabManager(forIndex: self.desiredIndex)
        let shouldChange = self.delegate?.tabBarView(self, shouldChangeFromTab: currentTabManager?.tab, toTab: desiredTabManager?.tab) ?? true
        guard shouldChange else { return }

        let indicateSelected = { (manager: TabManager?, selected: Bool) in
            guard let manager = manager else { return }
            manager.tab.delegate?.tabBarView(self, shouldIndicate: manager.tab, isSelected: selected)
        }

        self._selectedIndex = self.desiredIndex

        indicateSelected(currentTabManager, false)
        indicateSelected(desiredTabManager, true)
        self.dirtySelection = false
        self.forceTabReselection = false
        self.delegate?.tabBarView(self, didChangeFromTab: currentTabManager?.tab, toTab: desiredTabManager?.tab)
    }

    public var selectedTab: (index: Int, item: Tab)? {
        guard let selectedIndex = self.selectedIndex else { return nil }
        return (selectedIndex, self.tabManagers[selectedIndex].tab)
    }

    fileprivate func tabManager(forIndex index: Int?) -> TabManager? {
        if let index = index {
            return self.tabManagers[index]
        } else {
            return nil
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        self.addAndConstrainView(stackView)
        self.stackView = stackView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateSelectedIndexIfNecessary()
    }

    fileprivate func didTapView(for tabManager: TabManager) {
        self.setDesiredIndex(tabManager.index, needsLayout: false)
        self.updateSelectedIndexIfNecessary()
    }
}

// MARK: - TabBarViewDelegate

public protocol TabBarViewDelegate: class {

    func tabBarView(_ tabBarView: TabBarView, shouldChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) -> Bool
    func tabBarView(_ tabBarView: TabBarView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?)
}

// MARK: - TabBarViewItemDelegate

public protocol TabBarViewTabDelegate {

    func tabBarView(_ tabBarView: TabBarView, shouldIndicate tab: TabBarView.Tab, isSelected selected: Bool)
}
