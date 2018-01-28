//
//  AdaptiveThresholdFilter.swift
//  Preprocessing
//
//  Created by Gix on 1/18/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation
import CoreImage

@available(OSX 10.11, iOS 11.0, *)
public class AdaptiveThresholdFilter: CIFilter {
    
    var inputImage: CIImage?
    
    var thresholdKernel =  CIColorKernel(source:
        "kernel vec4 thresholdFilter(__sample image, __sample threshold)" +
            "{" +
            "   float imageLuma = dot(image.rgb, vec3(0.2126, 0.7152, 0.0722));" +
            "   float thresholdLuma = dot(threshold.rgb, vec3(0.2126, 0.7152, 0.0722));" +
            "   return vec4(vec3(step(thresholdLuma, imageLuma+0.001)), 1);" +
        "}"
    )
    
    override public var outputImage: CIImage? {
        guard let inputImage = inputImage, let thresholdKernel = thresholdKernel else {
            return nil
        }
        
        let extent = inputImage.extent
        let blurred = inputImage.applyingFilter("CIBoxBlur", parameters: [kCIInputRadiusKey: 5])
        let arguments: [Any] = [inputImage, blurred]
        return thresholdKernel.apply(extent: extent, arguments: arguments)
    }
    
    public convenience init(_ inputImage: CIImage?) {
        self.init()
        self.inputImage = inputImage
    }
}
