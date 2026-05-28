//
//  BAPagedWaterfallFlowLayout.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit

/// 横向分页瀑布流/宫格布局。
///
/// 适合首页金刚区、分类入口、菜单分页等场景。布局按页横向滚动，每页内部按”行优先”排布：
/// 当 `rowCount = 2`、`columnCount = 4` 时，第 1 页第一行是 1/2/3/4，第二行是 5/6/7/8，
/// 第 2 页继续从 9 开始。布局会自动根据 collectionView 尺寸计算 item 宽高。
///
/// - Note: 本布局暂不支持 Supplementary Views（Header/Footer）和 Decoration Views。
open class BAPagedWaterfallFlowLayout: UICollectionViewLayout {
    /// 每页行数，最小为 1。
    public var rowCount: Int = 2 { didSet { invalidateLayout() } }
    /// 每页列数，最小为 1。
    public var columnCount: Int = 4 { didSet { invalidateLayout() } }
    /// 每页内容内边距。
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16) { didSet { invalidateLayout() } }
    /// 同一行内 item 的横向间距。
    public var minimumInteritemSpacing: CGFloat = 12 { didSet { invalidateLayout() } }
    /// 不同行之间的纵向间距。
    public var minimumLineSpacing: CGFloat = 12 { didSet { invalidateLayout() } }

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero

    /// 每页最大 item 数。
    public var itemsPerPage: Int { max(1, rowCount) * max(1, columnCount) }
    /// 当前内容页数。
    public private(set) var pageCount: Int = 0

    open override var collectionViewContentSize: CGSize { contentSize }

    open override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        itemAttributes.removeAll()

        let rows = max(1, rowCount)
        let columns = max(1, columnCount)
        let pageItemCount = rows * columns
        let pageWidth = collectionView.bounds.width
        let pageHeight = collectionView.bounds.height
        let itemWidth = max(1, (pageWidth - sectionInset.left - sectionInset.right - CGFloat(columns - 1) * minimumInteritemSpacing) / CGFloat(columns))
        let itemHeight = max(1, (pageHeight - sectionInset.top - sectionInset.bottom - CGFloat(rows - 1) * minimumLineSpacing) / CGFloat(rows))

        var totalItems = 0
        for section in 0..<collectionView.numberOfSections {
            totalItems += collectionView.numberOfItems(inSection: section)
        }
        pageCount = Int(ceil(Double(totalItems) / Double(pageItemCount)))

        var globalIndex = 0
        for section in 0..<collectionView.numberOfSections {
            for item in 0..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: item, section: section)
                let page = globalIndex / pageItemCount
                let indexInPage = globalIndex % pageItemCount
                let row = indexInPage / columns
                let column = indexInPage % columns
                let x = CGFloat(page) * pageWidth + sectionInset.left + CGFloat(column) * (itemWidth + minimumInteritemSpacing)
                let y = sectionInset.top + CGFloat(row) * (itemHeight + minimumLineSpacing)

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                globalIndex += 1
            }
        }

        contentSize = CGSize(width: CGFloat(max(1, pageCount)) * pageWidth, height: pageHeight)
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter { $0.frame.intersects(rect) }
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.first { $0.indexPath == indexPath }
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        nil
    }

    open override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        nil
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }
}
#endif
