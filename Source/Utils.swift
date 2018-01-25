//
//  FoundationExtensions.swift
//  Preprocessing
//
//  Created by GongXiang on 1/24/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import CoreGraphics
import CoreVideo

public extension CGRect {
    public func scaled(to size: CGSize) -> CGRect {
        return CGRect(
            x: self.origin.x * size.width,
            y: self.origin.y * size.height,
            width: self.size.width * size.width,
            height: self.size.height * size.height
        )
    }
    
    public var area: CGFloat {
        return size.width * size.height
    }
}

public extension CGPoint {
    public func scaled(to size: CGSize) -> CGPoint {
        return CGPoint(x: self.x * size.width, y: self.y * size.height)
    }
}

public extension CGImage {
    
    public func pixelBuffer(_ colorspace: CGColorSpace = CGColorSpaceCreateDeviceRGB()) -> CVPixelBuffer? {
        var pb: CVPixelBuffer? = nil
        
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_OneComponent8, nil, &pb)
        guard let pixelBuffer = pb else { return nil }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue:0))
        
        let bitmapContext = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: colorspace, bitmapInfo: 0)!
        
        bitmapContext.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        return pixelBuffer
    }
}

#if os(iOS)
    import CoreImage
    import UIKit
    public func draw(retangle bounds: CGRect, on image: CIImage) -> CIImage? {
        
        guard let cgImage = CIContext().createCGImage(image, from: image.extent) else {
            return nil
        }
        
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.red.cgColor)
        context?.translateBy(x: 0, y: CGFloat(size.height))
        context?.scaleBy(x: 1, y: -1)
        context?.draw(cgImage, in: CGRect(origin: .zero, size: size))
        UIColor.red.setFill()
        context?.stroke(bounds, width: 3.5)
        let drawnImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return drawnImage.map { CIImage(image: $0)! }
    }
#endif
