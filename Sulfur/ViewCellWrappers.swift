/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

// MARK: - TableViewCell

public final class TableViewCell<View: UIView>: UITableViewCell {

    public static var viewReuseIdentifier: String {
        return "\(self)"
    }

    public class func registerInTableView(tableView: UITableView) {
        tableView.registerClass(self, forCellReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromTableView(tableView: UITableView, forIndexPath indexPath: NSIndexPath) -> (TableViewCell<View>, View) {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.viewReuseIdentifier, forIndexPath: indexPath) as! TableViewCell<View>
        return (cell, cell.nestedView)
    }

    public private(set) weak var nestedView: View!

    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrainView(view)
        self.nestedView = view
    }
}

// MARK: - TableViewHeaderFooterView

public final class TableViewHeaderFooterView<View: UIView>: UITableViewHeaderFooterView {

    public static var viewReuseIdentifier: String {
        return "\(self)"
    }

    public class func registerInTableView(tableView: UITableView) {
        tableView.registerClass(self, forHeaderFooterViewReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromTableView(tableView: UITableView) -> (TableViewHeaderFooterView<View>, View) {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(self.viewReuseIdentifier) as! TableViewHeaderFooterView<View>
        return (view, view.nestedView)
    }

    public private(set) weak var nestedView: View!

    override public init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrainView(view)
        self.nestedView = view
    }
}

// MARK: - CollectionViewCell

public final class CollectionViewCell<View: UIView>: UICollectionViewCell {

    public class var viewReuseIdentifier: String {
        return "\(self)"
    }

    public class func registerInCollectionView(collectionView: UICollectionView) {
        collectionView.registerClass(self, forCellWithReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromCollectionView(collectionView: UICollectionView, forIndexPath indexPath: NSIndexPath) -> (CollectionViewCell<View>, View) {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.viewReuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell<View>
        return (cell, cell.nestedView)
    }

    public private(set) weak var nestedView: View!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        let view = View.init()
        self.contentView.addAndConstrainView(view)
        self.nestedView = view
    }
}

// MARK: - CollectionReusableView

public final class CollectionReusableView<View: UIView>: UICollectionReusableView {

    public static var viewReuseIdentifier: String {
        return "\(self)"
    }

    public class func registerInCollectionView(collectionView: UICollectionView, forSupplementaryViewOfKind kind: String) {
        collectionView.registerClass(self, forSupplementaryViewOfKind: kind, withReuseIdentifier: self.viewReuseIdentifier)
    }

    public class func dequeueFromCollectionView(collectionView: UICollectionView, forSupplementaryViewOfKind kind: String, forIndexPath indexPath: NSIndexPath) -> (CollectionReusableView<View>, View) {
        let view = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: self.viewReuseIdentifier, forIndexPath: indexPath) as! CollectionReusableView<View>
        return (view, view.nestedView)
    }

    public private(set) weak var nestedView: View!

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }

    private func commonInit() {
        let view = View.init()
        self.addAndConstrainView(view)
        self.nestedView = view
    }
}
