/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE.txt', which is part of this source code package.
 */

import UIKit

extension UIViewController {

    func instantiateControllerFromStoryboard<Controller: UIViewController>() -> Controller! {
        return self.storyboard!.instantiateViewControllerWithIdentifier("\(Controller.self)") as! Controller
    }

    func pushViewControllerIfPossible<ViewController: UIViewController>(viewController: ViewController, animated: Bool) {
        guard let navigationController = self.navigationController else {
            self.presentViewController(viewController, animated: animated, completion: nil)
            return
        }
        navigationController.pushViewController(viewController, animated: animated)
    }
}

extension UITableView {

    func dequeueAtIndexPath<Cell: UITableViewCell>(indexPath: NSIndexPath) -> Cell {
        return self.dequeueReusableCellWithIdentifier("\(Cell.self)", forIndexPath: indexPath) as! Cell
    }
}
