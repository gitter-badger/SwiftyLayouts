//
//  CardViewLayout.swift
//  SwiftyLayouts
//
//  Created by kaushal on 19/01/18.
//  Copyright © 2018 kaushal. All rights reserved.
//

import UIKit

public protocol LayoutDelegate : class {
    func collectionView(_ collectionView:UICollectionView, heightForCellAtIndexPath indexPath:IndexPath) -> CGFloat
    func collectionView(_ collectionView:UICollectionView, ofSuplementryViewKind kind: String,  heightAtIndexPath indexPath:IndexPath) -> CGFloat
}

public extension LayoutDelegate {
    
    func collectionView(_ collectionView:UICollectionView, heightForCellAtIndexPath indexPath:IndexPath) -> CGFloat {
        return 45
    }
    
    func collectionView(_ collectionView:UICollectionView, ofSuplementryViewKind kind: String,  heightAtIndexPath indexPath:IndexPath) -> CGFloat {
        if indexPath == IndexPath(index:0) {
            return CGFloat.leastNormalMagnitude
        }
        return 0
    }

}


public extension UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let separator:UICollectionReusableView = UICollectionReusableView(frame:CGRect(x: 0, y: 0, width: 200, height: 200))
            separator.backgroundColor = #colorLiteral(red: 0.7450980544, green: 0.1568627506, blue: 0.07450980693, alpha: 1)
            if indexPath == IndexPath(index:0) {
                separator.backgroundColor = #colorLiteral(red: 0.7598647549, green: 0.5621008782, blue: 1, alpha: 1)
            }
        return separator
    }
}

public class CardViewLayout: UICollectionViewLayout {
    
    private var registeredDecorationClasses:[String : AnyClass] = [:]
    private var itemLayoutAttributeCache        =       [IndexPath : UICollectionViewLayoutAttributes]()
    private var decorationLayoutAttributeCache  =       [IndexPath : UICollectionViewLayoutAttributes]()
    private var headerLayoutAttributeCache      =       [IndexPath : UICollectionViewLayoutAttributes]()
    private var footerLayoutAttributeCache      =       [IndexPath : UICollectionViewLayoutAttributes]()
    private var globalHeaderAttributes:UICollectionViewLayoutAttributes = UICollectionViewLayoutAttributes()
    
    private var collectionViewContentHeight: CGFloat = 0
    public var layoutSetting = LayoutSetting()
    public weak var delegate: LayoutDelegate!

    private var collectionViewContentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }
    
    public override var collectionViewContentSize: CGSize {
        return CGSize(width: collectionViewContentWidth, height: collectionViewContentHeight)
    }
    
    private var cellWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right) - (layoutSetting.cellMargin.left + layoutSetting.cellMargin.right)
    }
    
    public override func register(_ viewClass: AnyClass?, forDecorationViewOfKind elementKind: String) {
        registeredDecorationClasses[elementKind] = viewClass
        super.register(viewClass, forDecorationViewOfKind: elementKind)
    }
}

// MARK: - Layout Core Process
extension CardViewLayout {
    public override func prepare() {
        //prepare item layout attributs
        prepareLayoutAttributesCache()
    }
    
    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var visibleLayoutAttributes = [UICollectionViewLayoutAttributes]()
        
        // Loop through the cache and look for items in the rect
        let allLayoutAttributeCache:[UICollectionViewLayoutAttributes] = Array(headerLayoutAttributeCache.values) + Array(itemLayoutAttributeCache.values)
        //Global header
        
        //End of global header
        var section:Int = 0
        for attributes in allLayoutAttributeCache {
            switch attributes.representedElementCategory {
            case .cell :
                if attributes.frame.intersects(rect) {
                    visibleLayoutAttributes.append(attributes)
                }
            case .supplementaryView :
                if layoutSetting.floatingHeaders {
                    var indexPath:IndexPath = IndexPath(item: 0, section: section)
                    if attributes === globalHeaderAttributes {
                        indexPath = IndexPath(index: 0)
                    }
                updateSupplementaryViews(attributes: attributes, collectionView: collectionView!, indexPath:indexPath)
                    section = section + 1
                    visibleLayoutAttributes.append(attributes)
                } else if attributes.frame.intersects(rect) {
                    visibleLayoutAttributes.append(attributes)
                }
            case .decorationView :
                break
            }
        }
        return visibleLayoutAttributes
    }
    
   @discardableResult public override func shouldInvalidateLayout(
                                            forBoundsChange newBounds: CGRect) -> Bool {
    return true
//    return !newBounds.size.equalTo(self.collectionView!.frame.size)
    }
}

