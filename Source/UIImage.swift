//
//  UIKitExtensions.swift
//  Preprocessing
//
//  Created by GongXiang on 1/24/18.
//  Copyright © 2018 Gix. All rights reserved.
//

#if os(iOS)
import UIKit
    
    public extension UIImageOrientation {
        var cgImagePropertyOrientation: CGImagePropertyOrientation {
            switch self {
            case .down:
                return .down
            case .up:
                return .up
            case .downMirrored:
                return .downMirrored
            case .upMirrored:
                return .upMirrored
            case .left:
                return .left
            case .right:
                return .right
            case .leftMirrored:
                return .leftMirrored
            case .rightMirrored:
                return .rightMirrored
            }
        }
    }
    
    public extension UIImage {
        /**
         Creates a new UIImage from a CVPixelBuffer, using Core Image.
         */
        public convenience init?(pixelBuffer: CVPixelBuffer, context: CIContext) {
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
            let rect = CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer),
                              height: CVPixelBufferGetHeight(pixelBuffer))
            if let cgImage = context.createCGImage(ciImage, from: rect) {
                self.init(cgImage: cgImage)
            } else {
                return nil
            }
        }
        
    }
    
    extension UIImage: Preprocessable {}
    
    @available(iOS 11.0, *)
    public extension Preprocessor where T: UIImage {
        
        public var ciImage: CIImage? {
            return CIImage(image: image)?.oriented(image.imageOrientation.cgImagePropertyOrientation)
        }
        
        public func process(conf: Configuration = Configuration.`default`, debugger: Debugger? = nil) -> ProcessedResult {
            guard let ciImage = ciImage else {
                return .failure(.abort("can't get ciImage"))
            }
            return ciImage.preprocessor.process(conf: conf, debugger: debugger)
        }
        
        public func divideText(result resize: CGSize? = nil, adjustment: Bool = false, debugger: Debugger? = nil) -> DivideResult {
            guard let cgImage = image.cgImage else {
                return .failure(.abort("can't get cgimage"))
            }
            return cgImage.preprocessor.divideText(result: resize, adjustment: adjustment, debugger: debugger)
        }
        
        public func croppedMaxRetangle() -> CorpMaxRetangleResult {
            guard let cgImage = image.cgImage else {
                return .failure(.abort("can't get cgimage"))
            }
            return cgImage.preprocessor.croppedMaxRetangle()
        }
        
        public func correctionByFace() -> FaceCorrectionResult {
            guard let ciImage = ciImage else {
                return .failure(.abort("can't get ciImage"))
            }
            return ciImage.preprocessor.correctionByFace()
        }
    }
    
    extension UIImage: Recognizable {
        public var croppedMaxRetangle: CorpMaxRetangleResult {
            return preprocessor.croppedMaxRetangle()
        }
    }
        
#endif

