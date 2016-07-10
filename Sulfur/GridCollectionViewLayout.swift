/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: - GridCollectionViewLayout

public final class GridCollectionViewLayout: UICollectionViewLayout {

    // MARK: Inner Classes

    private enum GridMeasurementUtils {

        static func frameForGridRect(rect: GridRect, cellSize: CGSize, spacingSize: CGSize) -> CGRect {
            let frameX = (cellSize.width + spacingSize.width) * rect.x
            let frameY = (cellSize.height + spacingSize.height) * rect.y
            let size = self.sizeForGridRect(rect, cellSize: cellSize, spacingSize: spacingSize)
            return CGRect(origin: CGPoint(x: frameX, y: frameY), size: size)
        }

        static func sizeForGridRect(rect: GridRect, cellSize: CGSize, spacingSize: CGSize) -> CGSize {
            let itemWidth = cellSize.width * rect.width + ((rect.width - 1.0) * spacingSize.width)
            let itemHeight = cellSize.height * rect.height + ((rect.height - 1.0) * spacingSize.height)
            return CGSize(width: itemWidth, height: itemHeight)
        }
    }

    // MARK: GridRect

    public struct GridRect: Hashable {

        public var x: CGFloat
        public var y: CGFloat
        public var width: CGFloat
        public var height: CGFloat

        public init() {
            self.init(x: 0, y: 0, width: 1, height: 1)
        }

        public init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
            self.x = x
            self.y = y
            self.width = width
            self.height = height
        }

