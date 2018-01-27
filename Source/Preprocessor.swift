//
//  Processor.swift
//  Preprocessing
//
//  Created by GongXiang on 1/18/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import Vision

/// debugger 输出每一步的处理结果
public typealias Debugger = (CIImage) -> ()

/// 配置与处理器
public struct Configuration {
    
    public static var `default`: Configuration { return Configuration() }
    
    public var colorMonochromeFilterInputColor: CIColor? // CIColorMonochrome kCIInputColorKey 参数
    public var colorControls: (CGFloat, CGFloat, CGFloat) // CIColorControls Saturation, Brightness, Contrast
    public var exposureAdjustEV: CGFloat // CIExposureAdjust IInputEVKey
    
    public var gaussianBlurSigma: Double
    
    public var smoothThresholdFilter: (CGFloat, CGFloat)? // inputEdgeO, inputEdge1
    
    public var unsharpMask: (CGFloat, CGFloat) // Radius, Intensity
    
    init() {
        colorMonochromeFilterInputColor = CIColor(red: 0.75, green: 0.75, blue: 0.75)
        colorControls = (0.4, 0.2, 1.1)
        exposureAdjustEV = 0.7
        gaussianBlurSigma = 0.4
        smoothThresholdFilter = (0.35, 0.85)
        unsharpMask = (2.5, 0.5)
    }
}

/// 每一步的处理结果
public protocol Valueable {
    associatedtype T
    var value: T? { get }
}

public struct Value {
    public let image: CIImage
    public let bounds: CGRect
    
    public init (_ image: CIImage, _ bounds: CGRect) {
        self.image = image
        self.bounds = bounds
    }
}

public enum Result<T>: Valueable {
    case success(T)
    case failure(PreprocessError)
    
    public var value: T? {
        if case .success(let t) = self {
            return t
        }
        return nil
    }
    
    public func mapValue<U>(_ transform: (T) -> U) -> Result<U> {
        switch self {
        case .success(let t):
            return .success(transform(t))
        case .failure(let e):
            return .failure(e)
        }
    }
}

public typealias DivideResult = Result<[Value]>
public typealias CorpMaxRectangleResult = Result<Value>
public typealias FaceCorrectionResult = Result<Value>
public typealias ProcessedResult = Result<Value>
public typealias PerspectiveCorrectionResult = Result<Value>

// 处理器
public protocol Preprocessable { }
public extension Preprocessable {
    var preprocessor: Preprocessor<Self> {
        return Preprocessor(self)
    }
}

public struct Preprocessor<T> {
    let image: T
    init(_ image: T) {
        self.image = image
    }
}

extension CIImage: Preprocessable {}

@available(OSX 10.13, iOS 11.0, *)
extension CGImage: Preprocessable {
    public var preprocessor: Preprocessor<CIImage> {
        return CIImage(cgImage: self).preprocessor
    }
}

extension Value: Preprocessable {
    public var preprocessor: Preprocessor<CIImage> {
        return image.preprocessor
    }
}

public extension Valueable where T == Value {
    public func process(conf: Configuration = Configuration.`default`, debugger: Debugger? = nil) -> ProcessedResult {
        return value?.preprocessor.process(conf: conf, debugger: debugger) ?? .failure(.notFound)
    }
    
    public func divideText(result resize: CGSize? = nil, adjustment: Bool = false, debugger: Debugger? = nil) -> DivideResult {
        return value?.preprocessor.divideText(result: resize, adjustment: adjustment, debugger: debugger) ?? .failure(.notFound)
    }
    
    public func correctionByFace() -> FaceCorrectionResult {
        return value?.preprocessor.correctionByFace() ?? .failure(.notFound)
    }
}

@available(OSX 10.13, iOS 11.0, *)
public extension Preprocessor where T: CIImage {
    
