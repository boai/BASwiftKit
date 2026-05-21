//
//  UIImage+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIImage {

    /// 根据纯色生成 1×1 图片
    static func ba_image(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// 缩放至指定尺寸（保持当前 scale）
    func ba_resized(to size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 圆形头像裁剪
    func ba_roundedToCircle() -> UIImage? {
        let minSide = min(size.width, size.height)
        let square = CGSize(width: minSide, height: minSide)
        let renderer = UIGraphicsImageRenderer(size: square)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: square)
            UIBezierPath(ovalIn: rect).addClip()
            let drawRect = CGRect(
                x: (square.width - size.width) / 2,
                y: (square.height - size.height) / 2,
                width: size.width,
                height: size.height
            )
            self.draw(in: drawRect)
        }
    }

    /// 着色（生成同形状的纯色图）
    func ba_tinted(_ color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            draw(in: CGRect(origin: .zero, size: size), blendMode: .destinationIn, alpha: 1)
        }
    }

    /// 压缩到目标体积（KB），通过逐步降低 JPEG 质量
    func ba_compressed(toKB targetKB: Int) -> Data? {
        var quality: CGFloat = 0.9
        guard var data = jpegData(compressionQuality: quality) else { return nil }
        let max = targetKB * 1024
        while data.count > max, quality > 0.1 {
            quality -= 0.1
            guard let next = jpegData(compressionQuality: quality) else { break }
            data = next
        }
        return data
    }
}
#endif
