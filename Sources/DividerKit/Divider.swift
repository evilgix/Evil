//
//  main.swift
//  Divider
//
//  Created by GongXiang on 1/19/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import CoreImage
import Metal
import Preprocessing

public struct Divider {
    
    public static func `do`(originalImagePath: String, dividedImagePath: String, labels: [String], divideSize: CGSize = CGSize(width: 227, height: 227)) throws {
        
        func imageURL(_ offset: Int) -> URL {
            return URL(fileURLWithPath: originalImagePath, isDirectory: true).appendingPathComponent("\(offset).png")
        }
        func singleImageURL(label: Int, idx: Int) -> URL {
            return URL(fileURLWithPath: dividedImagePath, isDirectory: true).appendingPathComponent("\(labels[label])/\(idx).jpeg")
        }
        
        let fileManager = FileManager.`default`
        
        guard let paths = fileManager.subpaths(atPath: originalImagePath), paths.count > 0 else {
            throw DividerError.originalImageSourceNotFound
        }
        
        if fileManager.fileExists(atPath: dividedImagePath) {
            try fileManager.removeItem(atPath: dividedImagePath)
        }
        
        try labels.forEach { label in
            try fileManager.createDirectory(atPath: "\(dividedImagePath)/\(label)", withIntermediateDirectories: true, attributes: nil)
        }
        
        let context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
        
        paths.enumerated().forEach { offset, _ in
            if let ciimage = CIImage(contentsOf: imageURL(offset)) {
                let processedImage = Processor.`do`(image: ciimage)
                let divideResult = Processor.divide(image: processedImage, size: divideSize, adaptiveThreshold: false)
                guard divideResult.count == labels.count else {
                    print("[warning] result invidate. offset: ==> \(offset)")
                    return;
                }
                
                let idx = offset
                divideResult.enumerated().forEach { offset, r in
                    let url = singleImageURL(label: offset, idx: idx)
                    do {
                        try context.writeJPEGRepresentation(of: r.0, to: url, colorSpace: CGColorSpaceCreateDeviceRGB(), options: [:])
                    } catch (let error) {
                        print("[warning] write jepg file failed. \(error.localizedDescription)")
                    }
                }
                print("[info] idx:\(idx) finished.")
            } else {
                print("[warning] can't load ciimage. url ==> %@", imageURL(offset))
            }
        }
        
        print("[info] done.")
    }
}
