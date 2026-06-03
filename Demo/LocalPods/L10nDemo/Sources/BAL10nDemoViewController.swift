//
//  BAL10nDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

final class BAL10nDemoViewController: BABaseViewController {

    private let viewModel: BAL10nDemoViewModel
    private let disposeBag = BADisposeBag()

    private let segment = UISegmentedControl(items: ["English", "中文"])
    private let titleLabel = UILabel()
    private let greetingLabel = UILabel()
    private let langCaption = UILabel()
    private let langValue = UILabel()
    private let ctaButton = UIButton(type: .system)

    init(viewModel: BAL10nDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel.registerTables()
        setupLayout()
        bindViewModel()
    }

    private func setupLayout() {
        let stack = UIStackView.ba_make(axis: .vertical, spacing: 16, alignment: .fill)

        titleLabel.font = .ba_bold(24)
        titleLabel.textColor = BAAppTheme.textPrimary
        titleLabel.textAlignment = .center

        greetingLabel.font = .ba_medium(18)
        greetingLabel.textColor = BAAppTheme.textPrimary
        greetingLabel.textAlignment = .center
        greetingLabel.numberOfLines = 0

        langCaption.font = .ba_regular(13)
        langCaption.textColor = BAAppTheme.textSecondary
        langCaption.textAlignment = .center

        langValue.font = .ba_mono(14, weight: .medium)
        langValue.textColor = BAAppTheme.accent
        langValue.textAlignment = .center

        segment.selectedSegmentIndex = viewModel.currentLanguage.value.hasPrefix("zh") ? 1 : 0
        segment.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)

        ctaButton.titleLabel?.font = .ba_semibold(15)
        ctaButton.backgroundColor = BAAppTheme.accent
        ctaButton.setTitleColor(.white, for: .normal)
        ctaButton.layer.cornerRadius = BAAppTheme.smallCornerRadius
        ctaButton.layer.cornerCurve = .continuous
        ctaButton.ba_setShadow(color: BAAppTheme.accent, opacity: 0.22, radius: 12, offset: CGSize(width: 0, height: 6))
        ctaButton.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }

        stack.ba_addArrangedSubviews(titleLabel, greetingLabel, segment, langCaption, langValue, ctaButton)
        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(32)
            make.left.right.equalToSuperview().inset(20)
        }
    }

    @objc private func segmentChanged() {
        let lang = segment.selectedSegmentIndex == 0 ? "en" : "zh-Hans"
        viewModel.setLanguage(lang)
    }

    private func bindViewModel() {
        viewModel.currentLanguage.bind { [weak self] lang in
            self?.refreshTexts(language: lang)
        }.disposed(by: disposeBag)
    }

    private func refreshTexts(language: String) {
        titleLabel.text = "l10n.title".ba_localized
        greetingLabel.text = "l10n.greeting".ba_localized
        langCaption.text = "l10n.lang.label".ba_localized
        langValue.text = language
        ctaButton.setTitle("l10n.cta".ba_localized, for: .normal)
        title = "l10n.title".ba_localized
    }
}