//MARK: - CollectionView Layout attributes
extension CardViewLayout {
    
    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        return itemLayoutAttributeCache[indexPath]!
    }
    
    public override func layoutAttributesForSupplementaryView(ofKind elementKind:String,
                                                              at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        switch elementKind {
        case UICollectionElementKindSectionHeader:
            guard let headerAttribute = headerLayoutAttributeCache[indexPath] else {
                return nil
            }
            return headerAttribute
        case UICollectionElementKindSectionFooter:
            guard let footerAttribute = footerLayoutAttributeCache[indexPath] else {
                return nil
            }
            return footerAttribute
        default:
            fatalError("wrong element kind for suplementry view")
        }
    }
    
    public override func layoutAttributesForDecorationView(ofKind elementKind: String,
                                                           at indexPath: IndexPath) -> UICollectionViewLayoutAttributes {
        guard let decorationAttribute = decorationLayoutAttributeCache[indexPath] else {
            fatalError("decoration view elemen is must to draw layout")
        }
        return decorationAttribute
    }
}

//MARK: - Private Methods
private extension CardViewLayout {
        
    private func prepareLayoutAttributesCache() {
        // method to prepare cache.
        guard let collectionView = collectionView,
            itemLayoutAttributeCache.isEmpty else {
                return
        }
        collectionViewContentHeight = 0
        //Global header
        if  isGlobalHeaderProvided() {
            let globalIndexPath = IndexPath(index: 0)
            globalHeaderAttributes = createSuplementryAttribute(ofKind:UICollectionElementKindSectionHeader, cellIndexPath:globalIndexPath)
            collectionViewContentHeight = globalHeaderAttributes.frame.maxY
            headerLayoutAttributeCache[globalIndexPath] = globalHeaderAttributes
        }
        
        for section in 0 ..< collectionView.numberOfSections {
            //header layouts
            let headerIndexPath = IndexPath(item:0, section: section)
            let sectionHeaderAttribute = createSuplementryAttribute(ofKind:UICollectionElementKindSectionHeader, cellIndexPath:headerIndexPath )
            collectionViewContentHeight = sectionHeaderAttribute.frame.maxY
            headerLayoutAttributeCache[headerIndexPath] = sectionHeaderAttribute
            
            for item in 0 ..< collectionView.numberOfItems(inSection: section) {
                //cell layouts
                let cellIndexPath = IndexPath(item: item, section: section)
                let attribute = createItemAttribute(forCellWith:cellIndexPath)
                collectionViewContentHeight = attribute.frame.maxY
                itemLayoutAttributeCache[cellIndexPath] = attribute
            }
        }
    }
    
    private func createItemAttribute(forCellWith cellIndexPath:IndexPath) -> (UICollectionViewLayoutAttributes) {
        let attribute = UICollectionViewLayoutAttributes(forCellWith: cellIndexPath)
        let cellHeight: CGFloat = delegate.collectionView(self.collectionView!, heightForCellAtIndexPath: cellIndexPath)
        let itemMinY:CGFloat = collectionViewContentHeight + layoutSetting.cellMargin.top
        let itemMaxY:CGFloat = itemMinY + cellHeight + layoutSetting.cellMargin.bottom
        let itemMinX:CGFloat = layoutSetting.cellMargin.left + layoutSetting.contentMargin.left
        let itemMaxX:CGFloat = collectionView!.bounds.width - (layoutSetting.cellMargin.right + layoutSetting.contentMargin.right)
        attribute.frame = CGRect(
            x:itemMinX,
            y:itemMinY,
            width:(itemMaxX - itemMinX),
            height:(itemMaxY - itemMinY)
        )
        attribute.zIndex = layoutSetting.minItemZIndex
        
       return attribute
    }
    
    private func createSuplementryAttribute(ofKind kind:String, cellIndexPath:IndexPath) -> (UICollectionViewLayoutAttributes) {
    
        let attribute = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind:UICollectionElementKindSectionHeader, with:cellIndexPath)
        
        let cellHeight: CGFloat = delegate.collectionView(self.collectionView!, ofSuplementryViewKind:UICollectionElementKindSectionHeader, heightAtIndexPath: cellIndexPath)
        let itemMinY:CGFloat = (collectionViewContentHeight + layoutSetting.sectionMargin.top)
        let itemMaxY:CGFloat = itemMinY + cellHeight + layoutSetting.sectionMargin.bottom
        let itemMinX:CGFloat = layoutSetting.sectionMargin.left + layoutSetting.contentMargin.left
        let itemMaxX:CGFloat = collectionView!.bounds.width - (layoutSetting.sectionMargin.right + layoutSetting.contentMargin.right)
        attribute.frame = CGRect(
            x:itemMinX,
            y:itemMinY,
            width:(itemMaxX - itemMinX),
            height:(itemMaxY - itemMinY)
        )
        attribute.zIndex = layoutSetting.minHeaderOverlayZIndex
        
