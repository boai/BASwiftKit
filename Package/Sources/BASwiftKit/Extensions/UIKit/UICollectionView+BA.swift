//
//  UICollectionView+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBACollectionBinderKey: UInt8 = 0

public extension UICollectionView {

    func ba_register<Cell: UICollectionViewCell>(_ cellType: Cell.Type) {
        register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
    }

    func ba_dequeue<Cell: UICollectionViewCell>(_ cellType: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withReuseIdentifier: String(describing: cellType), for: indexPath) as! Cell
    }

    func ba_subscribe<Item, Cell: UICollectionViewCell>(_ items: [Item],
                                                        cellType: Cell.Type,
                                                        configure: @escaping (Cell, Item, IndexPath) -> Void,
                                                        didSelect: ((Item, IndexPath) -> Void)? = nil) {
        let binder = BACollectionViewBinder(items: items, cellType: cellType, configure: configure, didSelect: didSelect)
        objc_setAssociatedObject(self, &kBACollectionBinderKey, binder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        ba_register(cellType)
        dataSource = binder
        delegate = binder
        reloadData()
    }
}

private final class BACollectionViewBinder<Item, Cell: UICollectionViewCell>: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    private let items: [Item]
    private let cellType: Cell.Type
    private let configure: (Cell, Item, IndexPath) -> Void
    private let didSelect: ((Item, IndexPath) -> Void)?

    init(items: [Item],
         cellType: Cell.Type,
         configure: @escaping (Cell, Item, IndexPath) -> Void,
         didSelect: ((Item, IndexPath) -> Void)?) {
        self.items = items
        self.cellType = cellType
        self.configure = configure
        self.didSelect = didSelect
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.ba_dequeue(cellType, for: indexPath)
        configure(cell, items[indexPath.item], indexPath)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelect?(items[indexPath.item], indexPath)
    }
}
#endif
