//
//  ChineseIDCard.swift
//  ChineseIDCardOCR
//
//  Created by GongXiang on 1/25/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import CoreGraphics

@available(OSX 10.13, iOS 11.0, *)
public class ChineseIDCard {
    
    static let modelName = "ChineseIDCard.mlmodel"
    static let downloadURL = URL(string: "http://ou5pk1mdu.bkt.clouddn.com/ChineseIDCard.mlmodel")!
    
    let evil: Evil
    
    public init(_ autoUpateModel: Bool = true) throws {
        if let evil = try? Evil(model: ChineseIDCard.modelName) {
            self.evil = evil
        } else {
            try ChineseIDCard.updateModel()
            self.evil = try Evil(model: ChineseIDCard.modelName)
        }
    }
    
    public init(_ evil: Evil) {
        self.evil = evil
    }
    
    public static func updateModel(force: Bool = false) throws {
        try Evil.update(model: ChineseIDCard.modelName, source: ChineseIDCard.downloadURL, force: force)
    }
    
    public func recognize(_ object: Recognizable, placeholder: String = "?") -> String? {
        if let image = object.croppedMaxRetangle.correctionByFace().process().value?.image {
            // 截取 数字区
            // 按照真实比例截取，身份证号码区
            let x = image.extent.width * 0.33
            let w = image.extent.width * 0.63
            let h = image.extent.height * 0.25
            let rect = CGRect(x: x, y: 0, width: w, height: h)
            if let images = image.cropped(to: rect).preprocessor.divideText().value?.map({ $0.image }) {
                return try? evil.prediction(ciimages: images).map { $0 ?? placeholder }.joined()
            }
        }
        return nil
    }
}
