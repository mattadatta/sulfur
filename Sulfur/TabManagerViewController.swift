/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Cartography

// MARK: - TabManagerViewController

public final class TabManagerViewController: UIViewController {

    public typealias TabItem = TabManagerView.TabItem
    public typealias TabItemViewBinding = TabManagerView.TabItemViewBinding
    public typealias TabItemViewControllerBinding = TabItemBinding<UIViewController>

    private var tabMappings: [TabItem: TabItemViewControllerBinding] = [:]
    public var tabBindings: [TabItemViewControllerBinding] = [] {
        didSet {
            self.tabManagerView.tabBindings = self.tabBindings.map { viewControllerBinding in
                return TabItemViewBinding(
                    tabItem: viewControllerBinding.tabItem,
                    action: {
                        switch viewControllerBinding.action {
                        case .performAction(let performAction):
                            return .performAction(performAction)

                        case .displayContent(let retrieveViewController):
                            return .displayContent({ [weak self] tabItem in
                                let viewController = retrieveViewController(tabItem)
                                self?.activeViewController = viewController
                                return viewController.view
                                })
                        }
                    }())
            }
            self.tabMappings = self.tabBindings.reduce([:]) { partial, binding in
                var dict = partial
                dict[binding.tabItem] = binding
                return dict
            }
        }
    }

    public weak var delegate: TabManagerViewControllerDelegate?

    public private(set) var activeViewController: UIViewController?

    public private(set) weak var tabManagerView: TabManagerView!
    public var tabBarView: TabBarView {
        return self.tabManagerView.tabBarView
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
        let tabManagerView = TabManagerView()
        self.view = tabManagerView
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        self.tabManagerView = self.view as! TabManagerView
        self.tabManagerView.translatesAutoresizingMaskIntoConstraints = false
        self.tabManagerView.delegate = self
    }
}

// MARK: - TabManagerViewControllerDelegate

public protocol TabManagerViewControllerDelegate: class {

    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, isTabItemEnabled tabItem: TabBarView.TabItem?) -> Bool
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?)
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, willRemove viewController: UIViewController, for tabItem: TabBarView.TabItem)
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, didRemove viewController: UIViewController, for tabItem: TabBarView.TabItem)
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, willAdd viewController: UIViewController, for tabItem: TabBarView.TabItem)
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, didAdd viewController: UIViewController, for tabItem: TabBarView.TabItem)
}

// MARK: - TabManagerViewController: TabManagerViewDelegate

extension TabManagerViewController: TabManagerViewDelegate {

    public func tabManagerView(_ tabManagerView: TabManagerView, isTabItemEnabled tabItem: TabBarView.TabItem?) -> Bool {
        return self.delegate?.tabManagerViewController(self, isTabItemEnabled: tabItem) ?? true
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?) {
        self.delegate?.tabManagerViewController(self, didChangeFromTabItem: fromTabItem, toTabItem: toTabItem)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, willRemove view: UIView, for tabItem: TabBarView.TabItem) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabManagerViewController(self, willRemove: viewController, for: tabItem)
        viewController.willMove(toParentViewController: nil)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, didRemove view: UIView, for tabItem: TabBarView.TabItem) {
        guard let viewController = self.activeViewController else { return }
        viewController.removeFromParentViewController()
        self.activeViewController = nil
        self.delegate?.tabManagerViewController(self, didRemove: viewController, for: tabItem)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, willAdd view: UIView, for tabItem: TabBarView.TabItem) {
        guard let viewController = self.activeViewController else { return }
        self.delegate?.tabManagerViewController(self, willAdd: viewController, for: tabItem)
        self.addChildViewController(viewController)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, didAdd view: UIView, for tabItem: TabBarView.TabItem) {
        guard let viewController = self.activeViewController else { return }
        viewController.didMove(toParentViewController: self)
        self.delegate?.tabManagerViewController(self, didAdd: viewController, for: tabItem)
    }
}

// MARK: - TabManagerView

public final class TabManagerView: UIView {

    public typealias TabItem = TabBarView.TabItem
    public typealias TabItemViewBinding = TabItemBinding<UIView>

