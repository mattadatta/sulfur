/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public final class GridCollectionController: NSObject {

    public typealias GridRect = GridCollectionViewLayout.GridRect

    public struct ItemIndex: Hashable {

        public var section: Int
        public var rect: GridRect

        public init(rect: GridRect) {
            self.init(section: 0, rect: rect)
        }

        public init(section: Int, rect: GridRect) {
            self.section = section
            self.rect = rect
        }

        public var hashValue: Int {
            var hash = self.section.hashValue
            hash = hash &* 31 &+ self.rect.hashValue
            return hash
        }
    }

    public struct SupplementaryIndex: Hashable {

        public enum Kind {

            case Header
            case Footer

            public var collectionViewKind: String {
                switch self {
                case .Header:
                    return UICollectionElementKindSectionHeader
                case .Footer:
                    return UICollectionElementKindSectionFooter
                }
            }

            public static func kindForCollectionViewKind(elementKind: String) -> Kind? {
                switch elementKind {
                case UICollectionElementKindSectionHeader:
                    return .Header
                case UICollectionElementKindSectionFooter:
                    return .Footer
                default:
                    return nil
                }
            }
        }

        public var section: Int
        public var kind: Kind

        public init(section: Int, kind: Kind) {
            self.section = section
            self.kind = kind
        }

        public var hashValue: Int {
            var hash = self.section.hashValue
            hash = hash &* 31 &+ self.kind.hashValue
            return hash
        }
    }

    public struct Item: Hashable {

        public var index: ItemIndex
        public var controller: ItemController
        public var data: Any?

        public init(section: Int = 0, rect: GridRect, controller: ItemController, data: Any? = nil) {
            self.index = ItemIndex(section: section, rect: rect)
            self.controller = controller
            self.data = data
        }

        public var hashValue: Int {
            return self.index.hashValue
        }
    }

    public struct Supplementary: Hashable {

        public var index: SupplementaryIndex
        public var length: CGFloat
        public var insets: UIEdgeInsets
        public var controller: SupplementaryController
        public var data: Any?

        public init(section: Int = 0, kind: SupplementaryIndex.Kind, length: CGFloat, insets: UIEdgeInsets = UIEdgeInsetsZero, controller: SupplementaryController, data: Any? = nil) {
            self.index = SupplementaryIndex(section: section, kind: kind)
            self.length = length
            self.insets = insets
            self.controller = controller
            self.data = data
        }

        public var hashValue: Int {
            return self.index.hashValue
        }
    }

    public struct Component: Hashable {

        public enum Kind: Hashable {

            case Item(GridCollectionController.Item, ItemViewCell)
            case Supplementary(GridCollectionController.Supplementary, ItemReusableView)

            public var hashValue: Int {
                switch self {
                case .Item(let item, _):
                    return item.hashValue
                case .Supplementary(let supplementary, _):
                    return supplementary.hashValue
                }
            }
        }

        public var kind: Kind
        public var view: UIView?

        public init(item: Item, itemViewCell: ItemViewCell) {
            self.kind = .Item(item, itemViewCell)
            self.view = itemViewCell.nestedView
        }

        public init(supplementary: Supplementary, itemReusableView: ItemReusableView) {
            self.kind = .Supplementary(supplementary, itemReusableView)
            self.view = itemReusableView.nestedView
        }

        public var hashValue: Int {
            return self.kind.hashValue
        }

        public func attach() {
            switch self.kind {
            case .Item(let item, _):
                item.controller.attachToComponent(self)
            case .Supplementary(let supplementary, _):
                supplementary.controller.attachToComponent(self)
            }
        }

        public func detach() {
            switch self.kind {
            case .Item(let item, _):
                item.controller.detachFromComponent(self)
            case .Supplementary(let supplementary, _):
                supplementary.controller.detachFromComponent(self)
            }
        }

        public var itemAndCell: (item: Item, cell: ItemViewCell)? {
            switch self.kind {
            case .Item(let item, let cell):
                return (item, cell)
            default:
                return nil
            }
        }

        public var item: Item? {
            return self.itemAndCell?.item
        }

        public var supplementaryAndView: (supplementary: Supplementary, view: ItemReusableView)? {
            switch self.kind {
            case .Supplementary(let supplementary, let view):
                return (supplementary, view)
            default:
                return nil
            }
        }

        public var supplementary: Supplementary? {
            return self.supplementaryAndView?.supplementary
        }
    }

    public let collectionView: UICollectionView
    public let gridLayout: GridCollectionViewLayout
    public weak var delegate: GridCollectionControllerDelegate?

    private var itemIndexPaths: [ItemIndex: NSIndexPath] = [:]
    private var itemsBySection: [[Item]] = []

    public var items: [Item] = [] {
        didSet {
            let oldIdentifiers = Set(oldValue.map({ $0.controller.computedViewIdentifier }))
            let newIdentifiers = Set(self.items.map({ $0.controller.computedViewIdentifier }))
            oldIdentifiers.subtract(newIdentifiers).forEach {
                self.collectionView.registerClass(nil, forCellWithReuseIdentifier: $0)
            }
            newIdentifiers.subtract(oldIdentifiers).forEach {
                self.collectionView.registerClass(ItemViewCell.self, forCellWithReuseIdentifier: $0)
            }

            self.itemIndexPaths = [:]
            var itemsBySectionDict: [Int: [Item]] = [:]
            var maxSection = 0
            self.items.forEach { (item) in
                let section = item.index.section

                var storedItems = itemsBySectionDict[section] ?? []
                storedItems.append(item)
                itemsBySectionDict[section] = storedItems

                self.itemIndexPaths[item.index] = NSIndexPath(forItem: storedItems.count - 1, inSection: section)

                maxSection = max(maxSection, section)
            }
            self.itemsBySection = (0...maxSection).map({ itemsBySectionDict[$0] ?? [] })

            self.collectionView.reloadData()
        }
    }

    private var supplementaryIndexPaths: [SupplementaryIndex: NSIndexPath] = [:]
    private var supplementariesByIndex: [SupplementaryIndex: Supplementary] = [:]

    public var supplementaries: [Supplementary] = [] {
        didSet {
            let oldSupplementaries = Set(oldValue)
            let newSupplementaries = Set(self.supplementaries)
            oldSupplementaries.subtract(newSupplementaries).forEach { supplementary in
                self.collectionView.registerClass(
                    nil,
                    forSupplementaryViewOfKind: supplementary.index.kind.collectionViewKind,
                    withReuseIdentifier: supplementary.controller.computedViewIdentifier)
            }
            newSupplementaries.subtract(oldSupplementaries).forEach { supplementary in
                self.collectionView.registerClass(
                    ItemReusableView.self,
                    forSupplementaryViewOfKind: supplementary.index.kind.collectionViewKind,
                    withReuseIdentifier: supplementary.controller.computedViewIdentifier)
            }

            self.supplementaryIndexPaths = [:]
            self.supplementariesByIndex = [:]
            self.supplementaries.forEach { supplementary in
                self.supplementaryIndexPaths[supplementary.index] = NSIndexPath(forItem: 0, inSection: supplementary.index.section)
                self.supplementariesByIndex[supplementary.index] = supplementary
            }

            self.collectionView.reloadData()
        }
    }

    public init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        self.gridLayout = GridCollectionViewLayout()
        super.init()

        self.collectionView.collectionViewLayout = self.gridLayout
        self.collectionView.dataSource = self
        self.collectionView.delegate = self
        self.gridLayout.delegate = self
        self.collectionView.registerClass(ItemReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: "\(ItemReusableView.self)")
        self.collectionView.registerClass(ItemReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: "\(ItemReusableView.self)")
    }

    // MARK: API

    public func visibleComponents() -> [Component] {
        var components: [Component] = []
        components.appendContentsOf(self.visibleItemComponents())
        components.appendContentsOf(self.visibleSupplementaryComponentsForKind(.Header))
        components.appendContentsOf(self.visibleSupplementaryComponentsForKind(.Footer))
        return components
    }

    public func visibleItemComponents() -> [Component] {
        return self.collectionView.indexPathsForVisibleItems().map({ self.itemComponentForIndexPath($0)! })
    }

    public func visibleSupplementaryComponentsForKind(kind: SupplementaryIndex.Kind) -> [Component] {
        return self.collectionView.indexPathsForVisibleSupplementaryElementsOfKind(kind.collectionViewKind).map({
            self.supplementaryComponentOfKind(kind, forIndexPath: $0)
        }).flatMap({ $0 })
    }

    public func componentForItemIndex(index: ItemIndex) -> Component? {
        guard let indexPath = self.itemIndexPaths[index] else {
            return nil
        }
        return self.itemComponentForIndexPath(indexPath)
    }

    public func componentForSupplementaryIndex(index: SupplementaryIndex) -> Component? {
        guard let indexPath = self.supplementaryIndexPaths[index] else {
            return nil
        }
        return self.supplementaryComponentOfKind(index.kind, forIndexPath: indexPath)
    }

    // MARK: Internal

    private func itemComponentForIndexPath(indexPath: NSIndexPath) -> Component? {
        guard let cell = self.collectionView.cellForItemAtIndexPath(indexPath) else {
            return nil
        }
        return self.itemComponentForIndexPath(indexPath, cell: cell)
    }

    private func supplementaryComponentOfKind(kind: SupplementaryIndex.Kind, forIndexPath indexPath: NSIndexPath) -> Component? {
        // Uhh?
        let view = self.collectionView.supplementaryViewForElementKind(kind.collectionViewKind, atIndexPath: indexPath)
        return self.supplementaryComponentOfKind(kind, forSection: indexPath.section, view: view)
    }

    private func itemComponentForIndexPath(indexPath: NSIndexPath, cell: UICollectionViewCell) -> Component {
        let item = self.itemForIndexPath(indexPath)
        let itemCell = cell as! ItemViewCell
        return Component(item: item, itemViewCell: itemCell)
    }

    private func supplementaryComponentOfCollectionViewKind(elementKind: String, forSection section: Int, view: UICollectionReusableView) -> Component? {
        guard let kind = GridCollectionController.SupplementaryIndex.Kind.kindForCollectionViewKind(elementKind) else {
            return nil
        }
        return supplementaryComponentOfKind(kind, forSection: section, view: view)
    }

    private func supplementaryComponentOfKind(kind: SupplementaryIndex.Kind, forSection section: Int, view: UICollectionReusableView) -> Component? {
        guard let supplementary = self.supplementaryOfKind(kind, forSection: section) else {
            return nil
        }
        let supplementaryView = view as! ItemReusableView
        return Component(supplementary: supplementary, itemReusableView: supplementaryView)
    }

    private func itemForIndexPath(indexPath: NSIndexPath) -> Item {
        return self.itemsBySection[indexPath.section][indexPath.row]
    }

    private func supplementaryOfCollectionViewKind(elementKind: String, forSection section: Int) -> Supplementary? {
        guard let kind = GridCollectionController.SupplementaryIndex.Kind.kindForCollectionViewKind(elementKind) else {
            return nil
        }
        return self.supplementaryOfKind(kind, forSection: section)
    }

    private func supplementaryOfKind(kind: SupplementaryIndex.Kind, forSection section: Int) -> Supplementary? {
        return self.supplementariesByIndex[SupplementaryIndex(section: section, kind: kind)]
    }
}

