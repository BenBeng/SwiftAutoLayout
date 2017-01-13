//  Copyright (c) 2016 Indragie Karunaratne. All rights reserved.
//  Licensed under the MIT license, see LICENSE file for more info.

#if os(OSX)
    import AppKit
    public typealias View = NSView
    public typealias LayoutPriority = NSLayoutPriority

    @available(OSX 10.11, *)
    public typealias LayoutGuide = NSLayoutGuide
#elseif os(iOS) || os(tvOS)
    import UIKit
    public typealias View = UIView
    public typealias LayoutPriority = UILayoutPriority
    public typealias EdgeInsets = UIEdgeInsets

    @available(iOS 9.0, *)
    public typealias LayoutGuide = UILayoutGuide
#endif

extension EdgeInsets {
    #if os(OSX)
    public static let zero = EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    #endif
}

extension NSLayoutConstraint {
    public class func activate(_ constraints: [Any]) {
        for item in constraints {
            if let layoutContraint = item as? NSLayoutConstraint {
                layoutContraint.isActive = true
            }else if let layoutConstraints = item as? [NSLayoutConstraint] {
                NSLayoutConstraint.activate(layoutConstraints)
            }
        }
    }
}

public protocol LayoutRegion: AnyObject {}
extension View: LayoutRegion {}

@available(iOS 9.0, OSX 10.11, *)
extension LayoutGuide: LayoutRegion {}

public struct XAxis {}
public struct YAxis {}
public struct Dimension {}

public struct LayoutItem<C> {
    public let item: AnyObject
    public let attribute: NSLayoutAttribute
    public let multiplier: CGFloat
    public let constant: CGFloat

    fileprivate func constrain(_ secondItem: LayoutItem, relation: NSLayoutRelation) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: item, attribute: attribute, relatedBy: relation,
            toItem: secondItem.item, attribute: secondItem.attribute,
            multiplier: secondItem.multiplier, constant: secondItem.constant)
    }

    fileprivate func constrain(_ constant: CGFloat, relation: NSLayoutRelation) -> NSLayoutConstraint {
        return NSLayoutConstraint(
            item: item, attribute: attribute, relatedBy: relation,
            toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: constant)
    }

    fileprivate func itemWithMultiplier(_ multiplier: CGFloat) -> LayoutItem {
        return LayoutItem(
            item: self.item, attribute: self.attribute,
            multiplier: multiplier, constant: self.constant)
    }

    fileprivate func itemWithConstant(_ constant: CGFloat) -> LayoutItem {
        return LayoutItem(
            item: self.item, attribute: self.attribute,
            multiplier: self.multiplier, constant: constant)
    }
}

public func *<C>(lhs: LayoutItem<C>, rhs: CGFloat) -> LayoutItem<C> {
    return lhs.itemWithMultiplier(lhs.multiplier * rhs)
}

public func /<C>(lhs: LayoutItem<C>, rhs: CGFloat) -> LayoutItem<C> {
    return lhs.itemWithMultiplier(lhs.multiplier / rhs)
}

public func +<C>(lhs: LayoutItem<C>, rhs: CGFloat) -> LayoutItem<C> {
    return lhs.itemWithConstant(lhs.constant + rhs)
}

public func -<C>(lhs: LayoutItem<C>, rhs: CGFloat) -> LayoutItem<C> {
    return lhs.itemWithConstant(lhs.constant - rhs)
}

public func ==<C>(lhs: LayoutItem<C>, rhs: LayoutItem<C>) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .equal)
}

public func ==(lhs: LayoutItem<Dimension>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .equal)
}

public func >=<C>(lhs: LayoutItem<C>, rhs: LayoutItem<C>) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .greaterThanOrEqual)
}

public func >=(lhs: LayoutItem<Dimension>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .greaterThanOrEqual)
}

public func <=<C>(lhs: LayoutItem<C>, rhs: LayoutItem<C>) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .lessThanOrEqual)
}

public func <=(lhs: LayoutItem<Dimension>, rhs: CGFloat) -> NSLayoutConstraint {
    return lhs.constrain(rhs, relation: .lessThanOrEqual)
}

infix operator <|: AdditionPrecedence
public func <|(lhs: View, rhs: EdgeInsets) -> [NSLayoutConstraint] {
    return [
        lhs.top == lhs.superview!.top + rhs.top,
        lhs.bottom == lhs.superview!.bottom - rhs.bottom,
        lhs.leading == lhs.superview!.leading + rhs.left,
        lhs.trailing == lhs.superview!.trailing - rhs.right
    ]
}

