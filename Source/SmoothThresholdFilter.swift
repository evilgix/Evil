//
//  SmoothThresholdFilter.swift
//  Preprocessing
//
//  Created by GongXiang on 1/18/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import CoreImage

@available(OSX 10.11, iOS 11.0, *)
public class SmoothThresholdFilter: CIFilter {
    
    var inputImage : CIImage?
    
    var inputEdgeO: CGFloat = 0.35
    var inputEdge1: CGFloat = 0.85
    
    var colorKernel = CIColorKernel(source:
        "kernel vec4 color(__sample pixel, float inputEdgeO, float inputEdge1)" +
            "{" +
            "    float luma = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));" +
            "    float threshold = smoothstep(inputEdgeO, inputEdge1, luma);" +
            "    return vec4(threshold, threshold, threshold, 1.0);" +
        "}"
    )
    
    public override var outputImage: CIImage? {
        guard let inputImage = inputImage else { return nil }
        
        let extent = inputImage.extent
        let arguments: [Any] = [inputImage, inputEdgeO, inputEdge1]
        
        return colorKernel?.apply(extent: extent, arguments: arguments)
    }
    
    public convenience init(_ inputImage: CIImage, inputEdgeO: CGFloat = 0.35, inputEdge1: CGFloat = 0.85) {
        self.init()
        self.inputImage = inputImage
        self.inputEdge1 = inputEdge1
        self.inputEdgeO = inputEdgeO
    }
}