        public var hashValue: Int {
            var hash = self.x.hashValue
            hash = hash &* 31 &+ self.y.hashValue
            hash = hash &* 31 &+ self.width.hashValue
            hash = hash &* 31 &+ self.height.hashValue
            return hash
        }
    }

    // MARK: LayoutAttributes

    public final class LayoutAttributes: UICollectionViewLayoutAttributes {

        public enum Kind: Hashable {

            case Item(GridRect)
            case Supplementary(SupplementaryProperties)

            public var hashValue: Int {
                switch self {
                case .Item(let rect):
                    return rect.hashValue
                case .Supplementary(let properties):
                    var hash = properties.length.hashValue
                    hash = hash &* 31 &+ properties.insets.hashValue
                    return hash
                }
            }
        }

        public var section: Int = 0
        public var kind: Kind = .Item(GridRect())

        override public func copyWithZone(zone: NSZone) -> AnyObject {
            let attrs = super.copyWithZone(zone) as! LayoutAttributes
            attrs.section = self.section
            attrs.kind = self.kind
            return attrs
        }

        override public func isEqual(object: AnyObject?) -> Bool {
            guard let other = object as? LayoutAttributes else { return false }
            return self.section == other.section && self.kind == other.kind
        }

        public var rect: GridRect? {
            switch self.kind {
            case .Item(let rect):
                return rect
            default:
                return nil
            }
        }

        public var properties: SupplementaryProperties? {
            switch self.kind {
            case .Supplementary(let properties):
                return properties
            default:
                return nil
            }
        }

        override public var debugDescription: String {
            switch self.kind {
            case .Item(let rect):
                return "LayoutParams(kind: Item, rect: \(rect), indexPath: \(self.indexPath)"
            case .Supplementary(let properties):
                return "LayoutParams(kind: Supplementary, properties: \(properties), indexPath: \(self.indexPath)"
            }
        }
    }

    // MARK: SupplementartProperties

    public struct SupplementaryProperties: Hashable {

        public var length: CGFloat
        public var insets: UIEdgeInsets

        public init() {
            self.init(length: 0, insets: UIEdgeInsetsZero)
        }

        public init(length: CGFloat, insets: UIEdgeInsets) {
            self.length = length
            self.insets = insets
        }

        public var hashValue: Int {
            var hash = self.length.hashValue
            hash = hash &* 31 &+ self.insets.hashValue
            return hash
        }
    }

    public enum Direction {
        case Vertical
        case Horizontal
    }

    public var direction: Direction = .Vertical {
        didSet {
            guard self.direction != oldValue else { return }
            self.invalidateLayout()
        }
    }

    public struct UnitInformation: Hashable {

        public enum Dimension {
            case Width
            case Height
        }

        public var dimension: Dimension
        public var numUnits: CGFloat
        public var spacingSize: CGSize
        public var oppositeSideFn: (CGFloat) -> CGFloat

        public init(dimension: Dimension, numUnits: CGFloat, spacingSize: CGSize, oppositeSideFn: (CGFloat) -> CGFloat = { $0 }) {
            self.dimension = dimension
            self.numUnits = numUnits
            self.spacingSize = spacingSize
            self.oppositeSideFn = oppositeSideFn
        }

        public var hashValue: Int {
            var hash = self.dimension.hashValue
            hash = hash &* 31 &+ self.numUnits.hashValue
            hash = hash &* 31 &+ self.spacingSize.hashValue
            return hash
        }
    }

    public struct CellSizeInformation: Hashable {

        public var cellSize: CGSize
        public var oppositeDimensionSpacingFn: (CGFloat) -> CGFloat

        public init(cellSize: CGSize, oppositeDimensionSpacingFn: (CGFloat) -> CGFloat = { $0 }) {
            self.cellSize = cellSize
            self.oppositeDimensionSpacingFn = oppositeDimensionSpacingFn
        }

        public var hashValue: Int {
            return self.cellSize.hashValue
        }
    }

    public enum GridComputation: Hashable {

        case Units(UnitInformation)
        case CellSize(CellSizeInformation)

        public var hashValue: Int {
            switch self {
            case .Units(let info):
                return info.hashValue
            case .CellSize(let info):
                return info.hashValue
            }
        }
    }

    public var gridComputation: GridComputation = .Units(UnitInformation(dimension: .Width, numUnits: 4, spacingSize: CGSizeZero)) {
        didSet {
            self.invalidateLayout()
        }
    }

    public var sectionInsets: UIEdgeInsets = UIEdgeInsetsZero {
        didSet {
            guard self.sectionInsets != oldValue else { return }
            self.invalidateLayout()
        }
    }

    public weak var delegate: GridCollectionViewLayoutDelegate? {
        didSet {
            guard self.delegate !== oldValue else { return }
            self.invalidateLayout()
        }
    }

    public private(set) var cellSize: CGSize = CGSizeZero
    public private(set) var spacingSize: CGSize = CGSizeZero
    public private(set) var numUnits: Int = 0

    private var layoutAttrs: [LayoutAttributes] = []
    private var itemLayoutAttrs: [NSIndexPath: LayoutAttributes] = [:]
    private var headerLayoutAttrs: [NSIndexPath: LayoutAttributes] = [:]
    private var footerLayoutAttrs: [NSIndexPath: LayoutAttributes] = [:]
    private var contentOffsets: [(CGFloat, CGFloat, CGFloat)] = []
    private var contentSize: CGSize = CGSizeZero

    // MARK: UICollectionViewLayout overrides

    override public class func layoutAttributesClass() -> AnyClass {
        return LayoutAttributes.self
    }

    override public func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return self.collectionView?.bounds.size != newBounds.size
    }

    override public func prepareLayout() {
        super.prepareLayout()

        guard let collectionView = self.collectionView else { return }
        let bounds = collectionView.bounds

        self.layoutAttrs = []
        self.itemLayoutAttrs = [:]
        self.headerLayoutAttrs = [:]
        self.footerLayoutAttrs = [:]
        self.contentOffsets = []

        let spaceMinusPadding: CGFloat
        switch self.direction {
        case .Vertical:
            spaceMinusPadding = bounds.width - collectionView.contentInset.width
        case .Horizontal:
            spaceMinusPadding = bounds.height - collectionView.contentInset.height
        }

        switch self.gridComputation {
        case .Units(let info):
            let units = info.numUnits
            let spacingSize = info.spacingSize
            let sectionInsets = self.sectionInsets

            switch info.dimension {
            case .Width:
                let cellWidth = ((bounds.width - collectionView.contentInset.width - sectionInsets.width) - ((units - 1.0) * spacingSize.width)) / units
                self.cellSize = CGSize(width: cellWidth, height: info.oppositeSideFn(cellWidth))
            case .Height:
                let cellHeight = ((bounds.height - collectionView.contentInset.height - sectionInsets.height) - ((units - 1.0) * spacingSize.height)) / units
                self.cellSize = CGSize(width: info.oppositeSideFn(cellHeight), height: cellHeight)
            }
            self.spacingSize = spacingSize

        case .CellSize(let info):
            let cellSize = info.cellSize
            let cellDimension: CGFloat
            switch self.direction {
            case .Vertical:
                cellDimension = cellSize.width
            case .Horizontal:
                cellDimension = cellSize.height
            }
            let numUnits = CGFloat(Int(spaceMinusPadding / cellDimension))
            let itemSpacing = numUnits < 2 ? 0.0 : (spaceMinusPadding - (cellDimension * numUnits)) / (numUnits - 1.0)

            self.cellSize = cellSize
            switch self.direction {
            case .Vertical:
                self.spacingSize = CGSize(width: itemSpacing, height: info.oppositeDimensionSpacingFn(itemSpacing))
            case .Horizontal:
                self.spacingSize = CGSize(width: info.oppositeDimensionSpacingFn(itemSpacing), height: itemSpacing)
            }
        }

        var cumulativeLength: CGFloat = 0.0

        let numberOfSections = collectionView.numberOfSections()
        (0..<numberOfSections).forEach { section in
            let sectionIndexPath = NSIndexPath(forItem: 0, inSection: section)

            // HEADER
            let headerLayoutAttrs = LayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withIndexPath: sectionIndexPath)
            let headerProperties = self.propertiesForHeaderForSection(section)
            let (headerLength, headerInsets) = (headerProperties.length, headerProperties.insets)

            let totalHeaderLength: CGFloat
            switch self.direction {
            case .Vertical:
                totalHeaderLength = headerLength + headerInsets.height
                headerLayoutAttrs.frame = CGRect(x: headerInsets.left, y: cumulativeLength + headerInsets.top, width: spaceMinusPadding - headerInsets.width, height: headerLength)
            case .Horizontal:
                totalHeaderLength = headerLength + headerInsets.width
                headerLayoutAttrs.frame = CGRect(x: cumulativeLength + headerInsets.left, y: headerInsets.top, width: headerLength, height: spaceMinusPadding - headerInsets.height)
            }

            headerLayoutAttrs.section = section
            headerLayoutAttrs.kind = .Supplementary(headerProperties)
            self.headerLayoutAttrs[sectionIndexPath] = headerLayoutAttrs
            self.layoutAttrs.append(headerLayoutAttrs)

            switch self.direction {
            case .Vertical:
                cumulativeLength += totalHeaderLength + self.sectionInsets.top
            case .Horizontal:
                cumulativeLength += totalHeaderLength + self.sectionInsets.left
            }

            // CONTENT
            var sectionMaxLength: CGFloat = 0.0

            let numberOfItems = collectionView.numberOfItemsInSection(section)
            (0..<numberOfItems).forEach { item in
                let indexPath = NSIndexPath(forItem: item, inSection: section)
                let rect = self.rectForIndexPath(indexPath)
                let attrs = LayoutAttributes(forCellWithIndexPath: indexPath)
                let originalFrame = GridMeasurementUtils.frameForGridRect(rect, cellSize: self.cellSize, spacingSize: self.spacingSize)

                switch self.direction {
                case .Vertical:
                    attrs.frame = originalFrame.offsetBy(dx: self.sectionInsets.left, dy: cumulativeLength)
                    sectionMaxLength = max(sectionMaxLength, originalFrame.bottom)
                case .Horizontal:
                    attrs.frame = originalFrame.offsetBy(dx: cumulativeLength, dy: self.sectionInsets.top)
                    sectionMaxLength = max(sectionMaxLength, originalFrame.right)
                }

                attrs.section = section
                attrs.kind = .Item(rect)
                self.itemLayoutAttrs[indexPath] = attrs
                self.layoutAttrs.append(attrs)
            }

            switch self.direction {
            case .Vertical:
                cumulativeLength += sectionMaxLength + self.sectionInsets.bottom
            case .Horizontal:
                cumulativeLength += sectionMaxLength + self.sectionInsets.right
            }

            // FOOTER
            let footerLayoutAttrs = LayoutAttributes(forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withIndexPath: sectionIndexPath)
            let footerProperties = self.propertiesForFooterForSection(section)
            let (footerLength, footerInsets) = (footerProperties.length, footerProperties.insets)

            let totalFooterLength: CGFloat
            switch self.direction {
            case .Vertical:
                totalFooterLength = footerLength + footerInsets.height
                footerLayoutAttrs.frame = CGRect(x: footerInsets.left, y: cumulativeLength + footerInsets.top, width: spaceMinusPadding - footerInsets.width, height: footerLength)
            case .Horizontal:
                totalFooterLength = footerLength + footerInsets.width
                footerLayoutAttrs.frame = CGRect(x: cumulativeLength + footerInsets.left, y: footerInsets.top, width: footerLength, height: spaceMinusPadding - footerInsets.height)
            }

            footerLayoutAttrs.section = section
            footerLayoutAttrs.kind = .Supplementary(footerProperties)
            self.footerLayoutAttrs[sectionIndexPath] = footerLayoutAttrs
            self.layoutAttrs.append(footerLayoutAttrs)

            cumulativeLength += totalFooterLength

            self.contentOffsets.append((totalHeaderLength, sectionMaxLength, totalFooterLength))
        }

        switch self.direction {
        case .Vertical:
            self.contentSize = CGSize(width: spaceMinusPadding, height: cumulativeLength)
        case .Horizontal:
            self.contentSize = CGSize(width: cumulativeLength, height: spaceMinusPadding)
        }
    }

    override public func collectionViewContentSize() -> CGSize {
        return self.contentSize
    }

    override public func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return self.layoutAttrs.filter({ rect.intersects($0.frame) })
    }

    override public func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return self.itemLayoutAttrs[indexPath]
    }

    override public func layoutAttributesForSupplementaryViewOfKind(elementKind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionElementKindSectionHeader:
            return self.headerLayoutAttrs[indexPath]
        case UICollectionElementKindSectionFooter:
            return self.footerLayoutAttrs[indexPath]
        default:
            fatalError("Unkown element kind: \(elementKind)")
        }
    }

