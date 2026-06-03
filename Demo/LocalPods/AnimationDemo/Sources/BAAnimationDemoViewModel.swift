//
//  BAAnimationDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

struct BAAnimationSample {
    let title: String
    let apply: (UIView) -> Void
}

final class BAAnimationDemoViewModel {

    let samples: BAObservable<[BAAnimationSample]> = BAObservable([])

    func loadData() {
        samples.update([
            BAAnimationSample(title: "Spring Appear") { v in
                v.transform = .identity
                v.alpha = 1
                v.ba_springAppear()
            },
            BAAnimationSample(title: "Shake")     { v in v.ba_shake() },
            BAAnimationSample(title: "Pulse")     { v in
                v.ba_stopPulse()
                v.ba_pulse(scale: 1.12, duration: 0.5, repeatCount: 3)
            },
            BAAnimationSample(title: "Slide Top") { v in v.ba_slideIn(from: .top) },
            BAAnimationSample(title: "Slide Bottom") { v in v.ba_slideIn(from: .bottom) },
            BAAnimationSample(title: "Slide Leading") { v in v.ba_slideIn(from: .leading) },
            BAAnimationSample(title: "Fade Out → In") { v in
                v.ba_fadeOut(duration: 0.25) { _ in v.ba_fadeIn(duration: 0.25) }
            },
            BAAnimationSample(title: "Rotate") { v in v.ba_rotate(by: .pi / 2) }
        ])
    }
}