infix operator <||: AdditionPrecedence
public func <||(lhs: View, rhs: EdgeInsets) -> [NSLayoutConstraint] {
    return [
        lhs.topMargin == lhs.superview!.topMargin + rhs.top,
        lhs.bottomMargin == lhs.superview!.bottomMargin - rhs.bottom,
        lhs.leadingMargin == lhs.superview!.leadingMargin + rhs.left,
        lhs.trailingMargin == lhs.superview!.trailingMargin - rhs.right
    ]
}

postfix operator <|
public postfix func <|(lhs: View) -> [NSLayoutConstraint] {
    return lhs <| EdgeInsets.zero
}

postfix operator <||
public postfix func <||(lhs: View) -> [NSLayoutConstraint] {
    return lhs <|| EdgeInsets.zero
}

public func -<C>(lhs: [NSLayoutConstraint], rhs: LayoutItem<C>) -> [NSLayoutConstraint] {
    var layouts = lhs
    for (index, layout) in lhs.enumerated() {
        if layout.firstAttribute == rhs.attribute {
            layouts.remove(at: index)
            break
        }
    }
    
    return layouts
}

fileprivate func layoutItem<C>(_ item: AnyObject, _ attribute: NSLayoutAttribute) -> LayoutItem<C> {
    return LayoutItem(item: item, attribute: attribute, multiplier: 1.0, constant: 0.0)
}

public extension LayoutRegion {
    public var left: LayoutItem<XAxis> { return layoutItem(self, .left) }
    public var right: LayoutItem<XAxis> { return layoutItem(self, .right) }
    public var top: LayoutItem<YAxis> { return layoutItem(self, .top) }
    public var bottom: LayoutItem<YAxis> { return layoutItem(self, .bottom) }
    public var leading: LayoutItem<XAxis> { return layoutItem(self, .leading) }
    public var trailing: LayoutItem<XAxis> { return layoutItem(self, .trailing) }
    public var width: LayoutItem<Dimension> { return layoutItem(self, .width) }
    public var height: LayoutItem<Dimension> { return layoutItem(self, .height) }
    public var centerX: LayoutItem<XAxis> { return layoutItem(self, .centerX) }
    public var centerY: LayoutItem<YAxis> { return layoutItem(self, .centerY) }
}

public extension View {

    @available(iOS 8.0, OSX 10.11, *)
    public var firstBaseline: LayoutItem<YAxis> { return layoutItem(self, .firstBaseline) }
    public var lastBaseline: LayoutItem<YAxis> { return layoutItem(self, .lastBaseline) }
}

#if os(iOS) || os(tvOS)
    public extension UIViewController {
        public var topLayoutGuideTop: LayoutItem<YAxis> {
            return layoutItem(topLayoutGuide, .top)
        }

        public var topLayoutGuideBottom: LayoutItem<YAxis> {
            return layoutItem(topLayoutGuide, .bottom)
        }

        public var bottomLayoutGuideTop: LayoutItem<YAxis> {
            return layoutItem(bottomLayoutGuide, .top)
        }

        public var bottomLayoutGuideBottom: LayoutItem<YAxis> {
            return layoutItem(bottomLayoutGuide, .bottom)
        }
    }

    public extension UIView {
        public var leftMargin: LayoutItem<XAxis> { return layoutItem(self, .leftMargin) }
        public var rightMargin: LayoutItem<XAxis> { return layoutItem(self, .rightMargin) }
        public var topMargin: LayoutItem<YAxis> { return layoutItem(self, .topMargin) }
        public var bottomMargin: LayoutItem<YAxis> { return layoutItem(self, .bottomMargin) }
        public var leadingMargin: LayoutItem<XAxis> { return layoutItem(self, .leadingMargin) }
        public var trailingMargin: LayoutItem<XAxis> { return layoutItem(self, .trailingMargin) }
        public var centerXWithinMargins: LayoutItem<XAxis> { return layoutItem(self, .centerXWithinMargins) }
        public var centerYWithinMargins: LayoutItem<YAxis> { return layoutItem(self, .centerYWithinMargins) }
    }
#endif

precedencegroup LayoutPriorityPrecedence {
    associativity: left
    higherThan: LogicalConjunctionPrecedence
    lowerThan: ComparisonPrecedence
}

infix operator ~ : LayoutPriorityPrecedence

public func ~(lhs: NSLayoutConstraint, rhs: LayoutPriority) -> NSLayoutConstraint {
    let newConstraint = NSLayoutConstraint(
        item: lhs.firstItem, attribute: lhs.firstAttribute, relatedBy: lhs.relation,
        toItem: lhs.secondItem, attribute: lhs.secondAttribute,
        multiplier: lhs.multiplier, constant: lhs.constant)
    newConstraint.priority = rhs
    return newConstraint
}