        return attribute
    }

    
    private func updateCells(_ attributes: UICollectionViewLayoutAttributes, halfHeight: CGFloat, halfCellHeight: CGFloat) {
        
    }
    
    private func updateSupplementaryViews(attributes: UICollectionViewLayoutAttributes, collectionView: UICollectionView, indexPath: IndexPath) {
        
        var cellHeight: CGFloat = delegate.collectionView(self.collectionView!, ofSuplementryViewKind:UICollectionElementKindSectionHeader, heightAtIndexPath: indexPath)
        var offset = collectionView.contentOffset.y + collectionView.contentInset.top
        offset = offset + layoutSetting.sectionMargin.top
        var firstAttributeFrame:CGRect = CGRect.zero
        var lastAttributeFrame:CGRect = CGRect.zero
        var itemMinY:CGFloat
        if offset < 0 {
            offset = 0
        } else if (offset > collectionView.frame.size.height) && (offset > (collectionView.contentSize.height - collectionView.frame.size.height)) {
            offset = collectionView.contentSize.height - collectionView.frame.size.height
        }
        
        let heightValue = collectionView.contentSize.height - collectionView.bounds.size.height
        
        //Global header
        if indexPath.count == 1 {
            if (offset < 100) {
                cellHeight = cellHeight - offset
            } else {
                cellHeight = cellHeight - 100
            }
            firstAttributeFrame = (itemLayoutAttributeCache[IndexPath(item:0, section:0)]?.frame)!
            lastAttributeFrame = (headerLayoutAttributeCache[IndexPath(item:0, section:0)]?.frame)!
            itemMinY = min(max(offset, firstAttributeFrame.minY - cellHeight - CGFloat(50)), heightValue)
            attributes.zIndex = layoutSetting.minHeaderOverlayZIndex + 10
            
        } else {
            let numberOfItemsInSection:Int = collectionView.numberOfItems(inSection: indexPath.section)
            firstAttributeFrame = (itemLayoutAttributeCache[indexPath]?.frame)!
            lastAttributeFrame = (itemLayoutAttributeCache[IndexPath(item: max(0,numberOfItemsInSection-1), section: indexPath.section )]?.frame)!
            offset = offset + globalHeaderAttributes.frame.height + layoutSetting.sectionMargin.top

            itemMinY = min(
                max(offset, (firstAttributeFrame.minY - cellHeight)),
                (lastAttributeFrame.maxY - cellHeight))
            attributes.zIndex = layoutSetting.minHeaderOverlayZIndex
        }
        
        let itemMaxY:CGFloat = itemMinY + cellHeight + layoutSetting.sectionMargin.bottom
        let itemMinX:CGFloat = layoutSetting.sectionMargin.left + layoutSetting.contentMargin.left
        let itemMaxX:CGFloat = collectionView.bounds.width - (layoutSetting.sectionMargin.right + layoutSetting.contentMargin.right)
        attributes.frame = CGRect(
            x:itemMinX,
            y:itemMinY,
            width:(itemMaxX - itemMinX),
            height:(itemMaxY - itemMinY)
        )
    }
    
    func invalidateLayoutWithCache() -> Void {
        // Invalidate cached Components
        itemLayoutAttributeCache.removeAll(keepingCapacity: true)
        decorationLayoutAttributeCache.removeAll(keepingCapacity: true)
        headerLayoutAttributeCache.removeAll(keepingCapacity: true)
        footerLayoutAttributeCache.removeAll(keepingCapacity: true)

        shouldInvalidateLayout(forBoundsChange: CGRect.zero)
    }
    
    func zIndexFor(_ elementKind:String, floating:Bool = false) -> CGFloat {
        
        if elementKind == LayoutElementKind.itemTopDecorator.rawValue {
            
        }
        return 10
    }
    
   /* func rectForSection(section:Int) -> CGRect {
        var sectionRect = CGRect.zero
        return sectionRect
    } */
    
    private func isGlobalHeaderProvided () -> (Bool) {
        var isHeader:Bool = false
        let height = delegate.collectionView(self.collectionView!, ofSuplementryViewKind:UICollectionElementKindSectionHeader, heightAtIndexPath: IndexPath(index:0))
        if height > CGFloat.leastNormalMagnitude {
            isHeader = true
        }
        
        return isHeader
    }

}