    /// 返回处理后的CIImage对象
    ///
    /// - parameter image: 将要处理的CIImage对象，注意image的orientation
    /// - parameter configuration: 根据自己特定业务下的图片特点，可以调整相应的预处理参数
    /// - parameter debugger: 返回每一步的处理结果
    ///
    /// - returns: retrun processed iamge.
    ///
    public func process(conf: Configuration = Configuration.`default`, debugger: Debugger? = nil) -> ProcessedResult {
        
        var inputImage: CIImage = self.image
        
        // 只有在主动设置的时候才丢弃颜色信息
        if let color = conf.colorMonochromeFilterInputColor {
            // 0x00. 灰度图 --> 主要用来做文字识别所以直接去掉色彩信息
            inputImage = inputImage.applyingFilter("CIColorMonochrome", parameters: [kCIInputColorKey: color])
            debugger?(inputImage)
        }
        
        // 0x01. 提升亮度 --> 会损失一部分背景纹理 饱和度不能太高
        inputImage = inputImage.applyingFilter("CIColorControls", parameters: [
            kCIInputSaturationKey: conf.colorControls.0,
            kCIInputBrightnessKey: conf.colorControls.1,
            kCIInputContrastKey: conf.colorControls.2])
        debugger?(inputImage)
        
        // 0x02 曝光调节
        inputImage = inputImage.applyingFilter("CIExposureAdjust", parameters: [kCIInputEVKey: conf.exposureAdjustEV])
        debugger?(inputImage)
        
        // 0x03 高斯模糊
        inputImage = inputImage.applyingGaussianBlur(sigma: conf.gaussianBlurSigma)
        debugger?(inputImage)
        
        if let sf = conf.smoothThresholdFilter {
            // 0x04. 去燥
            inputImage = SmoothThresholdFilter(inputImage,
                                               inputEdgeO: sf.0,
                                               inputEdge1: sf.1).outputImage ?? inputImage
            debugger?(inputImage)
        }
        
        // 0x05 增强文字轮廓
        inputImage = inputImage.applyingFilter("CIUnsharpMask",
                                               parameters: [kCIInputRadiusKey: conf.unsharpMask.0, kCIInputIntensityKey: conf.unsharpMask.1])
        debugger?(inputImage)
        
        return .success(Value(inputImage, inputImage.extent))
    }
    
    /// 将一整个文字图片划分为单个的`字`
    ///
    /// - parameter result: resize分割后单个字的size
    /// - parameter adjustment: 是否对调整分割后的图片
    /// - parameter debugger: 返回每一步的处理结果
    ///
    /// - returns: 返回分割结果
    ///
    public func divideText(result resize: CGSize? = nil, adjustment: Bool = true, debugger: Debugger? = nil) -> DivideResult {
        
        let detectTextRequest = VNDetectTextRectanglesRequest()
        detectTextRequest.reportCharacterBoxes = true
        
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        try? handler.perform([detectTextRequest])
        
        guard let textObservations = detectTextRequest.results as? [VNTextObservation] else {
            return .failure(.notFound)
        }
        
        let ciImage = self.image
        var results = [Value]()
        
        for textObservation in textObservations {
            guard let cs = textObservation.characterBoxes else { continue }
            
            for c in cs {
                
                let rect = c.boundingBox.scaled(to: ciImage.extent.size)
                
                var image = ciImage.cropped(to: rect)
                    .transformed(by: CGAffineTransform(translationX: -rect.origin.x, y: -rect.origin.y))
                if let size = resize {
                    // 将文字切割出来 缩放到`size`
                    image = image.resize(size)
                }
                //                if adjustment {
                //                    image = SmoothThresholdFilter(image, inputEdgeO: 0.15, inputEdge1: 0.9).outputImage ?? image
                //                    debugger?(image)
                //                    image = AdaptiveThresholdFilter(image).outputImage ?? image
                //                    debugger?(image)
                //                }
                debugger?(image)
                results.append(Value(image, rect))
            }
        }
        
        return .success(results)
    }
    
