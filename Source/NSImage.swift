//
//  AppKitExtensions.swift
//  Preprocessing
//
//  Created by GongXiang on 1/24/18.
//  Copyright © 2018 Gix. All rights reserved.
//

#if os(macOS)
import AppKit

    public extension CIImage {
        public convenience init?(image: NSImage) {
            guard let tiffData = image.tiffRepresentation else { return nil }
            self.init(data: tiffData)
        }
    }
    
    public extension NSImage {
        public var cgImage: CGImage? {
            var rect = CGRect(origin: CGPoint.zero, size: size)
            return cgImage(forProposedRect: &rect, context: nil, hints: nil)
        }
    }
    
    extension NSImage: Preprocessable {}
    
    @available(OSX 10.13, *)
    public extension Preprocessor where T: NSImage {
        
        public func process(conf: Configuration = Configuration.`default`, debugger: Debugger? = nil) -> ProcessedResult {
            guard let ciImage = CIImage(image: image) else {
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
            guard let ciImage = CIImage(image: image) else {
                return .failure(.abort("can't get ciImage"))
            }
            return ciImage.preprocessor.correctionByFace()
        }
    }
    
    extension NSImage: Recognizable {
        public var croppedMaxRetangle: CorpMaxRetangleResult {
            return preprocessor.croppedMaxRetangle()
        }
    }
#endif

