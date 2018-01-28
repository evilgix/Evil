//
//  AppKitExtensions.swift
//  Preprocessing
//
//  Created by Gix on 1/24/18.
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
#endif