//    public var gridSnapping = true
//
//    override public func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
//        guard let collectionView = self.collectionView where self.gridSnapping else {
//            return proposedContentOffset
//        }
//
//        let contentInset: CGFloat
//        let contentOffset: CGFloat
//        let contentSize: CGFloat
//        let boundsSize: CGFloat
//        let sectionStartLength: CGFloat
//        let sectionEndLength: CGFloat
//        switch self.direction {
//        case .Vertical:
//            contentInset = collectionView.contentInset.top
//            contentOffset = proposedContentOffset.y
//            contentSize = self.contentSize.height
//            boundsSize = collectionView.bounds.height
//            sectionStartLength = self.sectionInsets.top
//            sectionEndLength = self.sectionInsets.bottom
//        case .Horizontal:
//            contentInset = collectionView.contentInset.left
//            contentOffset = proposedContentOffset.x
//            contentSize = self.contentSize.width
//            boundsSize = collectionView.bounds.width
//            sectionStartLength = self.sectionInsets.left
//            sectionEndLength = self.sectionInsets.right
//        }
//
//        var cumulatedOffset: CGFloat = 0.0
//        var minDistance: CGFloat = CGFloat.max
//        var finalOffset: CGFloat = 0.0
//        for (headerLength, contentLength, footerLength) in self.contentOffsets {
//            // HEADER
//            if headerLength > 0 {
//                let headerDistance = contentOffset - cumulatedOffset
//                if (abs(headerDistance) < minDistance) {
//                    minDistance = abs(headerDistance)
//                } else {
//                    break
//                }
//
//                finalOffset = cumulatedOffset
//                cumulatedOffset += (headerLength + sectionStartLength)
//            }
//
//            // CONTENT
//            let numCells = Int(round(contentLength - ((self.dimensionAndUnits.units - 1) * self.itemSpacing)) / self.cellDimension)
//            var itemFound = false
//            let cellRange = (0..<numCells)
//            for i in cellRange {
//                let itemDistance = contentOffset - cumulatedOffset
//                if (abs(itemDistance) < minDistance) {
//                    minDistance = abs(itemDistance)
//                } else {
//                    itemFound = true
//                    break
//                }
//
//                finalOffset = cumulatedOffset
//                cumulatedOffset += self.cellDimension
//                if i < cellRange.count - 1 {
//                    cumulatedOffset += self.itemSpacing
//                }
//            }
//            if itemFound {
//                break
//            }
//
//            if footerLength > 0 {
//                cumulatedOffset += sectionEndLength
//
//                // FOOTER
//                let footerDistance = contentOffset - cumulatedOffset
//                if (abs(footerDistance) < minDistance) {
//                    minDistance = abs(footerDistance)
//                } else {
//                    break
//                }
//
//                finalOffset = cumulatedOffset
//            }
//        }
//
//        finalOffset = min(finalOffset, contentSize - boundsSize)
//        finalOffset -= contentInset
//
//        switch self.direction {
//        case .Vertical:
//            return CGPoint(x: 0.0, y: finalOffset)
//        case .Horizontal:
//            return CGPoint(x: finalOffset, y: 0.0)
//        }
//    }
}