    private weak var containerView: UIView!
    public private(set) weak var tabBarView: TabBarView!

    private var tabMappings: [TabItem: TabItemViewBinding] = [:]
    public var tabBindings: [TabItemViewBinding] = [] {
        didSet {
            self.tabBarView.tabItems = self.tabBindings.map({ $0.tabItem })
            self.tabMappings = self.tabBindings.reduce([:]) { partial, binding in
                var dict = partial
                dict[binding.tabItem] = binding
                return dict
            }
        }
    }

    public weak var delegate: TabManagerViewDelegate?

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

// MARK: - TabManagerViewDelegate

public protocol TabManagerViewDelegate: class {

    func tabManagerView(_ tabManagerView: TabManagerView, isTabItemEnabled tabItem: TabBarView.TabItem?) -> Bool
    func tabManagerView(_ tabManagerView: TabManagerView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?)
    func tabManagerView(_ tabManagerView: TabManagerView, willRemove view: UIView, for tabItem: TabBarView.TabItem)
    func tabManagerView(_ tabManagerView: TabManagerView, didRemove view: UIView, for tabItem: TabBarView.TabItem)
    func tabManagerView(_ tabManagerView: TabManagerView, willAdd view: UIView, for tabItem: TabBarView.TabItem)
    func tabManagerView(_ tabManagerView: TabManagerView, didAdd view: UIView, for tabItem: TabBarView.TabItem)
}

// MARK: - TabManagerView: TabBarViewDelegate

extension TabManagerView: TabBarViewDelegate {

    public func tabBarView(_ tabBarView: TabBarView, shouldChangeTo tabItem: TabBarView.TabItem?) -> Bool {
        let isEnabled = self.delegate?.tabManagerView(self, isTabItemEnabled: tabItem) ?? true
        guard let tabItem = tabItem, let binding = self.tabMappings[tabItem] else { return isEnabled }
        return isEnabled && binding.action.isDisplayContent
    }

    public func tabBarView(_ tabBarView: TabBarView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?) {
        if let activeView = self.activeView, let tabItem = fromTabItem {
            self.delegate?.tabManagerView(self, willRemove: activeView, for: tabItem)
            activeView.removeFromSuperview()
            self.activeView = nil
            self.delegate?.tabManagerView(self, didRemove: activeView, for: tabItem)
        }

        guard let tabItem = toTabItem else { return }
        guard let binding = self.tabMappings[tabItem] else { return }
        switch binding.action {
        case .performAction(let performAction):
            performAction(tabItem)

        case .displayContent(let retrieveView):
            let view = retrieveView(tabItem)
            self.delegate?.tabManagerView(self, willAdd: view, for: tabItem)
            self.containerView.addAndConstrain(view)
            self.activeView = view
            self.delegate?.tabManagerView(self, didAdd: view, for: tabItem)
        }
    }
}

public enum TabItemAction<ContentType> {

    public typealias TabItem = TabBarView.TabItem
    public typealias PerformAction = (TabItem) -> Void
    public typealias RetrieveContent = (TabItem) -> ContentType

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

public struct TabItemBinding<ContentType>: Hashable {

    public typealias TabItem = TabBarView.TabItem

    public var tabItem: TabItem
    public var action: TabItemAction<ContentType>

    public init(tabItem: TabItem, action: TabItemAction<ContentType>) {
        self.tabItem = tabItem
        self.action = action
    }

    // MARK: Hashable conformance

    public var hashValue: Int {
        return self.tabItem.hashValue
    }

    public static func ==<ContentType> (lhs: TabItemBinding<ContentType>, rhs: TabItemBinding<ContentType>) -> Bool {
        return lhs.tabItem == rhs.tabItem
    }
}

// MARK: - TabBarView

public final class TabBarView: UIView {

    public struct TabItem: Hashable {

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

        public static func == (lhs: TabItem, rhs: TabItem) -> Bool {
            return lhs.tag == rhs.tag
        }
    }

    private final class TabItemManager {

        unowned let tabBarView: TabBarView
        let tabItem: TabItem
        let index: Int

