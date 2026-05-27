//
//  BAWaterfallDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAWaterfallDemoViewController: BABaseViewController {

    private struct Item {
        let title: String
        let size: CGSize
        let color: UIColor
    }

    private let layout = BAWaterfallFlowLayout()
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
    private let segmentedControl = UISegmentedControl(items: ["纵向瀑布流", "横向瀑布流"])
    private let items: [Item] = (0..<36).map { index in
        let heights: [CGFloat] = [120, 160, 210, 140, 260, 180, 230, 150]
        let widths: [CGFloat] = [120, 180, 240, 150, 210, 280, 170, 230]
        let colors = [
            UIColor(ba_hex: "#5B6CFF")!, UIColor(ba_hex: "#9B5BFF")!,
            UIColor(ba_hex: "#0EA5E9")!, UIColor(ba_hex: "#22C55E")!,
            UIColor(ba_hex: "#F97316")!, UIColor(ba_hex: "#FF6BCB")!
        ]
        return Item(title: "#\(index + 1)",
                    size: CGSize(width: widths[index % widths.count], height: heights[index % heights.count]),
                    color: colors[index % colors.count])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "瀑布流 FlowLayout"
        setupLayout()
        applyVerticalLayout()
    }

    private func setupLayout() {
        view.addSubview(segmentedControl)
        view.addSubview(collectionView)

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(changeLayoutMode), for: .valueChanged)

        layout.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.ba_register(BAWaterfallDemoCell.self)
        collectionView.dataSource = self

        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(36)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview()
        }
    }

    @objc private func changeLayoutMode() {
        if segmentedControl.selectedSegmentIndex == 0 {
            applyVerticalLayout()
        } else {
            applyHorizontalLayout()
        }
    }

    private func applyVerticalLayout() {
        layout.scrollDirection = .vertical
        layout.columnCount = 2
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        collectionView.alwaysBounceVertical = true
        collectionView.alwaysBounceHorizontal = false
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    private func applyHorizontalLayout() {
        layout.scrollDirection = .horizontal
        layout.rowCount = 2
        layout.sectionInset = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.collectionViewLayout.invalidateLayout()
    }
}

extension BAWaterfallDemoViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.ba_dequeue(BAWaterfallDemoCell.self, for: indexPath)
        cell.configure(title: items[indexPath.item].title,
                       size: items[indexPath.item].size,
                       color: items[indexPath.item].color)
        return cell
    }
}

extension BAWaterfallDemoViewController: BAWaterfallFlowLayoutDelegate {
    func waterfallFlowLayout(_ layout: BAWaterfallFlowLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        items[indexPath.item].size
    }
}

private final class BAWaterfallDemoCell: UICollectionViewCell {
    private let titleLabel = UILabel.ba_make(font: .ba_semibold(18), color: .white)
    private let detailLabel = UILabel.ba_make(font: .ba_regular(12), color: UIColor.white.withAlphaComponent(0.8), numberOfLines: 0)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = BAAppTheme.cornerRadius
        contentView.layer.masksToBounds = true
        contentView.ba_addSubviews(titleLabel, detailLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(14)
        }
        detailLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(14)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(title: String, size: CGSize, color: UIColor) {
        contentView.backgroundColor = color
        titleLabel.text = title
        detailLabel.text = "原始比例\n\(Int(size.width)) × \(Int(size.height))"
    }
}
