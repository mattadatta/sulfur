/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: - TableViewCell

public final class TableViewCell<View: UIView>: UITableViewCell {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func registerInTableView(_ tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromTableView(_ tableView: UITableView, forIndexPath indexPath: IndexPath) -> (TableViewCell<View>, View) {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewReuseIdentifier, for: indexPath) as! TableViewCell<View>
        return (cell, cell.nestedView)
    }

    public fileprivate(set) weak var nestedView: View!

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrain(view)
        self.nestedView = view
    }

    public private(set) var isSetup = false

    public func setup(_ block: (_ cell: TableViewCell<View>, _ view: View) -> Void) {
        guard !self.isSetup else { return }
        self.isSetup = true
        block(self, self.nestedView)
    }

    public var didPrepareForReuse: ((_ cell: TableViewCell<View>, _ view: View) -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?(self, self.nestedView)
    }

    public var didSetSelected: ((_ cell: TableViewCell<View>, _ view: View, _ selected: Bool, _ animated: Bool) -> Void)?

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.didSetSelected?(self, self.nestedView, selected, animated)
    }
}

// MARK: - TableViewHeaderFooterView

public final class TableViewHeaderFooterView<View: UIView>: UITableViewHeaderFooterView {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func registerInTableView(_ tableView: UITableView) {
        tableView.register(self, forHeaderFooterViewReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromTableView(_ tableView: UITableView) -> (TableViewHeaderFooterView<View>, View) {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.viewReuseIdentifier) as! TableViewHeaderFooterView<View>
        return (view, view.nestedView)
    }

    public fileprivate(set) weak var nestedView: View!

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrain(view)
        self.nestedView = view
    }

    public private(set) var isSetup = false

    public func setup(_ block: (_ cell: TableViewHeaderFooterView<View>, _ view: View) -> Void) {
        guard !self.isSetup else { return }
        self.isSetup = true
        block(self, self.nestedView)
    }

    public var didPrepareForReuse: ((_ headerFooterView: TableViewHeaderFooterView<View>, _ view: View) -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?(self, self.nestedView)
    }
}

// MARK: - CollectionViewCell

public final class CollectionViewCell<View: UIView>: UICollectionViewCell {

    public class var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func registerInCollectionView(_ collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromCollectionView(_ collectionView: UICollectionView, forIndexPath indexPath: IndexPath) -> (CollectionViewCell<View>, View) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.viewReuseIdentifier, for: indexPath) as! CollectionViewCell<View>
        return (cell, cell.nestedView)
    }

    public fileprivate(set) weak var nestedView: View!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrain(view)
        self.nestedView = view
    }

    public private(set) var isSetup = false

    public func setup(_ block: (_ cell: CollectionViewCell<View>, _ view: View) -> Void) {
        guard !self.isSetup else { return }
        self.isSetup = true
        block(self, self.nestedView)
    }

    public var didPrepareForReuse: ((_ cell: CollectionViewCell<View>, _ view: View) -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?(self, self.nestedView)
    }

    public var didSetSelected: ((_ cell: CollectionViewCell<View>, _ view: View, _ selected: Bool, _ animated: Bool) -> Void)?

    override public var isSelected: Bool {
        didSet {
            self.didSetSelected?(self, self.nestedView, self.isSelected, false)
        }
    }
}

// MARK: - CollectionReusableView

public final class CollectionReusableView<View: UIView>: UICollectionReusableView {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func registerInCollectionView(_ collectionView: UICollectionView, forSupplementaryViewOfKind kind: String) {
        collectionView.register(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromCollectionView(_ collectionView: UICollectionView, forSupplementaryViewOfKind kind: String, forIndexPath indexPath: IndexPath) -> (CollectionReusableView<View>, View) {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.viewReuseIdentifier, for: indexPath) as! CollectionReusableView<View>
        return (view, view.nestedView)
    }

    public fileprivate(set) weak var nestedView: View!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        let view = View.init()
        self.addAndConstrain(view)
        self.nestedView = view
    }

    public private(set) var isSetup = false

    public func setup(_ block: (_ cell: CollectionReusableView<View>, _ view: View) -> Void) {
        guard !self.isSetup else { return }
        self.isSetup = true
        block(self, self.nestedView)
    }

    public var didPrepareForReuse: ((CollectionReusableView<View>, View) -> Void)?

    override public func prepareForReuse() {
        super.prepareForReuse()
        self.didPrepareForReuse?(self, self.nestedView)
    }
}
