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
            return Hasher()
                .adding(part: self.section)
                .adding(hashable: self.rect)
                .hashValue
        }
    }

    public struct SupplementaryIndex: Hashable {

        public enum Kind {

            case header
            case footer

            public var collectionViewKind: String {
                switch self {
                case .header:
                    return UICollectionElementKindSectionHeader
                case .footer:
                    return UICollectionElementKindSectionFooter
                }
            }

            public static func kind(forCollectionViewKind elementKind: String) -> Kind? {
                switch elementKind {
                case UICollectionElementKindSectionHeader:
                    return .header
                case UICollectionElementKindSectionFooter:
                    return .footer
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
            return Hasher()
                .adding(part: self.section)
                .adding(hashable: self.kind)
                .hashValue
        }
    }

    public struct Item: Hashable {

        public var index: ItemIndex
        public var insets: UIEdgeInsets
        public var controller: ItemController
        public var data: Any?

        public init(section: Int = 0, rect: GridRect, insets: UIEdgeInsets = .zero, controller: ItemController, data: Any? = nil) {
            self.index = ItemIndex(section: section, rect: rect)
            self.insets = insets
            self.controller = controller
            self.data = data
        }

        public var hashValue: Int {
            return self.index.hashValue
        }
    }

    public struct Supplementary: Hashable {

        public var index: SupplementaryIndex
        public var properties: GridCollectionViewLayout.SupplementaryProperties
        public var controller: SupplementaryController
        public var data: Any?

        public init(section: Int = 0, kind: SupplementaryIndex.Kind, properties: GridCollectionViewLayout.SupplementaryProperties, controller: SupplementaryController, data: Any? = nil) {
            self.index = SupplementaryIndex(section: section, kind: kind)
            self.properties = properties
            self.controller = controller
            self.data = data
        }

        public var hashValue: Int {
            return self.index.hashValue
        }
    }

    public struct Component: Hashable {

        public enum Kind: Hashable {

            case item(GridCollectionController.Item, ItemViewCell)
            case supplementary(GridCollectionController.Supplementary, ItemReusableView)

            public var hashValue: Int {
                switch self {
                case .item(let item, _):
                    return item.hashValue
                case .supplementary(let supplementary, _):
                    return supplementary.hashValue
                }
            }
        }

        public var kind: Kind
        public var view: UIView?

        public init(item: Item, itemViewCell: ItemViewCell) {
            self.kind = .item(item, itemViewCell)
            self.view = itemViewCell.nestedView
        }

        public init(supplementary: Supplementary, itemReusableView: ItemReusableView) {
            self.kind = .supplementary(supplementary, itemReusableView)
            self.view = itemReusableView.nestedView
        }

        public var hashValue: Int {
            return self.kind.hashValue
        }

        public func attach() {
            switch self.kind {
            case .item(let item, _):
                item.controller.attach(to: self)
            case .supplementary(let supplementary, _):
                supplementary.controller.attach(to: self)
            }
        }

        public func detach() {
            switch self.kind {
            case .item(let item, _):
                item.controller.detach(from: self)
            case .supplementary(let supplementary, _):
                supplementary.controller.detach(from: self)
            }
        }

        public var itemAndCell: (item: Item, cell: ItemViewCell)? {
            switch self.kind {
            case .item(let item, let cell):
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
            case .supplementary(let supplementary, let view):
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

    private var itemIndexPaths: [ItemIndex: IndexPath] = [:]
    private var itemsBySection: [[Item]] = []

    public var items: [Item] = [] {
        didSet {
            let oldIdentifiers = Set(oldValue.map({ $0.controller.computedViewIdentifier }))
            let newIdentifiers = Set(self.items.map({ $0.controller.computedViewIdentifier }))
            oldIdentifiers.subtracting(newIdentifiers).forEach {
                self.collectionView.register(nil as AnyClass?, forCellWithReuseIdentifier: $0)
            }
            newIdentifiers.subtracting(oldIdentifiers).forEach {
                self.collectionView.register(ItemViewCell.self, forCellWithReuseIdentifier: $0)
            }

            self.itemIndexPaths = [:]
            var itemsBySectionDict: [Int: [Item]] = [:]
            var maxSection = 0
            self.items.forEach { (item) in
                let section = item.index.section

                var storedItems = itemsBySectionDict[section] ?? []
                storedItems.append(item)
                itemsBySectionDict[section] = storedItems

                self.itemIndexPaths[item.index] = IndexPath(item: storedItems.count - 1, section: section)

                maxSection = max(maxSection, section)
            }
            self.itemsBySection = (0...maxSection).map({ itemsBySectionDict[$0] ?? [] })

            self.collectionView.reloadData()
        }
    }

    private var supplementaryIndexPaths: [SupplementaryIndex: IndexPath] = [:]
    private var supplementariesByIndex: [SupplementaryIndex: Supplementary] = [:]

    public var supplementaries: [Supplementary] = [] {
        didSet {
            let oldSupplementaries = Set(oldValue)
            let newSupplementaries = Set(self.supplementaries)
            oldSupplementaries.subtracting(newSupplementaries).forEach { supplementary in
                self.collectionView.register(
                    nil as AnyClass?,
                    forSupplementaryViewOfKind: supplementary.index.kind.collectionViewKind,
                    withReuseIdentifier: supplementary.controller.computedViewIdentifier)
            }
            newSupplementaries.subtracting(oldSupplementaries).forEach { supplementary in
                self.collectionView.register(
                    ItemReusableView.self,
                    forSupplementaryViewOfKind: supplementary.index.kind.collectionViewKind,
                    withReuseIdentifier: supplementary.controller.computedViewIdentifier)
            }

            self.supplementaryIndexPaths = [:]
            self.supplementariesByIndex = [:]
            self.supplementaries.forEach { supplementary in
                self.supplementaryIndexPaths[supplementary.index] = IndexPath(item: 0, section: supplementary.index.section)
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
        self.collectionView.register(ItemReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: String(ItemReusableView.self))
        self.collectionView.register(ItemReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: String(ItemReusableView.self))
    }

    // MARK: API

    public func visibleComponents() -> [Component] {
        var components: [Component] = []
        components.append(contentsOf: self.visibleItemComponents())
        components.append(contentsOf: self.visibleSupplementaryComponents(of: .header))
        components.append(contentsOf: self.visibleSupplementaryComponents(of: .footer))
        return components
    }

    public func visibleItemComponents() -> [Component] {
        return self.collectionView.indexPathsForVisibleItems.map({ self.itemComponent(for: $0)! })
    }

    public func visibleSupplementaryComponents(of kind: SupplementaryIndex.Kind) -> [Component] {
        return self.collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind.collectionViewKind).map({
            self.supplementaryComponent(of: kind, for: $0)
        }).flatMap({ $0 })
    }

    public func component(for index: ItemIndex) -> Component? {
        guard let indexPath = self.itemIndexPaths[index] else { return nil }
        return self.itemComponent(for: indexPath)
    }

    public func component(for index: SupplementaryIndex) -> Component? {
        guard let indexPath = self.supplementaryIndexPaths[index] else { return nil }
        return self.supplementaryComponent(of: index.kind, for: indexPath)
    }

    // MARK: Internal

    private func itemComponent(for indexPath: IndexPath) -> Component? {
        guard let cell = self.collectionView.cellForItem(at: indexPath) else { return nil }
        return self.itemComponent(for: indexPath, with: cell)
    }

    private func supplementaryComponent(of kind: SupplementaryIndex.Kind, for indexPath: IndexPath) -> Component? {
        // Uhh?
        let view = self.collectionView.supplementaryView(forElementKind: kind.collectionViewKind, at: indexPath)
        return self.supplementaryComponent(of: kind, inSection: indexPath.section, with: view!)
    }

    private func itemComponent(for indexPath: IndexPath, with cell: UICollectionViewCell) -> Component {
        let item = self.item(for: indexPath)
        let itemCell = cell as! ItemViewCell
        return Component(item: item, itemViewCell: itemCell)
    }

    private func supplementaryComponent(ofCollectionViewKind elementKind: String, inSection section: Int, with view: UICollectionReusableView) -> Component? {
        guard let kind = GridCollectionController.SupplementaryIndex.Kind.kind(forCollectionViewKind: elementKind) else {
            return nil
        }
        return supplementaryComponent(of: kind, inSection: section, with: view)
    }

    private func supplementaryComponent(of kind: SupplementaryIndex.Kind, inSection section: Int, with view: UICollectionReusableView) -> Component? {
        guard let supplementary = self.supplementary(of: kind, inSection: section) else {
            return nil
        }
        let supplementaryView = view as! ItemReusableView
        return Component(supplementary: supplementary, itemReusableView: supplementaryView)
    }

    private func item(for indexPath: IndexPath) -> Item {
        return self.itemsBySection[indexPath.section][indexPath.row]
    }

    private func supplementary(ofCollectionViewKind elementKind: String, inSection section: Int) -> Supplementary? {
        guard let kind = GridCollectionController.SupplementaryIndex.Kind.kind(forCollectionViewKind: elementKind) else { return nil }
        return self.supplementary(of: kind, inSection: section)
    }

    private func supplementary(of kind: SupplementaryIndex.Kind, inSection section: Int) -> Supplementary? {
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
    return lhs.index == rhs.index
}

public func == (lhs: GridCollectionController.Supplementary, rhs: GridCollectionController.Supplementary) -> Bool {
    return lhs.index == rhs.index
}

public func == (lhs: GridCollectionController.Component, rhs: GridCollectionController.Component) -> Bool {
    return lhs.kind == rhs.kind
}

public func == (lhs: GridCollectionController.Component.Kind, rhs: GridCollectionController.Component.Kind) -> Bool {
    switch (lhs, rhs) {
    case (.item(let lhs, _), .item(let rhs, _)):
        return lhs == rhs
    case (.supplementary(let lhs, _), .supplementary(let rhs, _)):
        return lhs == rhs
    default:
        return false
    }
}

// MARK: - GridCollectionControllerDelegate

public protocol GridCollectionControllerDelegate: class {

    func gridCollectionController(_ gridCollectionController: GridCollectionController, didSelect component: GridCollectionController.Component)
}

private extension GridCollectionController {

    func didSelectComponent(_ component: Component) {
        self.delegate?.gridCollectionController(self, didSelect: component)
    }
}

extension GridCollectionController: UICollectionViewDataSource, UICollectionViewDelegate, GridCollectionViewLayoutDelegate {

    // MARK: UICollectionView

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.itemsBySection.count
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.itemsBySection[section].count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.item(for: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.controller.computedViewIdentifier, for: indexPath) as! ItemViewCell
        cell.nestedView = item.controller.view(forItem: item, reusingView: cell.nestedView)
        cell.didPrepareForReuse = { [weak self, unowned cell] in
            guard let component = self?.itemComponent(for: indexPath, with: cell) else { return }
            component.detach()
        }
        let component = self.itemComponent(for: indexPath, with: cell)
        component.attach()
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let supplementary = self.supplementary(ofCollectionViewKind: kind, inSection: indexPath.section) else {
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: ItemReusableView.cellIdentifier, for: indexPath)
        }

        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: supplementary.controller.computedViewIdentifier, for: indexPath) as! ItemReusableView
        view.nestedView = supplementary.controller.view(forSupplementary: supplementary, reusingView: view.nestedView)
        view.didPrepareForReuse = { [weak self, unowned view] in
            guard let component = self?.supplementaryComponent(ofCollectionViewKind: kind, inSection: indexPath.section, with: view) else { return }
            component.detach()
        }
        guard let component = self.supplementaryComponent(ofCollectionViewKind: kind, inSection: indexPath.section, with: view) else {
            return view
        }
        component.attach()
        return view
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)!
        let component = self.itemComponent(for: indexPath, with: cell)
        self.didSelectComponent(component)
    }

    // MARK: GridCollectionViewLayout

    public func gridCollectionViewLayout(_ layout: GridCollectionViewLayout, propertiesFor indexPath: IndexPath) -> GridCollectionViewLayout.ItemProperties {
        let item = self.item(for: indexPath)
        return GridCollectionViewLayout.ItemProperties(gridRect: item.index.rect, insets: item.insets)
    }

    public func gridCollectionViewLayout(_ layout: GridCollectionViewLayout, propertiesForHeaderInSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties? {
        return self.supplementary(of: .header, inSection: section)?.properties
    }

    public func gridCollectionViewLayout(_ layout: GridCollectionViewLayout, propertiesForFooterInSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties? {
        return self.supplementary(of: .footer, inSection: section)?.properties
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

    private var didPrepareForReuse: (() -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?()
    }
}

public final class ItemReusableView: UICollectionReusableView {

    static let cellIdentifier = String(ItemReusableView.self)

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

    private var didPrepareForReuse: (() -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?()
    }
}

public protocol ComponentController: class {

    var viewIdentifier: String? { get }
    func attach(to component: GridCollectionController.Component)
    func detach(from component: GridCollectionController.Component)
}

private extension ComponentController {

    var computedViewIdentifier: String {
        return self.viewIdentifier ?? String(Self.self)
    }
}

public protocol ItemController: ComponentController {

    func view(forItem item: GridCollectionController.Item, reusingView reuseView: UIView?) -> UIView
}

public protocol SupplementaryController: ComponentController {

    func view(forSupplementary supplementary: GridCollectionController.Supplementary, reusingView reuseView: UIView?) -> UIView
}

// MARK: LinearGrid

public struct LinearGrid {

    public var numUnits: Int
    public var direction: GridCollectionViewLayout.Direction

    public init(numUnits: Int, direction: GridCollectionViewLayout.Direction = .vertical) {
        self.numUnits = numUnits
        self.direction = direction
    }

    public func rect(forIndex index: Int, width: CGFloat = 1.0, height: CGFloat = 1.0) -> GridCollectionViewLayout.GridRect {
        switch self.direction {
        case .vertical:
            return GridCollectionViewLayout.GridRect(
                x: CGFloat(index % self.numUnits),
                y: CGFloat(index / self.numUnits),
                width: width,
                height: height)
        case .horizontal:
            return GridCollectionViewLayout.GridRect(
                x: CGFloat(index / self.numUnits),
                y: CGFloat(index % self.numUnits),
                width: width,
                height: height)
        }
    }
}
