//
//  BAWaterfallFlowLayout.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit

/// 瀑布流布局方向。
public enum BAWaterfallScrollDirection {
    /// 纵向滚动，按列排布，自动把 item 放入当前最短列。
    case vertical
    /// 横向滚动，按行排布，自动把 item 放入当前最短行。
    case horizontal
}

/// 瀑布流布局代理。
///
/// 代理只负责提供 item 原始尺寸，布局会根据当前方向自动等比缩放：纵向布局固定 item 宽度后计算高度，
/// 横向布局固定 item 高度后计算宽度。这样业务只需要返回图片或卡片的真实宽高比例即可。
public protocol BAWaterfallFlowLayoutDelegate: AnyObject {
    /// 返回指定 item 的原始尺寸或期望比例。
    ///
    /// - Parameters:
    ///   - layout: 当前瀑布流布局。
    ///   - indexPath: item 位置。
    /// - Returns: 原始尺寸。宽高任一小于等于 0 时会使用布局默认 item 尺寸。
    func waterfallFlowLayout(_ layout: BAWaterfallFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
}

/// 自适应横向/纵向瀑布流 FlowLayout。
///
/// - 纵向：`columnCount` 控制列数，item 宽度由 collectionView 宽度、sectionInset 和列间距自动计算，高度按代理尺寸等比换算。
/// - 横向：`rowCount` 控制行数，item 高度由 collectionView 高度、sectionInset 和行间距自动计算，宽度按代理尺寸等比换算。
/// - 多 section：每个 section 会独立重新计算列/行起点，适合首页模块、商品列表、图片墙等场景。
open class BAWaterfallFlowLayout: UICollectionViewLayout {
    /// 布局代理。
    public weak var delegate: BAWaterfallFlowLayoutDelegate?
    /// 滚动方向，默认纵向瀑布流。
    public var scrollDirection: BAWaterfallScrollDirection = .vertical { didSet { invalidateLayout() } }
    /// 纵向瀑布流列数，最小为 1。
    public var columnCount: Int = 2 { didSet { invalidateLayout() } }
    /// 横向瀑布流行数，最小为 1。
    public var rowCount: Int = 2 { didSet { invalidateLayout() } }
    /// section 内边距。
    public var sectionInset: UIEdgeInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12) { didSet { invalidateLayout() } }
    /// item 横向间距。
    public var minimumInteritemSpacing: CGFloat = 10 { didSet { invalidateLayout() } }
    /// item 纵向间距。
    public var minimumLineSpacing: CGFloat = 10 { didSet { invalidateLayout() } }
    /// 未提供代理或代理返回无效尺寸时使用的默认 item 尺寸。
    public var defaultItemSize: CGSize = CGSize(width: 120, height: 160) { didSet { invalidateLayout() } }

    private var itemAttributes: [UICollectionViewLayoutAttributes] = []
    private var contentSize: CGSize = .zero

    open override var collectionViewContentSize: CGSize { contentSize }

    open override func prepare() {
        super.prepare()
        guard let collectionView else { return }
        itemAttributes.removeAll()

        switch scrollDirection {
        case .vertical:
            prepareVerticalLayout(in: collectionView)
        case .horizontal:
            prepareHorizontalLayout(in: collectionView)
        }
    }

    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        itemAttributes.filter { $0.frame.intersects(rect) }
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        itemAttributes.first { $0.indexPath == indexPath }
    }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        collectionView?.bounds.size != newBounds.size
    }

    private func prepareVerticalLayout(in collectionView: UICollectionView) {
        let sectionCount = collectionView.numberOfSections
        let availableWidth = collectionView.bounds.width
        let columns = max(1, columnCount)
        let totalSpacing = CGFloat(columns - 1) * minimumInteritemSpacing
        let itemWidth = max(0, (availableWidth - sectionInset.left - sectionInset.right - totalSpacing) / CGFloat(columns))
        var sectionTop: CGFloat = 0

        for section in 0..<sectionCount {
            var columnHeights = Array(repeating: sectionTop + sectionInset.top, count: columns)
            let itemCount = collectionView.numberOfItems(inSection: section)

            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let column = indexOfMinimumValue(in: columnHeights)
                let x = sectionInset.left + CGFloat(column) * (itemWidth + minimumInteritemSpacing)
                let y = columnHeights[column]
                let itemHeight = scaledHeight(for: indexPath, width: itemWidth)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                columnHeights[column] = attributes.frame.maxY + minimumLineSpacing
            }

            let maxColumnHeight = columnHeights.max() ?? sectionTop
            sectionTop = maxColumnHeight - minimumLineSpacing + sectionInset.bottom
        }

        contentSize = CGSize(width: collectionView.bounds.width, height: max(collectionView.bounds.height, sectionTop))
    }

    private func prepareHorizontalLayout(in collectionView: UICollectionView) {
        let sectionCount = collectionView.numberOfSections
        let availableHeight = collectionView.bounds.height
        let rows = max(1, rowCount)
        let totalSpacing = CGFloat(rows - 1) * minimumLineSpacing
        let itemHeight = max(0, (availableHeight - sectionInset.top - sectionInset.bottom - totalSpacing) / CGFloat(rows))
        var sectionLeft: CGFloat = 0

        for section in 0..<sectionCount {
            var rowWidths = Array(repeating: sectionLeft + sectionInset.left, count: rows)
            let itemCount = collectionView.numberOfItems(inSection: section)

            for item in 0..<itemCount {
                let indexPath = IndexPath(item: item, section: section)
                let row = indexOfMinimumValue(in: rowWidths)
                let x = rowWidths[row]
                let y = sectionInset.top + CGFloat(row) * (itemHeight + minimumLineSpacing)
                let itemWidth = scaledWidth(for: indexPath, height: itemHeight)
                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(x: x, y: y, width: itemWidth, height: itemHeight)
                itemAttributes.append(attributes)
                rowWidths[row] = attributes.frame.maxX + minimumInteritemSpacing
            }

            let maxRowWidth = rowWidths.max() ?? sectionLeft
            sectionLeft = maxRowWidth - minimumInteritemSpacing + sectionInset.right
        }

        contentSize = CGSize(width: max(collectionView.bounds.width, sectionLeft), height: collectionView.bounds.height)
    }

    private func scaledHeight(for indexPath: IndexPath, width: CGFloat) -> CGFloat {
        let size = validSize(for: indexPath)
        guard size.width > 0 else { return defaultItemSize.height }
        return max(1, width * size.height / size.width)
    }

    private func scaledWidth(for indexPath: IndexPath, height: CGFloat) -> CGFloat {
        let size = validSize(for: indexPath)
        guard size.height > 0 else { return defaultItemSize.width }
        return max(1, height * size.width / size.height)
    }

    private func validSize(for indexPath: IndexPath) -> CGSize {
        let size = delegate?.waterfallFlowLayout(self, sizeForItemAt: indexPath) ?? defaultItemSize
        guard size.width > 0, size.height > 0 else { return defaultItemSize }
        return size
    }

    private func indexOfMinimumValue(in values: [CGFloat]) -> Int {
        values.enumerated().min(by: { $0.element < $1.element })?.offset ?? 0
    }
}
#endif
