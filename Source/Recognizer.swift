//
//  Recognizer.swift
//  Evil iOS
//
//  Created by GongXiang on 1/26/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import CoreGraphics
import CoreImage
import CoreML

/// 那些类型可以识别
public protocol Recognizable {
    var croppedMaxRetangle: CorpMaxRetangleResult { get }
}

extension CIImage: Recognizable {
    public var croppedMaxRetangle: CorpMaxRetangleResult {
        return preprocessor.croppedMaxRetangle()
    }
}

extension CGImage: Recognizable {
    public var croppedMaxRetangle: CorpMaxRetangleResult {
        return preprocessor.croppedMaxRetangle()
    }
}

public typealias Processor = (Recognizable) -> CIImage?

public enum Recognizer {
    
    case chineseIDCard
    case custom(name: String, model: URL, needComplie: Bool, processor: Processor?) // local complied model url
    
    static var modelBaseURL: URL = {
       let info = Bundle.main.infoDictionary
        guard let baseURL = info?["EvilModelBaseURL"] as? String else {
            fatalError("please set `EvilModelBaseURL` in `info.plist`")
        }
        return URL(string: baseURL)!
    }()
    
    static let documentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as URL
    static let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0] as URL
    
    var needComplie: Bool {
        if case .custom(_, _, let needComplie, _) = self {
            return needComplie
        }
        return true
    }
    
    var name: String {
        switch self {
        case .chineseIDCard:
            return "ChineseIDCard"
        case .custom(let name, _, _, _):
            return name
        }
    }
    
    // 未编译的model 下载地址
    var modelURL: URL? {
        if case .custom(_, let url, let needComplie, _) = self {
            return needComplie ? url : nil
        }
        return Recognizer.modelBaseURL.appendingPathComponent("\(name).mlmodel")
    }
    
    // 已经编译好的model 可以直接使用
    var modelcURL: URL {
        if case .custom(_, let url, let needComplie, _) = self, !needComplie {
            return url
        }
        return Recognizer.documentURL.appendingPathComponent("evil/\(name).mlmodelc")
    }
    
    var existModel: Bool {
        return (try? MLModel(contentsOf: modelcURL)) != nil
    }
    
    var processor: Processor? {
        switch self {
        case .chineseIDCard:
            return cropChineseIDCardNumberArea
        case .custom(_, _, _, let processor):
            return processor
        }
    }
    
    // 处理身份证相关
    func cropChineseIDCardNumberArea(_ object: Recognizable) -> CIImage? {
        if let image = object.croppedMaxRetangle.correctionByFace().process().value?.image {
            // 截取 数字区
            // 按照真实比例截取，身份证号码区
            let x = image.extent.width * 0.33
            let y = image.extent.height * 0
            let w = image.extent.width * 0.63
            let h = image.extent.height * 0.25
            let rect = CGRect(x: x, y: y, width: w, height: h)
            return image.cropped(to: rect)
        }
        return nil
    }
    
    ///   从默认的地址下载深度学习模型，并更新
    ///
    /// - parameter force: 若本地存在模型文件，是否强制更新
    ///
    public func dowloadAndUpdateModel(force: Bool = false) throws {
        guard needComplie else { return }
        guard !existModel || !force else {
            return
        }
        guard let url = modelURL else {
            fatalError("no model download url for: \(self)")
        }
        let data = try Data(contentsOf: url)
        let cachedModel = Recognizer.cacheURL.appendingPathComponent(name)
        try data.write(to: cachedModel)
        try update(model: cachedModel)
        try FileManager.default.removeItem(at: cachedModel) // remove cache file
    }
    
    /// 用指定的文件更新本地深度学习模型
    ///
    /// - parameter source: 新的, 未编译的模型文件地址
    ///
    public func update(model source: URL) throws {
        let comiledURL = try MLModel.compileModel(at: source)

        try? FileManager.default.removeItem(at: modelcURL) // if exits remove it.
        let path = modelcURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        try FileManager.default.moveItem(at: comiledURL, to: modelcURL)
        
        debugPrint("[Recognizer] model \(name) compile succeed")
    }
}

extension Evil {
    
    public func recognize(_ object: Recognizable, placeholder: String = "?") -> String? {
        if let images = recognizer.processor?(object)?.preprocessor.divideText().value?.map({ $0.image }) {
            return try? prediction(ciimages: images).map { $0 ?? placeholder }.joined()
        }
        return nil
    }
}