// MARK: - GridCellCollectionViewLayoutDelegate

public protocol GridCollectionViewLayoutDelegate: class {

    func gridCollectionViewLayout(layout: GridCollectionViewLayout, rectForIndexPath indexPath: NSIndexPath) -> GridCollectionViewLayout.GridRect
    func gridCollectionViewLayout(layout: GridCollectionViewLayout, propertiesForHeaderForSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties?
    func gridCollectionViewLayout(layout: GridCollectionViewLayout, propertiesForFooterForSection section: Int) -> GridCollectionViewLayout.SupplementaryProperties?
}

private extension GridCollectionViewLayout {

    func rectForIndexPath(indexPath: NSIndexPath) -> GridRect {
        return self.delegate?.gridCollectionViewLayout(self, rectForIndexPath: indexPath) ?? GridRect()
    }

    func propertiesForHeaderForSection(section: Int) -> SupplementaryProperties {
        return self.delegate?.gridCollectionViewLayout(self, propertiesForHeaderForSection: section) ?? SupplementaryProperties()
    }

    func propertiesForFooterForSection(section: Int) -> SupplementaryProperties {
        return self.delegate?.gridCollectionViewLayout(self, propertiesForFooterForSection: section) ?? SupplementaryProperties()
    }
}

public func == (lhs: GridCollectionViewLayout.GridRect, rhs: GridCollectionViewLayout.GridRect) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y && lhs.width == rhs.width && lhs.height == rhs.height
}

