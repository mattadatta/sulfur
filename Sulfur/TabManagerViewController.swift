/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit
import Cartography

// MARK: - TabManagerViewController

public final class TabManagerViewController: UIViewController {

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

    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, didSelectTabItem tabItem: TabBarView.TabItem?) -> Bool
    func tabManagerViewController(_ tabManagerViewController: TabManagerViewController, viewControllerForTabItem tabItem: TabBarView.TabItem?) -> UIViewController
}

private extension TabManagerViewController {

    func didSelectTabItem(_ tabItem: TabBarView.TabItem?) -> Bool {
        return self.delegate!.tabManagerViewController(self, didSelectTabItem: tabItem)
    }

    func viewControllerForTabItem(_ tabItem: TabBarView.TabItem?) -> UIViewController {
        return self.delegate!.tabManagerViewController(self, viewControllerForTabItem: tabItem)
    }
}

// MARK: - TabManagerViewController: TabManagerViewDelegate

extension TabManagerViewController: TabManagerViewDelegate {

    public func tabManagerView(_ tabManagerView: TabManagerView, didSelectTabItem tabItem: TabBarView.TabItem?) -> Bool {
        return self.didSelectTabItem(tabItem)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, viewForTabItem tabItem: TabBarView.TabItem?) -> UIView {
        let viewController = self.viewControllerForTabItem(tabItem)
        self.activeViewController = viewController
        return viewController.view
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, willRemoveView view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.activeViewController?.willMove(toParentViewController: nil)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, didRemoveView view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.activeViewController?.removeFromParentViewController()
        self.activeViewController = nil
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, willAddView view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.addChildViewController(self.activeViewController!)
    }

    public func tabManagerView(_ tabManagerView: TabManagerView, didAddView view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.activeViewController?.didMove(toParentViewController: self)
    }
}

// MARK: - TabManagerView

public final class TabManagerView: UIView {

    private weak var containerView: UIView!
    public private(set) var tabBarView: TabBarView!
    public weak var delegate: TabManagerViewDelegate?

    public private(set) var activeView: UIView?

    private var tabBarHeightConstraintGroup: ConstraintGroup!

