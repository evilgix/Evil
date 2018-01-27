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
    
    let model: MLModel
    let recognizer: Recognizer
    
    public init(recognizer: Recognizer, autoUpdate: Bool = true) throws {
        if autoUpdate {
            if let m = (try? MLModel(contentsOf: recognizer.modelcURL)) {
                model = m
            } else {
                try recognizer.dowloadAndUpdateModel()
                model = try MLModel(contentsOf: recognizer.modelcURL)
            }
        } else {
            model = try MLModel(contentsOf: recognizer.modelcURL)
        }
        self.recognizer = recognizer
    }
    
    public convenience init(contentsOf url: URL, name: String, processor: Processor? = nil) throws {
        try self.init(recognizer: Recognizer.custom(name: name, model: url, needComplie: false, processor: processor),
                      autoUpdate: false)
    }
}

public extension Evil {
    
    /// ocr 识别图片数组
    ///
    /// - parameter images: 将要识别的图片数组
    ///
    public func prediction(_ images: [CIImage]) throws -> [String?] {
        let coreModel = try VNCoreMLModel(for: model)
        let request = VNCoreMLRequest(model: coreModel)
        request.imageCropAndScaleOption = .centerCrop
         let handler = VNSequenceRequestHandler()
        let result = try images.flatMap {
            try handler.perform([request], on: $0)
            return (request.results?.first as? VNClassificationObservation)?.identifier
        }
        return result
    }
}
