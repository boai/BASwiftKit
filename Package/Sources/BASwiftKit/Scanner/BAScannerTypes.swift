//
//  BAScannerTypes.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import AVFoundation
import Foundation

/// 扫码支持的码类型。
///
/// 默认提供移动端常见的一维码、二维码类型。业务可按需选择，类型越少识别越聚焦。
public enum BAScanCodeType: CaseIterable {
    /// QR Code，常用于链接、文本、业务码。
    case qr
    /// EAN-13 商品条码。
    case ean13
    /// EAN-8 商品条码。
    case ean8
    /// Code 128 条码，常用于物流、资产标签。
    case code128
    /// Code 39 条码。
    case code39
    /// PDF417 二维条码。
    case pdf417
    /// Aztec 二维码。
    case aztec
    /// Data Matrix 二维码。
    case dataMatrix

    public var metadataObjectType: AVMetadataObject.ObjectType {
        switch self {
        case .qr: return .qr
        case .ean13: return .ean13
        case .ean8: return .ean8
        case .code128: return .code128
        case .code39: return .code39
        case .pdf417: return .pdf417
        case .aztec: return .aztec
        case .dataMatrix: return .dataMatrix
        }
    }

    static func makeMetadataObjectTypes(_ types: [BAScanCodeType]) -> [AVMetadataObject.ObjectType] {
        types.map(\.metadataObjectType)
    }
}

/// 扫码配置。
public struct BAScannerConfiguration {
    /// 需要识别的码类型。
    public var codeTypes: [BAScanCodeType]
    /// 是否连续识别。`false` 时识别到第一个结果后会自动停止扫码。
    public var isContinuous: Bool
    /// 相机画面填充方式，默认铺满预览区域。
    public var videoGravity: AVLayerVideoGravity

    /// 创建扫码配置。
    ///
    /// - Parameters:
    ///   - codeTypes: 需要识别的码类型，默认支持常见二维码和条码。
    ///   - isContinuous: 是否连续识别，默认识别一次后停止。
    ///   - videoGravity: 预览层填充方式。
    public init(codeTypes: [BAScanCodeType] = BAScanCodeType.allCases,
                isContinuous: Bool = false,
                videoGravity: AVLayerVideoGravity = .resizeAspectFill) {
        self.codeTypes = codeTypes
        self.isContinuous = isContinuous
        self.videoGravity = videoGravity
    }
}

/// 扫码结果。
public struct BAScannerResult: Equatable {
    /// 码内容字符串。
    public let value: String
    /// 系统返回的码类型。
    public let metadataObjectType: AVMetadataObject.ObjectType

    /// 创建扫码结果。
    ///
    /// - Parameters:
    ///   - value: 识别到的字符串内容。
    ///   - metadataObjectType: 系统识别出的码类型。
    public init(value: String, metadataObjectType: AVMetadataObject.ObjectType) {
        self.value = value
        self.metadataObjectType = metadataObjectType
    }
}

/// 扫码错误。
public enum BAScannerError: Error, Equatable {
    /// 当前设备没有可用后置摄像头。
    case cameraUnavailable
    /// 相机权限被拒绝或受限制。
    case cameraUnauthorized
    /// 摄像头输入无法加入采集会话。
    case cannotAddInput
    /// 元数据输出无法加入采集会话。
    case cannotAddOutput
    /// 当前设备不支持传入的扫码类型。
    case unsupportedCodeTypes
    /// 手电筒不可用。
    case torchUnavailable
    /// 手电筒被其他会话锁定，暂时无法操作。
    case torchLocked
}
#endif