public func == (lhs: GridCollectionViewLayout.SupplementaryProperties, rhs: GridCollectionViewLayout.SupplementaryProperties) -> Bool {
    return lhs.length == rhs.length && lhs.insets == rhs.insets
}

public func == (lhs: GridCollectionViewLayout.UnitInformation, rhs: GridCollectionViewLayout.UnitInformation) -> Bool {
    return lhs.dimension == rhs.dimension && lhs.numUnits == rhs.numUnits && lhs.spacingSize == rhs.spacingSize
}

public func == (lhs: GridCollectionViewLayout.CellSizeInformation, rhs: GridCollectionViewLayout.CellSizeInformation) -> Bool {
    return lhs.cellSize == rhs.cellSize
}

public func == (lhs: GridCollectionViewLayout.GridComputation, rhs: GridCollectionViewLayout.GridComputation) -> Bool {
    switch (lhs, rhs) {
    case (.Units(let lhs), .Units(let rhs)):
        return lhs == rhs
    case (.CellSize(let lhs), .CellSize(let rhs)):
        return lhs == rhs
    default:
        return false
    }
}

public func == (lhs: GridCollectionViewLayout.LayoutAttributes.Kind, rhs: GridCollectionViewLayout.LayoutAttributes.Kind) -> Bool {
    switch (lhs, rhs) {
    case (.Item(let lhs), .Item(let rhs)):
        return lhs == rhs
    case (.Supplementary(let lhs), .Supplementary(let rhs)):
        return lhs == rhs
    default:
        return false
    }
}
