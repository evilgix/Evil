//
//  Evil.swift
//  Evil
//
//  Created by GongXiang on 1/20/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Vision
import CoreML

@available(OSX 10.13, iOS 11.0, *)
public class Evil {
    
    private static let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
    private static let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0] as URL
    
    let model: MLModel
    
    static func modelURL(name: String) -> URL {
        return documentURL.appendingPathComponent("evil/\(name)")
    }
    
    public init(contentsOf url: URL) throws {
        model = try MLModel(contentsOf: url)
    }
    
    public convenience init(model name: String) throws {
        try self.init(contentsOf: Evil.modelURL(name: name))
    }
    
    public static func hasModel(name: String) -> Bool {
        return (try? Evil(model: name)) != nil
    }
}

// Download
public extension Evil {
    
    /// 更新本地默认的模型文件
    ///
    /// - parameter source: 模型文件地址
    /// - parameter force: 是否强制更新，默认为false
    ///
    public static func update(model name: String, source: URL, force: Bool = false) throws {
        if !force && Evil.hasModel(name: name) {
            return
        }
        let data = try Data(contentsOf: source)
        let cachedModel = Evil.cacheURL.appendingPathComponent(name)
        try data.write(to: cachedModel)
        try compile(model: name, source: cachedModel)
        try FileManager.default.removeItem(at: cachedModel) // remove cache file
    }
}

// Compile
public extension Evil {
    
    /// 编译本地默认的模型文件
    ///
    /// - parameter source: 模型文件地址
    ///
    public static func compile(model name: String,  source: URL) throws {
        let comiledURL = try MLModel.compileModel(at: source)
        let modelURL = Evil.modelURL(name: name)
        
        try? FileManager.default.removeItem(at: modelURL) // if exits remove it.
        let path = modelURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: comiledURL, to: Evil.modelURL(name: name))
        
        debugPrint("[Evil] model \(name) compile succeed")
    }
}

public extension Evil {
    
    static func convert(images: [CIImage]) -> [CGImage] {
        var context: CIContext
        if let device = MTLCreateSystemDefaultDevice() {
            context = CIContext(mtlDevice: device)
        } else {
            context = CIContext()
        }
        return images.flatMap { context.createCGImage($0, from: $0.extent) }
    }
    
    /// ocr 识别图片数组
    ///
    /// - parameter ciimages: 将要识别的图片数组
    ///
    public func prediction(ciimages: [CIImage]) throws -> [String?] {
        return try prediction(images: Evil.convert(images: ciimages))
    }
    
    /// ocr 识别图片数组
    ///
    /// - parameter images: 将要识别的图片数组
    ///
    public func prediction(images: [CGImage]) throws -> [String?] {
        let coreModel = try VNCoreMLModel(for: model)
        let request = VNCoreMLRequest(model: coreModel)
        request.imageCropAndScaleOption = .centerCrop
        
        let result = try images.flatMap {
            let handler = VNImageRequestHandler(cgImage: $0, options: [:])
            try handler.perform([request])
            return (request.results?.first as? VNClassificationObservation)?.identifier
        }
        return result
    }
}
