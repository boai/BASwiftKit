//
//  BAPagedWaterfallDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

public final class BAPagedWaterfallDemoViewController: BABaseViewController {

    public init() { super.init(nibName: nil, bundle: nil) }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private struct Item {
        let title: String
        let subtitle: String
        let color: UIColor
    }

    private let layout = BAPagedWaterfallFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let pageIndicator = BAPagedWaterfallPageIndicator()
    private let items: [Item] = (1...22).map { index in
        let colors = [
            UIColor(ba_hex: "#5B6CFF")!, UIColor(ba_hex: "#9B5BFF")!,
            UIColor(ba_hex: "#0EA5E9")!, UIColor(ba_hex: "#22C55E")!,
            UIColor(ba_hex: "#F97316")!, UIColor(ba_hex: "#FF6BCB")!,
            UIColor(ba_hex: "#1FBFB8")!, UIColor(ba_hex: "#EF4F4F")!
        ]
        return Item(title: "\(index)", subtitle: "Item \(index)", color: colors[(index - 1) % colors.count])
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "横向分页瀑布流"
        setupLayout()
    }

    private var previousBoundsSize: CGSize = .zero

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let newSize = view.bounds.size
        guard newSize != previousBoundsSize else { return }
        previousBoundsSize = newSize
        layout.invalidateLayout()
        pageIndicator.pageCount = max(1, Int(ceil(Double(items.count) / Double(layout.itemsPerPage))))
    }

    private func setupLayout() {
        view.addSubview(collectionView)
        view.addSubview(pageIndicator)

        layout.rowCount = 2
        layout.columnCount = 4
        layout.sectionInset = UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 14

        collectionView.backgroundColor = .clear
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.ba_register(BAPagedWaterfallCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self

        pageIndicator.pageCount = max(1, Int(ceil(Double(items.count) / Double(layout.itemsPerPage))))
        pageIndicator.currentPage = 0

        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalToSuperview()
            make.height.equalTo(230)
        }
        pageIndicator.snp.makeConstraints { make in
            make.top.equalTo(collectionView.snp.bottom).offset(16)
            make.centerX.equalToSuperview()
            make.height.equalTo(18)
        }
    }
}

extension BAPagedWaterfallDemoViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.ba_dequeue(BAPagedWaterfallCell.self, for: indexPath)
        let item = items[indexPath.item]
        cell.configure(title: item.title, subtitle: item.subtitle, color: item.color)
        return cell
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageIndicator.currentPage = max(0, min(pageIndicator.pageCount - 1, page))
    }
}

private final class BAPagedWaterfallCell: UICollectionViewCell {
    private let titleLabel = UILabel.ba_make(font: .ba_bold(24), color: .white, alignment: .center)
    private let subtitleLabel = UILabel.ba_make(font: .ba_regular(11), color: UIColor.white.withAlphaComponent(0.82), alignment: .center)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = BAAppTheme.smallCornerRadius
        contentView.layer.masksToBounds = true
        contentView.ba_addSubviews(titleLabel, subtitleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(6)
        }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, subtitle: String, color: UIColor) {
        contentView.backgroundColor = color
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}

private final class BAPagedWaterfallPageIndicator: UIView {
    var pageCount: Int = 0 { didSet { rebuildDots() } }
    var currentPage: Int = 0 { didSet { updateDots() } }

    private let stack = UIStackView.ba_make(axis: .horizontal, spacing: 6, alignment: .center)

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func rebuildDots() {
        stack.arrangedSubviews.forEach { view in
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for index in 0..<pageCount {
            let dot = UIView()
            dot.layer.cornerRadius = 4
            dot.tag = index
            stack.addArrangedSubview(dot)
            dot.snp.makeConstraints { make in
                make.width.equalTo(index == currentPage ? 18 : 8)
                make.height.equalTo(8)
            }
        }
        updateDots()
    }

    private func updateDots() {
        for case let dot as UIView in stack.arrangedSubviews {
            dot.backgroundColor = dot.tag == currentPage ? BAAppTheme.accent : BAAppTheme.textSecondary.withAlphaComponent(0.25)
            dot.snp.updateConstraints { make in
                make.width.equalTo(dot.tag == currentPage ? 18 : 8)
            }
        }
        UIView.animate(withDuration: 0.2) {
            self.layoutIfNeeded()
        }
    }
}
