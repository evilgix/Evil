//
//  main.swift
//  Evil
//
//  Created by GongXiang on 1/19/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import Foundation

func launch(pyton currentDirectoryPath: String, arguments: [String]) -> String? {
    
    let outpipe = Pipe()
    let process = Process()
    process.launchPath = "/usr/bin/python"
    process.arguments = arguments
    process.currentDirectoryPath = currentDirectoryPath
    process.standardOutput = outpipe
    process.launch()
    process.waitUntilExit()
    let outdata = outpipe.fileHandleForReading.availableData
    return String(data: outdata, encoding: String.Encoding.utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
}

var workspace = FileManager.default.currentDirectoryPath
var scriptPath = "./scripts"
var generatorModuleName = "generator"
var labels = [String]()

var originalPath: String {
    return workspace + "/original"
}

var outputPath: String {
    return workspace + "/output"
}

for argument in CommandLine.arguments {
    let args = argument.split(separator: "=")
    if args.count == 2 {
        switch args[0] {
        case "workspace", "w":
            workspace = String(args[1])
        case "scriptPath", "sp":
            scriptPath = String(args[1])
        case "generatorModuleName", "gmn":
            generatorModuleName = String(args[1])
        default:
            debugPrint("invalid arg ==> \(argument)")
        }
    } else {
        debugPrint("useless arg ==> \(argument)")
    }
}

try? FileManager.default.createDirectory(atPath: originalPath, withIntermediateDirectories: true, attributes: nil)

let generator = "\(scriptPath)/\(generatorModuleName).py"

debugPrint("generator ==> \(generator)")
debugPrint("originalPath ==> \(originalPath)")
debugPrint("begin generator original images .....")

guard let generatorResult = launch(pyton: scriptPath, arguments: [generator, "-o", "\(originalPath)"]) else {
    debugPrint("generate original image failed")
    exit(EX_NOINPUT)
}

labels = generatorResult.map { String($0) }
debugPrint("generator original images succeed.")

debugPrint("labels ==> \(labels)")
debugPrint("begin divid original images.....")

do {
    try Divider.do(originalImagePath: originalPath, dividedImagePath: outputPath, labels: labels)
} catch (let error) {
    debugPrint(error)
    exit(EX_NOINPUT)
}

debugPrint("divid original image succeed")

debugPrint("divided image path ==> \(outputPath)")

debugPrint("训练数据准备就绪，使用下面的命令开始训练自己的模型")
debugPrint("python \(scriptPath)/trainer.py -i \(outputPath) -o \(workspace)/evil.mlmodel -l \(labels.joined())")
