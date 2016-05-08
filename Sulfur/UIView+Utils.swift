/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit
import Cartography

public extension UIEdgeInsets {

    public init(size: CGFloat) {
        self.init(top: size, left: size, bottom: size, right: size)
    }

    public init(widths: CGFloat, heights: CGFloat) {
        self.init(top: heights, left: widths, bottom: heights, right: widths)
    }

    public var height: CGFloat {
        return self.top + self.bottom
    }

    public var width: CGFloat {
        return self.left + self.right
    }
}

public extension UIView {

    public func constrainView(view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        return constrain(self, view) { (containerView, view) in
            view.left == containerView.left + insets.left
            view.top == containerView.top + insets.top
            view.right == containerView.right - insets.right
            view.bottom == containerView.bottom - insets.bottom
        }
    }

    public func addAndConstrainView(view: UIView, withInsets insets: UIEdgeInsets = UIEdgeInsetsZero) -> ConstraintGroup {
        view.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(view)
        return self.constrainView(view, withInsets: insets)
    }
}

public extension UIViewController {

    public func instantiateControllerFromStoryboard<Controller: UIViewController>() -> Controller! {
        return self.storyboard!.instantiateViewControllerWithIdentifier("\(Controller.self)") as! Controller
    }

    public func pushViewControllerIfPossible<ViewController: UIViewController>(viewController: ViewController, animated: Bool) {
        guard let navigationController = self.navigationController else {
            self.presentViewController(viewController, animated: animated, completion: nil)
            return
        }
        navigationController.pushViewController(viewController, animated: animated)
    }
}

public extension UITableView {

    public func dequeueAtIndexPath<Cell: UITableViewCell>(indexPath: NSIndexPath) -> Cell {
        return self.dequeueReusableCellWithIdentifier("\(Cell.self)", forIndexPath: indexPath) as! Cell
    }
}
