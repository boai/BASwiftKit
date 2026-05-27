//
//  UIImage+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import CoreImage

public extension UIImage {

    // MARK: - 常用变量

    /// 图片像素宽度。
    var ba_pixelWidth: Int { cgImage?.width ?? Int(size.width * scale) }

    /// 图片像素高度。
    var ba_pixelHeight: Int { cgImage?.height ?? Int(size.height * scale) }

    /// 图片像素尺寸。
    var ba_pixelSize: CGSize { CGSize(width: ba_pixelWidth, height: ba_pixelHeight) }

    /// 宽高比，宽度除以高度。
    var ba_aspectRatio: CGFloat { size.height == 0 ? 0 : size.width / size.height }

    /// 图片是否为横图。
    var ba_isLandscape: Bool { size.width > size.height }

    /// 图片是否为竖图。
    var ba_isPortrait: Bool { size.height > size.width }

    /// 是否包含 alpha 通道。
    var ba_hasAlpha: Bool {
        guard let alphaInfo = cgImage?.alphaInfo else { return false }
        return alphaInfo == .first || alphaInfo == .last || alphaInfo == .premultipliedFirst || alphaInfo == .premultipliedLast
    }

    /// PNG 编码数据。
    var ba_pngData: Data? { pngData() }

    /// JPEG 编码数据，压缩质量为 0.9。
    var ba_jpegData: Data? { jpegData(compressionQuality: 0.9) }

    /// Base64 PNG 字符串。
    var ba_base64PNGString: String? { pngData()?.base64EncodedString() }

    /// 将图片渲染模式改为 `.alwaysOriginal`。
    var ba_original: UIImage { withRenderingMode(.alwaysOriginal) }

    /// 将图片渲染模式改为 `.alwaysTemplate`。
    var ba_template: UIImage { withRenderingMode(.alwaysTemplate) }

    /// 修正方向后的图片，适合上传或进行像素级处理前调用。
    var ba_normalized: UIImage {
        guard imageOrientation != .up else { return self }
        return ba_resized(to: size) ?? self
    }

    // MARK: - Create

    /// 根据纯色生成图片。
    ///
    /// - Parameters:
    ///   - color: 填充颜色。
    ///   - size: 图片尺寸，默认 1×1。
    /// - Returns: 生成的图片。
    static func ba_image(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage? {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// 根据渐变色生成图片。
    ///
    /// - Parameters:
    ///   - colors: 渐变颜色数组。
    ///   - size: 图片尺寸。
    ///   - startPoint: 起点，取值为 0~1 的相对坐标。
    ///   - endPoint: 终点，取值为 0~1 的相对坐标。
    /// - Returns: 生成的渐变图片。
    static func ba_gradientImage(colors: [UIColor],
                                 size: CGSize,
                                 startPoint: CGPoint = CGPoint(x: 0, y: 0.5),
                                 endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) -> UIImage? {
        guard !colors.isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgColors = colors.map { $0.cgColor } as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: nil) else { return }
            let start = CGPoint(x: size.width * startPoint.x, y: size.height * startPoint.y)
            let end = CGPoint(x: size.width * endPoint.x, y: size.height * endPoint.y)
            context.cgContext.drawLinearGradient(gradient, start: start, end: end, options: [])
        }
    }