        let tabItemView = TabItemView()
        let tapGestureRecognizer = UITapGestureRecognizer()

        init(tabBarView: TabBarView, tabItem: TabItem, index: Int) {
            self.tabBarView = tabBarView
            self.tabItem = tabItem
            self.index = index

            self.tabItemView.translatesAutoresizingMaskIntoConstraints = false
            self.tabItemView.addAndConstrain(self.tabItem.view)

            self.tapGestureRecognizer.addTarget(self, action: #selector(self.tabItemViewDidTap(_:)))
            self.tabItemView.addGestureRecognizer(self.tapGestureRecognizer)
        }

        dynamic func tabItemViewDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
            if tapGestureRecognizer.state == .ended {
                self.tabBarView.didTapView(for: self)
            }
        }

        func uninstall() {
            self.tabItemView.removeGestureRecognizer(self.tapGestureRecognizer)
            self.tabItemView.removeFromSuperview()
            self.tabItem.view.removeFromSuperview()
        }
    }

    public var tabItems: [TabItem] {
        get { return self.tabItemManagers.map({ $0.tabItem }) }
        set(newTabItems) {
            self.tabItemManagers = newTabItems.enumerated().map({ TabItemManager(tabBarView: self, tabItem: $1, index: $0) })
            self._selectedIndex = nil
            self.desiredIndex = self.tabItemManagers.isEmpty ? nil : 0
            self.forceTabReselection = true
            self.setNeedsLayout()
        }
    }

    private var tabItemManagers: [TabItemManager] = [] {
        willSet {
            self.tabItemManagers.forEach { tabItemManager in
                tabItemManager.uninstall()
            }
        }
        didSet {
            self.tabItemManagers.forEach { tabItemManager in
                self.stackView.addArrangedSubview(tabItemManager.tabItemView)
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
        if index < 0 || index >= self.tabItemManagers.count {
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

        let desiredTabItemManager = self.tabItemManager(forIndex: self.desiredIndex)
        let shouldChangeTo = self.delegate?.tabBarView(self, shouldChangeTo: desiredTabItemManager?.tabItem) ?? true

        guard shouldChangeTo else { return }

        let currentTabItemManager = self.tabItemManager(forIndex: self._selectedIndex)
        self._selectedIndex = desiredTabItemManager?.index

        let indicateSelected = { (manager: TabItemManager?, selected: Bool) in
            guard let manager = manager else { return }
            manager.tabItem.delegate?.tabBarView(self, tabItem: manager.tabItem, shouldIndicateSelected: selected)
        }

        indicateSelected(currentTabItemManager, false)
        indicateSelected(desiredTabItemManager, true)
        self.dirtySelection = false
        self.forceTabReselection = false
        self.delegate?.tabBarView(self, didChangeFromTabItem: currentTabItemManager?.tabItem, toTabItem: desiredTabItemManager?.tabItem)
    }

    public var selectedTab: (index: Int, item: TabItem)? {
        guard let selectedIndex = self.selectedIndex else {
            return nil
        }
        return (selectedIndex, self.tabItemManagers[selectedIndex].tabItem)
    }

    private func tabItemManager(forIndex index: Int?) -> TabItemManager? {
        if let index = index {
            return self.tabItemManagers[index]
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

    private func didTapView(for tabItemManager: TabItemManager) {
        self.setDesiredIndex(tabItemManager.index, needsLayout: false)
        self.updateSelectedIndexIfNecessary()
    }
}
// performAction, displayContent

// MARK: - TabItemView

private final class TabItemView: UIView {

}

// MARK: - TabBarViewDelegate

public protocol TabBarViewDelegate: class {

    func tabBarView(_ tabBarView: TabBarView, shouldChangeTo tabItem: TabBarView.TabItem?) -> Bool
    func tabBarView(_ tabBarView: TabBarView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?)
}

// MARK: - TabBarViewItemDelegate

public protocol TabBarViewItemDelegate {

    func tabBarView(_ tabBarView: TabBarView, tabItem: TabBarView.TabItem, shouldIndicateSelected selected: Bool)
}
