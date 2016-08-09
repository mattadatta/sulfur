/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Cartography

// MARK: - TabViewController

public final class TabViewController: UIViewController {

    public typealias Tab = TabbedView.Tab
    public typealias TabViewBinding = TabbedView.TabViewBinding
    public typealias TabViewControllerBinding = TabBinding<UIViewController>

    private var tabMappings: [Tab: TabViewControllerBinding] = [:]
    public var tabBindings: [TabViewControllerBinding] = [] {
        didSet {
            self.tabbedView.tabBindings = self.tabBindings.map { viewControllerBinding in
                return TabViewBinding(
                    tab: viewControllerBinding.tab,
                    action: {
                        switch viewControllerBinding.action {
                        case .performAction(let action):
                            return .performAction(action)

                        case .displayContent(let retrieveViewController):
                            return .displayContent({ [weak self] tab in
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

    public weak var delegate: TabViewControllerDelegate?

    public private(set) var activeViewController: UIViewController?

    public private(set) weak var tabbedView: TabbedView!
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

    private func commonInit() {
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

// MARK: - TabViewControllerDelegate

public protocol TabViewControllerDelegate: class {

    func tabViewController(_ tabViewController: TabViewController, isTabEnabled tab: TabBarView.Tab?) -> Bool
    func tabViewController(_ tabViewController: TabViewController, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?)
    func tabViewController(_ tabViewController: TabViewController, willRemove viewController: UIViewController, for tab: TabBarView.Tab)
    func tabViewController(_ tabViewController: TabViewController, didRemove viewController: UIViewController, for tab: TabBarView.Tab)
    func tabViewController(_ tabViewController: TabViewController, willAdd viewController: UIViewController, for tab: TabBarView.Tab)
    func tabViewController(_ tabViewController: TabViewController, didAdd viewController: UIViewController, for tab: TabBarView.Tab)
    func tabViewController(_ tabViewController: TabViewController, constrain view: UIView, inContainer containerView: UIView, for tab: TabBarView.Tab)
}

// MARK: - TabViewController: TabbedViewDelegate

extension TabViewController: TabbedViewDelegate {

    public func tabbedView(_ tabbedView: TabbedView, isTabEnabled tab: TabBarView.Tab?) -> Bool {
        return self.delegate?.tabViewController(self, isTabEnabled: tab) ?? true
    }

    public func tabbedView(_ tabbedView: TabbedView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) {
        self.delegate?.tabViewController(self, didChangeFromTab: fromTab, toTab: toTab)
    }

    public func tabbedView(_ tabbedView: TabbedView, willRemove view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabViewController(self, willRemove: viewController, for: tab)
        viewController.willMove(toParentViewController: nil)
    }

    public func tabbedView(_ tabbedView: TabbedView, didRemove view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        viewController.removeFromParentViewController()
        self.activeViewController = nil
        self.delegate?.tabViewController(self, didRemove: viewController, for: tab)
    }

    public func tabbedView(_ tabbedView: TabbedView, willAdd view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabViewController(self, willAdd: viewController, for: tab)
        self.addChildViewController(viewController)
    }

    public func tabbedView(_ tabbedView: TabbedView, didAdd view: UIView, for tab: TabBarView.Tab) {
        guard let viewController = self.activeViewController else { return }
        viewController.didMove(toParentViewController: self)
        self.delegate?.tabViewController(self, didAdd: viewController, for: tab)
    }

    public func tabbedView(_ tabbedView: TabbedView, constrain view: UIView, inContainer containerView: UIView, for tab: TabBarView.Tab) {
        self.delegate?.tabViewController(self, constrain: view, inContainer: containerView, for: tab)
    }
}

// MARK: - TabbedView

public final class TabbedView: UIView {

    public typealias Tab = TabBarView.Tab
    public typealias TabViewBinding = TabBinding<UIView>

    private weak var containerView: UIView!
    public private(set) weak var tabBarView: TabBarView!

    private var tabMappings: [Tab: TabViewBinding] = [:]
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

    public private(set) var activeView: UIView?

    public enum TabBarAlignment {
        case top
        case bottom
    }

    private var tabBarConstraintGroup = ConstraintGroup()
    public var tabBarAlignment: TabBarAlignment = .top {
        didSet {
            self.tabBarConstraintGroup = Cartography.constrain(self, self.tabBarView, replace: self.tabBarConstraintGroup) { superview, tabBarView in
                superview.left == tabBarView.left
                superview.right == tabBarView.right
                switch self.tabBarAlignment {
                case .top:
                    superview.top == tabBarView.top
                case .bottom:
                    superview.bottom == tabBarView.bottom
                }
            }
        }
    }

    private var tabBarHeightConstraintGroup = ConstraintGroup()
    public var tabBarHeight: CGFloat = -1 {
        didSet {
            guard self.tabBarHeight != oldValue else { return }
            self.tabBarHeightConstraintGroup = Cartography.constrain(self.tabBarView, replace: self.tabBarHeightConstraintGroup) { tabBarView in
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

    private func commonInit() {
        let containerView = UIView()
        self.addAndConstrain(containerView)
        self.containerView = containerView

        let tabBarView = TabBarView()
        tabBarView.delegate = self
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(tabBarView)
        self.tabBarView = tabBarView

        self.tabBarAlignment = .bottom
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

    public func tabBarView(_ tabBarView: TabBarView, shouldChangeToTab tab: TabBarView.Tab?) -> Bool {
        let isEnabled = self.delegate?.tabbedView(self, isTabEnabled: tab) ?? true
        guard let tab = tab, let binding = self.tabMappings[tab] else { return isEnabled }
        return isEnabled && binding.action.isDisplayContent
    }

    public func tabBarView(_ tabBarView: TabBarView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?) {
        // TODO: Animation injection
        if let activeView = self.activeView, let tab = fromTab {
            self.delegate?.tabbedView(self, willRemove: activeView, for: tab)
            activeView.removeFromSuperview()
            self.activeView = nil
            self.delegate?.tabbedView(self, didRemove: activeView, for: tab)
        }

        guard let tab = toTab else { return }
        guard let binding = self.tabMappings[tab] else { return }
        switch binding.action {
        case .performAction(let action):
            action(tab)

        case .displayContent(let retrieveView):
            guard let view = retrieveView(tab) else { break }
            self.delegate?.tabbedView(self, willAdd: view, for: tab)
            self.containerView.addSubview(view)
            self.delegate?.tabbedView(self, constrain: view, inContainer: self.containerView, for: tab)
            self.activeView = view
            self.delegate?.tabbedView(self, didAdd: view, for: tab)
        }
    }
}

public enum TabAction<ContentType> {

    public typealias Tab = TabBarView.Tab
    public typealias PerformAction = (Tab) -> Void
    public typealias RetrieveContent = (Tab) -> ContentType?

    case performAction(PerformAction)
    case displayContent(RetrieveContent)

    private var isPerformAction: Bool {
        switch self {
        case .performAction(_): return true
        default: return false
        }
    }

    private var isDisplayContent: Bool {
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
        public var delegate: TabBarViewItemDelegate?

        public init(tag: String, view: UIView, delegate: TabBarViewItemDelegate? = nil) {
            self.tag = tag
            self.view = view
            self.delegate = delegate ?? (view as? TabBarViewItemDelegate)
        }

        // MARK: Hashable conformance

        public var hashValue: Int {
            return self.tag.hashValue
        }

        public static func == (lhs: Tab, rhs: Tab) -> Bool {
            return lhs.tag == rhs.tag
        }
    }

    private final class TabManager {

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
            self.tabView.addAndConstrain(self.tab.view)

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

    private var tabManagers: [TabManager] = [] {
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

    private weak var stackView: UIStackView!

    public weak var delegate: TabBarViewDelegate?

    private var forceTabReselection = false
    private var dirtySelection = false
    private var desiredIndex: Int?

    private var _selectedIndex: Int?
    public var selectedIndex: Int? {
        get {
            if self.dirtySelection { return self.desiredIndex }
            return self._selectedIndex
        }
        set { self.setDesiredIndex(newValue) }
    }

    private func setDesiredIndex(_ index: Int?, needsLayout: Bool = true) {
        if index < 0 || index >= self.tabManagers.count {
            self.desiredIndex = nil
        } else {
            self.desiredIndex = index
        }

        self.dirtySelection = (self.desiredIndex != self._selectedIndex)

        if needsLayout && self.dirtySelection {
            self.setNeedsLayout()
        }
    }

    private func updateSelectedIndexIfNecessary() {
        guard self.dirtySelection || self.forceTabReselection else { return }

        let desiredTabManager = self.tabManager(forIndex: self.desiredIndex)
        let shouldChangeTo = self.delegate?.tabBarView(self, shouldChangeToTab: desiredTabManager?.tab) ?? true

        guard shouldChangeTo else { return }

        let currentTabManager = self.tabManager(forIndex: self._selectedIndex)
        self._selectedIndex = desiredTabManager?.index

        let indicateSelected = { (manager: TabManager?, selected: Bool) in
            guard let manager = manager else { return }
            manager.tab.delegate?.tabBarView(self, tab: manager.tab, shouldIndicateSelected: selected)
        }

        indicateSelected(currentTabManager, false)
        indicateSelected(desiredTabManager, true)
        self.dirtySelection = false
        self.forceTabReselection = false
        self.delegate?.tabBarView(self, didChangeFromTab: currentTabManager?.tab, toTab: desiredTabManager?.tab)
    }

    public var selectedTab: (index: Int, item: Tab)? {
        guard let selectedIndex = self.selectedIndex else {
            return nil
        }
        return (selectedIndex, self.tabManagers[selectedIndex].tab)
    }

    private func tabManager(forIndex index: Int?) -> TabManager? {
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

    private func commonInit() {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        self.addAndConstrain(stackView)
        self.stackView = stackView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.updateSelectedIndexIfNecessary()
    }

    private func didTapView(for tabManager: TabManager) {
        self.setDesiredIndex(tabManager.index, needsLayout: false)
        self.updateSelectedIndexIfNecessary()
    }
}

// MARK: - TabBarViewDelegate

public protocol TabBarViewDelegate: class {

    func tabBarView(_ tabBarView: TabBarView, shouldChangeToTab tab: TabBarView.Tab?) -> Bool
    func tabBarView(_ tabBarView: TabBarView, didChangeFromTab fromTab: TabBarView.Tab?, toTab: TabBarView.Tab?)
}

// MARK: - TabBarViewItemDelegate

public protocol TabBarViewItemDelegate {

    func tabBarView(_ tabBarView: TabBarView, tab: TabBarView.Tab, shouldIndicateSelected selected: Bool)
}