    /// 将图片中最大的矩形切割出来
    ///
    ///
    public func croppedMaxRectangle() -> CorpMaxRectangleResult {
        
        let request = VNDetectRectanglesRequest()
        let handler = VNImageRequestHandler(ciImage: image, options: [:])
        
        do {
            try handler.perform([request])
        } catch (let error) {
            return .failure(.inline(error))
        }
        
        guard let observations = request.results as? [VNRectangleObservation] else {
            return .failure(.notFound)
        }
        
        guard let maxObservation = (observations.max(by: { (left, right) -> Bool in
            return left.boundingBox.area > right.boundingBox.area
        })) else {
            return .failure(.notFound)
        }
        
        return image.preprocessor.perspectiveCorrection(boundingBox: maxObservation.boundingBox,
                                                        topLeft: maxObservation.topLeft,
                                                        topRight: maxObservation.topRight,
                                                        bottomLeft: maxObservation.bottomLeft,
                                                        bottomRight: maxObservation.bottomRight)
    }
    
    /// 根据脸部信息矫正图片，确认脸部正面向上👆
    ///
    ///
    public func correctionByFace() -> FaceCorrectionResult {
        
        let detector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyLow])!
        
        var orientation: CGImagePropertyOrientation = image.extent.width > image.extent.height ? .up : .right
        
        var faceFeatures = detector.features(in: image, options: [CIDetectorImageOrientation: orientation.rawValue])
        
        if orientation == .right {
            let newFeatures = detector.features(in: image, options: [CIDetectorImageOrientation: CGImagePropertyOrientation.left.rawValue])
            if newFeatures.count != 0 {
                if faceFeatures.count == 0 {
                    faceFeatures = newFeatures
                    orientation = .left
                } else {
                    if faceFeatures.first!.bounds.height > newFeatures.first!.bounds.height {
                        faceFeatures = newFeatures
                        orientation = .left
                    }
                }
            }
        } else if orientation == .up && faceFeatures.count == 0 {
            orientation = .down
            faceFeatures = detector.features(in: image, options: [CIDetectorImageOrientation: orientation.rawValue])
        }
        
        guard var faceFeature = faceFeatures.first as? CIFaceFeature,
            faceFeature.hasLeftEyePosition &&
                faceFeature.hasRightEyePosition &&
                faceFeature.hasMouthPosition &&
                !faceFeature.leftEyeClosed &&
                !faceFeature.rightEyeClosed
            else {
                return .failure(.notFound)
        }
        
        if orientation == .up && faceFeature.bounds.height > image.extent.height * 0.4 {
            if let newF = detector.features(in: image, options: [CIDetectorImageOrientation: CGImagePropertyOrientation.down.rawValue]).first as? CIFaceFeature {
                orientation = .down
                faceFeature = newF
            }
        }
        
        let bounds = faceFeature.bounds.applying(image.orientationTransform(for: orientation))
        
        return .success(Value(image.oriented(orientation), bounds))
    }
    
    public func perspectiveCorrection(boundingBox box: CGRect, topLeft: CGPoint, topRight: CGPoint, bottomLeft: CGPoint, bottomRight: CGPoint) -> PerspectiveCorrectionResult {
        
        let size = image.extent.size
        let boundingBox = box.scaled(to: size)
        if image.extent.contains(boundingBox) {
            // Rectify the detected image and reduce it to inverted grayscale for applying model.
            let topLeft = topLeft.scaled(to: size)
            let topRight = topRight.scaled(to: size)
            let bottomLeft = bottomLeft.scaled(to: size)
            let bottomRight = bottomRight.scaled(to: size)
            let outputImage = image.cropped(to: boundingBox)
                .applyingFilter("CIPerspectiveCorrection", parameters: [
                    "inputTopLeft": CIVector(cgPoint: topLeft),
                    "inputTopRight": CIVector(cgPoint: topRight),
                    "inputBottomLeft": CIVector(cgPoint: bottomLeft),
                    "inputBottomRight": CIVector(cgPoint: bottomRight)
                    ])
            return .success(Value(outputImage, boundingBox))
        }
        return .failure(.notFound)
    }
}

