//
//  UITableView+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBATableBinderKey: UInt8 = 0

public extension UITableView {

    func ba_register<Cell: UITableViewCell>(_ cellType: Cell.Type) {
        register(cellType, forCellReuseIdentifier: String(describing: cellType))
    }

    func ba_dequeue<Cell: UITableViewCell>(_ cellType: Cell.Type, for indexPath: IndexPath) -> Cell {
        dequeueReusableCell(withIdentifier: String(describing: cellType), for: indexPath) as! Cell
    }

    func ba_subscribe<Item, Cell: UITableViewCell>(_ items: [Item],
                                                   cellType: Cell.Type,
                                                   rowHeight: CGFloat = UITableView.automaticDimension,
                                                   configure: @escaping (Cell, Item, IndexPath) -> Void,
                                                   didSelect: ((Item, IndexPath) -> Void)? = nil) {
        let binder = BATableViewBinder(items: items, cellType: cellType, rowHeight: rowHeight, configure: configure, didSelect: didSelect)
        objc_setAssociatedObject(self, &kBATableBinderKey, binder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        ba_register(cellType)
        dataSource = binder
        delegate = binder
        reloadData()
    }
}

private final class BATableViewBinder<Item, Cell: UITableViewCell>: NSObject, UITableViewDataSource, UITableViewDelegate {
    private let items: [Item]
    private let cellType: Cell.Type
    private let rowHeight: CGFloat
    private let configure: (Cell, Item, IndexPath) -> Void
    private let didSelect: ((Item, IndexPath) -> Void)?

    init(items: [Item],
         cellType: Cell.Type,
         rowHeight: CGFloat,
         configure: @escaping (Cell, Item, IndexPath) -> Void,
         didSelect: ((Item, IndexPath) -> Void)?) {
        self.items = items
        self.cellType = cellType
        self.rowHeight = rowHeight
        self.configure = configure
        self.didSelect = didSelect
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.ba_dequeue(cellType, for: indexPath)
        configure(cell, items[indexPath.row], indexPath)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelect?(items[indexPath.row], indexPath)
    }
}
#endif
