/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public protocol ViewBinder {

    var view: UIView { get }

    func bind()
    func unbind()
}

public protocol ViewCell: ViewBinder {

    var viewBinder: ViewBinder? { get }
}

// MARK: - TableViewCell

public final class TableViewCell<View: UIView>: UITableViewCell, ViewCell {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func register(in tableView: UITableView) {
        tableView.register(self, forCellReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeue(from tableView: UITableView, for indexPath: IndexPath) -> (TableViewCell<View>, View) {
        let cell = tableView.dequeueReusableCell(withIdentifier: self.viewReuseIdentifier, for: indexPath) as! TableViewCell<View>
        return (cell, cell.nestedView)
    }

    public weak var nestedView: View! {
        willSet {
            guard let view = self.nestedView else { return }
            view.removeFromSuperview()
        }
        didSet {
            self.contentView.addAndConstrainView(self.nestedView)
        }
    }

    public var view: UIView {
        return self.nestedView
    }

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.nestedView = View()
    }

    public var viewBinder: ViewBinder? {
        willSet {
            self.viewBinder?.unbind()
        }
        didSet {
            self.viewBinder?.bind()
        }
    }

    public func bind() {
        self.viewBinder?.bind()
    }

    public func unbind() {
        self.viewBinder?.unbind()
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
        self.viewBinder = nil
    }

    public var didSetSelected: ((_ cell: TableViewCell<View>, _ view: View, _ selected: Bool, _ animated: Bool) -> Void)?

    override public func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.didSetSelected?(self, self.nestedView, selected, animated)
    }
}

// MARK: - TableViewHeaderFooterView

public final class TableViewHeaderFooterView<View: UIView>: UITableViewHeaderFooterView, ViewCell {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func register(in tableView: UITableView) {
        tableView.register(self, forHeaderFooterViewReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeue(from tableView: UITableView) -> (TableViewHeaderFooterView<View>, View) {
        let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: self.viewReuseIdentifier) as! TableViewHeaderFooterView<View>
        return (view, view.nestedView)
    }

    public weak var nestedView: View! {
        willSet {
            guard let view = self.nestedView else { return }
            view.removeFromSuperview()
        }
        didSet {
            self.contentView.addAndConstrainView(self.nestedView)
        }
    }

    public var view: UIView {
        return self.nestedView
    }

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    fileprivate func commonInit() {
        self.nestedView = View()
    }

    public var viewBinder: ViewBinder? {
        willSet {
            self.viewBinder?.unbind()
        }
        didSet {
            self.viewBinder?.bind()
        }
    }

    public func bind() {
        self.viewBinder?.bind()
    }

    public func unbind() {
        self.viewBinder?.unbind()
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
        self.viewBinder = nil
    }
}

// MARK: - CollectionViewCell

public final class CollectionViewCell<View: UIView>: UICollectionViewCell, ViewCell {

    public class var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func register(in collectionView: UICollectionView) {
        collectionView.register(self, forCellWithReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeue(from collectionView: UICollectionView, for indexPath: IndexPath) -> (CollectionViewCell<View>, View) {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.viewReuseIdentifier, for: indexPath) as! CollectionViewCell<View>
        return (cell, cell.nestedView)
    }

    public weak var nestedView: View! {
        willSet {
            guard let view = self.nestedView else { return }
            view.removeFromSuperview()
        }
        didSet {
            self.contentView.addAndConstrainView(self.nestedView)
        }
    }

    public var view: UIView {
        return self.nestedView
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
        self.nestedView = View()
    }

    public var viewBinder: ViewBinder? {
        willSet {
            self.viewBinder?.unbind()
        }
        didSet {
            self.viewBinder?.bind()
        }
    }

    public func bind() {
        self.viewBinder?.bind()
    }

    public func unbind() {
        self.viewBinder?.unbind()
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
        self.viewBinder = nil
    }

    public var didSetSelected: ((_ cell: CollectionViewCell<View>, _ view: View, _ selected: Bool, _ animated: Bool) -> Void)?

    override public var isSelected: Bool {
        didSet {
            self.didSetSelected?(self, self.nestedView, self.isSelected, false)
        }
    }

    public var didSetHighlighted: ((_ cell: CollectionViewCell<View>, _ view: View, _ highlighted: Bool, _ animated: Bool) -> Void)?

    override public var isHighlighted: Bool {
        didSet {
            self.didSetHighlighted?(self, self.nestedView, self.isHighlighted, false)
        }
    }
}

// MARK: - CollectionReusableView

public final class CollectionReusableView<View: UIView>: UICollectionReusableView, ViewCell {

    public static var viewReuseIdentifier: String {
        return String(describing: self)
    }

    public class func register(in collectionView: UICollectionView, forSupplementaryViewOfKind kind: String) {
        collectionView.register(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeue(from collectionView: UICollectionView, forSupplementaryViewOfKind kind: String, for indexPath: IndexPath) -> (CollectionReusableView<View>, View) {
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: self.viewReuseIdentifier, for: indexPath) as! CollectionReusableView<View>
        return (view, view.nestedView)
    }

    public weak var nestedView: View! {
        willSet {
            guard let view = self.nestedView else { return }
            view.removeFromSuperview()
        }
        didSet {
            self.addAndConstrainView(self.nestedView)
        }
    }

    public var view: UIView {
        return self.nestedView
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
        self.nestedView = View()
    }

    public var viewBinder: ViewBinder? {
        willSet {
            self.viewBinder?.unbind()
        }
        didSet {
            self.viewBinder?.bind()
        }
    }

    public func bind() {
        self.viewBinder?.bind()
    }

    public func unbind() {
        self.viewBinder?.unbind()
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
        self.viewBinder = nil
    }
}