    /// 从 Base64 字符串解码图片。
    ///
    /// - Parameter string: Base64 图片字符串。
    /// - Returns: 解码成功返回图片，否则返回 `nil`。
    static func ba_image(base64String string: String) -> UIImage? {
        guard let data = Data(base64Encoded: string) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Resize / Crop

    /// 缩放至指定尺寸。
    ///
    /// - Parameter size: 目标尺寸，单位 point。
    /// - Returns: 缩放后的图片。
    func ba_resized(to size: CGSize) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 按最大边等比缩放。
    ///
    /// - Parameter maxSide: 最大边长度，单位 point。
    /// - Returns: 缩放后的图片；原图已小于最大边时返回原图。
    func ba_resized(maxSide: CGFloat) -> UIImage? {
        guard maxSide > 0, max(size.width, size.height) > maxSide else { return self }
        let ratio = maxSide / max(size.width, size.height)
        return ba_resized(to: CGSize(width: size.width * ratio, height: size.height * ratio))
    }

    /// 按目标宽度等比缩放。
    ///
    /// - Parameter width: 目标宽度。
    /// - Returns: 缩放后的图片。
    func ba_resized(width: CGFloat) -> UIImage? {
        guard width > 0, size.width > 0 else { return nil }
        let ratio = width / size.width
        return ba_resized(to: CGSize(width: width, height: size.height * ratio))
    }

    /// 按目标高度等比缩放。
    ///
    /// - Parameter height: 目标高度。
    /// - Returns: 缩放后的图片。
    func ba_resized(height: CGFloat) -> UIImage? {
        guard height > 0, size.height > 0 else { return nil }
        let ratio = height / size.height
        return ba_resized(to: CGSize(width: size.width * ratio, height: height))
    }

    /// 居中裁剪为指定尺寸。
    ///
    /// - Parameter targetSize: 目标尺寸。
    /// - Returns: 裁剪后的图片。
    func ba_croppedCenter(to targetSize: CGSize) -> UIImage? {
        guard targetSize.width > 0, targetSize.height > 0 else { return nil }
        let scaleRatio = max(targetSize.width / size.width, targetSize.height / size.height)
        let drawSize = CGSize(width: size.width * scaleRatio, height: size.height * scaleRatio)
        let drawOrigin = CGPoint(x: (targetSize.width - drawSize.width) / 2, y: (targetSize.height - drawSize.height) / 2)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: drawOrigin, size: drawSize))
        }
    }

    /// 按指定 rect 裁剪图片。
    ///
    /// - Parameter rect: point 坐标系下的裁剪区域。
    /// - Returns: 裁剪后的图片。
    func ba_cropped(to rect: CGRect) -> UIImage? {
        let pixelRect = CGRect(x: rect.origin.x * scale,
                               y: rect.origin.y * scale,
                               width: rect.width * scale,
                               height: rect.height * scale)
        guard let cgImage = cgImage?.cropping(to: pixelRect) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 圆形头像裁剪。
    ///
    /// - Returns: 圆形图片，取原图短边居中裁剪。
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
            draw(in: drawRect)
        }
    }

    /// 添加圆角。
    ///
    /// - Parameters:
    ///   - radius: 圆角半径。
    ///   - corners: 圆角位置，默认全部。
    /// - Returns: 圆角图片。
    func ba_rounded(radius: CGFloat, corners: UIRectCorner = .allCorners) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
            path.addClip()
            draw(in: rect)
        }
    }

    // MARK: - Color / Effect

    /// 着色生成同形状的纯色图。
    ///
    /// - Parameter color: 目标颜色。
    /// - Returns: 着色后的图片。
    func ba_tinted(_ color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
            // destinationIn 只保留原图 alpha 区域，透明区域不会被填色。
            draw(in: CGRect(origin: .zero, size: size), blendMode: .destinationIn, alpha: 1)
        }
    }

    /// 添加半透明颜色蒙层。
    ///
    /// - Parameters:
    ///   - color: 蒙层颜色。
    ///   - alpha: 蒙层透明度。
    /// - Returns: 添加蒙层后的图片。
    func ba_overlay(color: UIColor, alpha: CGFloat = 0.35) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
            color.withAlphaComponent(alpha).setFill()
            UIRectFillUsingBlendMode(CGRect(origin: .zero, size: size), .sourceAtop)
        }
    }

    /// 高斯模糊图片。
    ///
    /// - Parameter radius: 模糊半径。
    /// - Returns: 模糊后的图片。
    func ba_blurred(radius: CGFloat) -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(radius, forKey: kCIInputRadiusKey)
        guard let output = filter?.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    /// 灰度图片。
    ///
    /// - Returns: 转换后的灰度图片。
    func ba_grayscale() -> UIImage? {
        guard let ciImage = CIImage(image: self) else { return nil }
        let filter = CIFilter(name: "CIPhotoEffectMono")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        guard let output = filter?.outputImage else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage, scale: scale, orientation: imageOrientation)
    }

    // MARK: - Rotate / Flip

    /// 旋转图片。
    ///
    /// - Parameter radians: 旋转弧度。
    /// - Returns: 旋转后的图片。
    func ba_rotated(radians: CGFloat) -> UIImage? {
        let rotatedRect = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral
        let targetSize = CGSize(width: abs(rotatedRect.width), height: abs(rotatedRect.height))
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { context in
            let cgContext = context.cgContext
            // 将坐标系移动到画布中心，保证旋转围绕图片中心发生。
            cgContext.translateBy(x: targetSize.width / 2, y: targetSize.height / 2)
            cgContext.rotate(by: radians)
            draw(in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
        }
    }

    /// 水平翻转图片。
    ///
    /// - Returns: 翻转后的图片。
    func ba_flippedHorizontal() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            // UIKit 绘制坐标从左上开始，先平移再负向缩放可实现镜像。
            cgContext.translateBy(x: size.width, y: 0)
            cgContext.scaleBy(x: -1, y: 1)
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    /// 垂直翻转图片。
    ///
    /// - Returns: 翻转后的图片。
    func ba_flippedVertical() -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: 0, y: size.height)
            cgContext.scaleBy(x: 1, y: -1)
            draw(in: CGRect(origin: .zero, size: size))
        }
    }

    // MARK: - Encode / Compress

    /// 按质量生成 JPEG 数据。
    ///
    /// - Parameter quality: 压缩质量，取值 0~1。
    /// - Returns: JPEG 数据。
    func ba_jpegData(quality: CGFloat) -> Data? {
        jpegData(compressionQuality: min(1, max(0, quality)))
    }

    /// 压缩到目标体积。
    ///
    /// - Parameters:
    ///   - targetKB: 目标体积，单位 KB。
    ///   - minQuality: 最低 JPEG 质量，默认 0.1。
    /// - Returns: 压缩后的 JPEG 数据。
    func ba_compressed(toKB targetKB: Int, minQuality: CGFloat = 0.1) -> Data? {
        guard targetKB > 0 else { return nil }
        var quality: CGFloat = 0.9
        guard var data = jpegData(compressionQuality: quality) else { return nil }
        let maxBytes = targetKB * 1024
        while data.count > maxBytes, quality > minQuality {
            quality = max(minQuality, quality - 0.1)
            guard let next = jpegData(compressionQuality: quality) else { break }
            data = next
        }
        return data
    }

    /// 转换为 Base64 字符串。
    ///
    /// - Parameter quality: JPEG 压缩质量；传 `nil` 时使用 PNG 编码。
    /// - Returns: Base64 字符串。
    func ba_base64String(jpegQuality quality: CGFloat? = nil) -> String? {
        let data: Data?
        if let quality {
            data = ba_jpegData(quality: quality)
        } else {
            data = pngData()
        }
        return data?.base64EncodedString()
    }
}
#endif