public func == (lhs: GridCollectionController.ItemIndex, rhs: GridCollectionController.ItemIndex) -> Bool {
    return lhs.section == rhs.section && lhs.rect == rhs.rect
}

public func == (lhs: GridCollectionController.SupplementaryIndex, rhs: GridCollectionController.SupplementaryIndex) -> Bool {
    return lhs.section == rhs.section && lhs.kind == rhs.kind
}

public func == (lhs: GridCollectionController.Item, rhs: GridCollectionController.Item) -> Bool {
    return lhs.index == rhs.index && ObjectIdentifier(lhs.controller) == ObjectIdentifier(rhs.controller)
}

public func == (lhs: GridCollectionController.Supplementary, rhs: GridCollectionController.Supplementary) -> Bool {
    return lhs.index == rhs.index && ObjectIdentifier(lhs.controller) == ObjectIdentifier(rhs.controller)
}

public func == (lhs: GridCollectionController.Component, rhs: GridCollectionController.Component) -> Bool {
    return lhs.kind == rhs.kind
}

public func == (lhs: GridCollectionController.Component.Kind, rhs: GridCollectionController.Component.Kind) -> Bool {
    switch (lhs, rhs) {
    case (.Item(let lhs, _), .Item(let rhs, _)):
        return lhs == rhs
    case (.Supplementary(let lhs, _), .Supplementary(let rhs, _)):
        return lhs == rhs
    default:
        return false
    }
}

