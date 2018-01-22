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
import DividerKit

// WARNING: replace with your owner `LABELS`
//let labels = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "X"]
// WARNING: modify this to your source root
//var imageRoot = "/Users/Kevin/develop/evil/ChineseIDCardTrainingDataGenerator"

var imageRoot = FileManager.default.currentDirectoryPath
var labels = [String]()

var size = CGSize(width: 227, height: 227)

for argument in CommandLine.arguments {
    let args = argument.split(separator: "=")
    if args.count == 2 {
        switch args[0] {
        case "labels", "l":
            labels = args[1].split(separator: ",").map { String($0) }
        case "imageRoot", "root", "r":
            imageRoot = String(args[1])
        case "divideWidth", "dw":
            if let n = NumberFormatter().number(from: String(args[1])) {
                size.width = CGFloat(truncating: n)
            }
        case "divideHeight", "dh":
            if let n = NumberFormatter().number(from: String(args[1])) {
                size.height = CGFloat(truncating: n)
            }
        default:
            debugPrint("invalid arg ==> \(argument)")
        }
    } else {
        debugPrint("useless arg ==> \(argument)")
    }
}

if labels.count == 0 {
    debugPrint("please set labels")
    exit(EX_NOINPUT)
}

let numberAreaImagesPath = imageRoot + "/original"
let outputPath = imageRoot + "/divided"

do {
    try Divider.do(originalImagePath: numberAreaImagesPath, dividedImagePath: outputPath, labels: labels, divideSize: size)
} catch (let error) {
    debugPrint(error.localizedDescription)
}
