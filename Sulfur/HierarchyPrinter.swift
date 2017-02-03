/*
 This file is subject to the terms and conditions defined in
 file 'LICENSE', which is part of this source code package.
 */

import UIKit

public struct HierarchyPrinter<Node, Inspector: NodeInspector> where Inspector.Node == Node {

    public var root: Node
    public var inspector: Inspector

    public init(root: Node, inspector: Inspector) {
        self.root = root
        self.inspector = inspector
    }

    public var hierarchyString: String {
        return HierarchyPrinter.dfsInspect(inspector: self.inspector, node: self.root, depth: 0, prefix: "", last: true)
    }

    public static func dfsInspect(inspector: Inspector, node: Node, depth: Int, prefix: String, last: Bool) -> String {
        let nodeDescription = inspector.describe(node, depth: depth, prefix: prefix, last: last)
        let horizontalLine = depth > 0 ? " \(last ? "└" : "├")─── " : ""
        let result = "\(prefix)\(horizontalLine)\(nodeDescription)"
        let padding = (last ? " " : "│").padding(toLength: depth > 0 ? 6 : 0, withPad: " ", startingAt: 0)
        let newPrefix = "\(prefix) \(padding)"
        let children = inspector.children(of: node)
        let childCount = children.count
        return children.enumerated().reduce(result) { result, obj in
            let index = obj.offset
            let subNode = obj.element
            let subResult = self.dfsInspect(inspector: inspector, node: subNode, depth: depth + 1, prefix: newPrefix, last: index == childCount - 1)
            return "\(result)\n\(subResult)"
        }
    }
}

extension HierarchyPrinter: CustomStringConvertible, CustomDebugStringConvertible {

    public var description: String {
        return self.hierarchyString
    }

    public var debugDescription: String {
        return self.hierarchyString
    }
}

public protocol NodeInspector {
    associatedtype Node

    func children(of node: Node) -> [Node]
    func describe(_ node: Node, depth: Int, prefix: String, last: Bool) -> String
}

public struct ViewNodeInspector: NodeInspector {

    public init() { }

    public func children(of node: UIView) -> [UIView] {
        return node.subviews
    }

    public func describe(_ node: UIView, depth: Int, prefix: String, last: Bool) -> String {
        guard let viewController = node.next as? UIViewController else {
            return "[\(type(of: node)): Frame = \(node.frame)]"
        }
        return "[\(type(of: viewController))] [\(type(of: node)): Frame = \(node.frame)]"
    }
}

public extension UIView {

    public var hierarchyString: String {
        return HierarchyPrinter(root: self, inspector: ViewNodeInspector()).hierarchyString
    }
}