// MARK: - GridCollectionControllerDelegate

public protocol GridCollectionControllerDelegate: class {

    func gridCollectionController(gridCollectionController: GridCollectionController, didSelect component: GridCollectionController.Component)
}

private extension GridCollectionController {

    func didSelectComponent(component: Component) {
        self.delegate?.gridCollectionController(self, didSelect: component)
    }
}

extension GridCollectionController: UICollectionViewDataSource, UICollectionViewDelegate, GridCollectionViewLayoutDelegate {

    // MARK: UICollectionView

    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.itemsBySection.count
    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemsBySection[section].count
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let item = self.itemForIndexPath(indexPath)
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.controller.computedViewIdentifier, forIndexPath: indexPath) as! ItemViewCell
        cell.nestedView = item.controller.viewForItem(item, reusingView: cell.nestedView)
        let component = self.itemComponentForIndexPath(indexPath, cell: cell)
        component.attach()
        return cell
    }

    public func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        let component = self.itemComponentForIndexPath(indexPath, cell: cell)
        component.detach()
    }

    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        guard let supplementary = self.supplementaryOfCollectionViewKind(kind, forSection: indexPath.section) else {
            return collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: ItemReusableView.cellIdentifier, forIndexPath: indexPath)
        }

        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: supplementary.controller.computedViewIdentifier, forIndexPath: indexPath) as! ItemReusableView
        view.nestedView = supplementary.controller.viewForSupplementary(supplementary, reusingView: view.nestedView)
        guard let component = self.supplementaryComponentOfCollectionViewKind(kind, forSection: indexPath.section, view: view) else {
            return view
        }
        component.attach()
        return view
    }

    public func collectionView(collectionView: UICollectionView, didEndDisplayingSupplementaryView view: UICollectionReusableView, forElementOfKind elementKind: String, atIndexPath indexPath: NSIndexPath) {
        guard let component = self.supplementaryComponentOfCollectionViewKind(elementKind, forSection: indexPath.section, view: view) else {
            return
        }
        component.detach()
    }

    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath)!
        let component = self.itemComponentForIndexPath(indexPath, cell: cell)
        self.didSelectComponent(component)
    }

    // MARK: GridCollectionViewLayout

    public func gridCollectionViewLayout(layout: GridCollectionViewLayout, rectForIndexPath indexPath: NSIndexPath) -> GridCollectionViewLayout.GridRect {
        return self.itemForIndexPath(indexPath).index.rect
    }

    public func gridCollectionViewLayout(layout: GridCollectionViewLayout, propertiesForHeaderForSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties? {
        guard let supplementary = self.supplementaryOfKind(.Header, forSection: section) else {
            return nil
        }
        return GridCollectionViewLayout.SupplementaryProperties(length: supplementary.length, insets: supplementary.insets)
    }

    public func gridCollectionViewLayout(layout: GridCollectionViewLayout, propertiesForFooterForSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties? {
        guard let supplementary = self.supplementaryOfKind(.Footer, forSection: section) else {
            return nil
        }
        return GridCollectionViewLayout.SupplementaryProperties(length: supplementary.length, insets: supplementary.insets)
    }
}

public final class ItemViewCell: UICollectionViewCell {

    public internal(set) var nestedView: UIView? {
        willSet {
            guard self.nestedView != newValue else {
                return
            }
            guard let view = self.nestedView else {
                return
            }
            view.removeFromSuperview()
        }
        didSet {
            guard self.nestedView != oldValue else {
                return
            }
            guard let view = self.nestedView else {
                return
            }
            self.contentView.addAndConstrainView(view)
        }
    }
}

public final class ItemReusableView: UICollectionReusableView {

    static let cellIdentifier = "\(ItemReusableView.self)"

    public internal(set) var nestedView: UIView? {
        willSet {
            guard self.nestedView != newValue else {
                return
            }
            guard let view = self.nestedView else {
                return
            }
            view.removeFromSuperview()
        }
        didSet {
            guard self.nestedView != oldValue else {
                return
            }
            guard let view = self.nestedView else {
                return
            }
            self.addAndConstrainView(view)
        }
    }
}

public protocol ComponentController: class {

    var viewIdentifier: String? { get }
    func attachToComponent(component: GridCollectionController.Component)
    func detachFromComponent(component: GridCollectionController.Component)
}

private extension ComponentController {

    var computedViewIdentifier: String {
        return self.viewIdentifier ?? String(Self)
    }
}

public protocol ItemController: ComponentController {

    func viewForItem(item: GridCollectionController.Item, reusingView reuseView: UIView?) -> UIView
}

public protocol SupplementaryController: ComponentController {

    func viewForSupplementary(supplementary: GridCollectionController.Supplementary, reusingView reuseView: UIView?) -> UIView
}

// MARK: LinearGrid

public struct LinearGrid {

    public var numUnits: Int
    public var direction: GridCollectionViewLayout.Direction

    public init(numUnits: Int, direction: GridCollectionViewLayout.Direction = .Vertical) {
        self.numUnits = numUnits
        self.direction = direction
    }

    public func rect(forIndex index: Int, width: CGFloat = 1.0, height: CGFloat = 1.0) -> GridCollectionViewLayout.GridRect {
        switch self.direction {
        case .Vertical:
            return GridCollectionViewLayout.GridRect(
                x: CGFloat(index % self.numUnits),
                y: CGFloat(index / self.numUnits),
                width: width,
                height: height)
        case .Horizontal:
            return GridCollectionViewLayout.GridRect(
                x: CGFloat(index / self.numUnits),
                y: CGFloat(index % self.numUnits),
                width: width,
                height: height)
        }

    }
}