    public var tabBarHeight: CGFloat = 60 {
        didSet {
            guard self.tabBarHeight != oldValue else {
                return
            }
            self.tabBarHeightConstraintGroup = constrain(self.tabBarView, replace: self.tabBarHeightConstraintGroup) { (tabBarView) in
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
        self.addAndConstrainView(containerView)
        self.containerView = containerView

        let tabBarView = TabBarView()
        tabBarView.delegate = self
        tabBarView.translatesAutoresizingMaskIntoConstraints = false
        self.tabBarView = tabBarView
        self.addSubview(tabBarView)
        constrain(self, self.tabBarView) { (superview, tabBarView) in
            superview.left == tabBarView.left
            superview.right == tabBarView.right
            superview.bottom == tabBarView.bottom
        }

        self.tabBarHeightConstraintGroup = constrain(self.tabBarView) { (tabBarView) in
            tabBarView.height == self.tabBarHeight
        }
    }
}

// MARK: - TabManagerViewDelegate

public protocol TabManagerViewDelegate: class {

    func tabManagerView(_ tabManagerView: TabManagerView, didSelectTabItem tabItem: TabBarView.TabItem?) -> Bool
    func tabManagerView(_ tabManagerView: TabManagerView, viewForTabItem tabItem: TabBarView.TabItem?) -> UIView

    func tabManagerView(_ tabManagerView: TabManagerView, willRemoveView view: UIView, forTabItem tabItem: TabBarView.TabItem?)
    func tabManagerView(_ tabManagerView: TabManagerView, didRemoveView view: UIView, forTabItem tabItem: TabBarView.TabItem?)
    func tabManagerView(_ tabManagerView: TabManagerView, willAddView view: UIView, forTabItem tabItem: TabBarView.TabItem?)
    func tabManagerView(_ tabManagerView: TabManagerView, didAddView view: UIView, forTabItem tabItem: TabBarView.TabItem?)
}

private extension TabManagerView {

    func didSelectTabItem(_ tabItem: TabBarView.TabItem?) -> Bool {
        return self.delegate!.tabManagerView(self, didSelectTabItem: tabItem)
    }

    func viewForTabItem(_ tabItem: TabBarView.TabItem?) -> UIView {
        return self.delegate!.tabManagerView(self, viewForTabItem: tabItem)
    }

    func willRemoveView(_ view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.delegate!.tabManagerView(self, willRemoveView: view, forTabItem: tabItem)
    }

    func didRemoveView(_ view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.delegate!.tabManagerView(self, didRemoveView: view, forTabItem: tabItem)
    }

    func willAddView(_ view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.delegate!.tabManagerView(self, willAddView: view, forTabItem: tabItem)
    }

    func didAddView(_ view: UIView, forTabItem tabItem: TabBarView.TabItem?) {
        self.delegate!.tabManagerView(self, didAddView: view, forTabItem: tabItem)
    }
}

// MARK: - TabManagerView: TabBarViewDelegate

extension TabManagerView: TabBarViewDelegate {

    public func tabBarView(_ tabBarView: TabBarView, didSelectTabItem tabItem: TabBarView.TabItem?) -> Bool {
        return self.didSelectTabItem(tabItem)
    }

    public func tabBarView(_ tabBarView: TabBarView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?) {
        if let activeView = self.activeView {
            self.willRemoveView(activeView, forTabItem: fromTabItem)
            activeView.removeFromSuperview()
            self.didRemoveView(activeView, forTabItem: fromTabItem)
            self.activeView = nil
        }

        let view = self.viewForTabItem(toTabItem)
        self.willAddView(view, forTabItem: toTabItem)
        self.containerView.addAndConstrainView(view)
        self.didAddView(view, forTabItem: toTabItem)
        self.activeView = view
    }
}

// MARK: - TabBarView

public final class TabBarView: UIView {

    public struct TabItem {

        public let tag: String
        public let view: UIView
        public let delegate: TabBarViewItemDelegate?

        public init(tag: String, view: UIView, delegate: TabBarViewItemDelegate? = nil) {
            self.tag = tag
            self.view = view
            self.delegate = delegate ?? (view as? TabBarViewItemDelegate)
        }
    }

    private final class TabItemManager {

        unowned let tabBarView: TabBarView

        let tabItem: TabItem
        let index: Int
        let tabItemView: TabItemView
        let tapGestureRecognizer: UITapGestureRecognizer

        init(tabBarView: TabBarView, tabItem: TabItem, index: Int) {
            self.tabBarView = tabBarView
            self.tabItem = tabItem
            self.index = index
            self.tabItemView = TabItemView()
            self.tapGestureRecognizer = UITapGestureRecognizer()

            self.tabItemView.translatesAutoresizingMaskIntoConstraints = false
            self.tabItemView.addAndConstrainView(self.tabItem.view)

            self.tapGestureRecognizer.addTarget(self, action: #selector(TabItemManager.tabItemViewDidTap(_:)))
            self.tabItemView.addGestureRecognizer(self.tapGestureRecognizer)
        }

        dynamic func tabItemViewDidTap(_ tapGestureRecognizer: UITapGestureRecognizer) {
            if tapGestureRecognizer.state == .ended {
                self.tabBarView.didTapViewWithTabItemManager(self)
            }
        }

        func cleanup() {
            self.tabItemView.removeGestureRecognizer(self.tapGestureRecognizer)
            self.tabItemView.removeFromSuperview()
            self.tabItem.view.removeFromSuperview()
        }
    }

    public var tabItems: [TabItem] {
        get {
            return self.tabItemManagers.map({ $0.tabItem })
        }
        set(newTabItems) {
            self.tabItemManagers = newTabItems.enumerated().map({ TabItemManager(tabBarView: self, tabItem: $1, index: $0) })
            self.selectedIndex = self.tabItemManagers.isEmpty ? nil : 0
            self.forceTabReselection = true
            self.setNeedsLayout()
        }
    }

    private var tabItemManagers: [TabItemManager] = [] {
        willSet {
            self.tabItemManagers.forEach { (tabItemManager) in
                tabItemManager.cleanup()
            }
        }
        didSet {
            self.tabItemManagers.forEach { (tabItemManager) in
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
            if self.dirtySelection {
                return self.desiredIndex
            }
            return self._selectedIndex
        }
        set {
            self.shouldChangeToIndex(newValue)
        }
    }

    private func shouldChangeToIndex(_ index: Int?) {
        if index < 0 || index >= self.tabItemManagers.count {
            self.desiredIndex = nil
        } else {
            self.desiredIndex = index
        }

        self.dirtySelection = (self.desiredIndex != self._selectedIndex)

        if self.dirtySelection {
            self.setNeedsLayout()
        }
    }

    private func ensureDesiredIndexSelected() {
        guard self.dirtySelection || self.forceTabReselection else {
            return
        }

        self.dirtySelection = false
        self.forceTabReselection = false

        let desiredTabItemManager = self.tabItemManagerForIndex(self.desiredIndex)
        let shouldSelectTab = self.didSelectTabItem(desiredTabItemManager?.tabItem)

        guard shouldSelectTab else {
            return
        }

        let currentTabItemManager = self.tabItemManagerForIndex(self._selectedIndex)

        self._selectedIndex = desiredTabItemManager?.index

        if let tabItemManager = currentTabItemManager {
            tabItemManager.tabItem.delegate?.tabBarView(self, tabItem: tabItemManager.tabItem, shouldIndicateSelected: false)
        }
        if let tabItemManager = desiredTabItemManager {
            tabItemManager.tabItem.delegate?.tabBarView(self, tabItem: tabItemManager.tabItem, shouldIndicateSelected: true)
        }

        self.didChangeFromTabItem(currentTabItemManager?.tabItem, toTabItem: desiredTabItemManager?.tabItem)
    }

    public var selectedTab: (index: Int, item: TabItem)? {
        guard let selectedIndex = self.selectedIndex else {
            return nil
        }
        return (selectedIndex, self.tabItemManagers[selectedIndex].tabItem)
    }

    private func tabItemManagerForIndex(_ index: Int?) -> TabItemManager? {
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
        self.addAndConstrainView(stackView)
        self.stackView = stackView
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        self.ensureDesiredIndexSelected()
    }

    private func didTapViewWithTabItemManager(_ tabItemManager: TabItemManager) {
        self.shouldChangeToIndex(tabItemManager.index)
        self.ensureDesiredIndexSelected()
    }
}

// MARK: - TabItemView

private final class TabItemView: UIView {

}

// MARK: - TabBarViewDelegate

public protocol TabBarViewDelegate: class {

    func tabBarView(_ tabBarView: TabBarView, didSelectTabItem tabItem: TabBarView.TabItem?) -> Bool
    func tabBarView(_ tabBarView: TabBarView, didChangeFromTabItem fromTabItem: TabBarView.TabItem?, toTabItem: TabBarView.TabItem?)
}

private extension TabBarView {

    func didSelectTabItem(_ tabItem: TabItem?) -> Bool {
        return self.delegate?.tabBarView(self, didSelectTabItem: tabItem) ?? true
    }

    func didChangeFromTabItem(_ fromTabItem: TabItem?, toTabItem: TabItem?) {
        self.delegate?.tabBarView(self, didChangeFromTabItem: fromTabItem, toTabItem: toTabItem)
    }
}

// MARK: - TabBarViewItemDelegate

public protocol TabBarViewItemDelegate {

    func tabBarView(_ tabBarView: TabBarView, tabItem: TabBarView.TabItem, shouldIndicateSelected selected: Bool)
}
