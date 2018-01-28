//
//  ViewController.swift
//  iOS Example
//
//  Created by Gix on 1/25/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import UIKit
import Evil
import Vision
import AVFoundation

class PreviewView: UIView {
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    var session: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        }
        set {
            videoPreviewLayer.session = newValue
        }
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var scanItem: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    
    var evil = try? Evil(recognizer: .chineseIDCard)
    lazy var context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    lazy var session = AVCaptureSession()
    lazy var rectangleRequest: VNDetectRectanglesRequest = {
        let request =  VNDetectRectanglesRequest()
        request.maximumObservations = 1
        return request
    }()
    
    lazy var operationQueue = OperationQueue()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        operationQueue.maxConcurrentOperationCount = 5
        operationQueue.qualityOfService = .utility
    }
    
    @IBAction func chooseImage(sender: UIBarButtonItem) {
        let vc = UIImagePickerController()
        vc.delegate = self
        show(vc, sender: nil)
    }
    
    @IBAction func scanIDCard(sender: UIBarButtonItem) {
        if previewView.session == nil {
            setupPreView()
        }
        
        if session.isRunning {
            stopScan()
        } else {
            session.startRunning()
            sender.title = "Stop Scan"
        }
    }
    
    private func stopScan() {
        session.stopRunning()
        scanItem.title = "Scan IDCard"
    }
    
    private func setupPreView() {
        //1
        session.sessionPreset = .high
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInteractive))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        previewView.videoPreviewLayer.videoGravity = .resize
        previewView.session = session
    }
}

extension UIDeviceOrientation {
    
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch self {
        case .portrait:
            return .rightMirrored
        case .portraitUpsideDown:
            return .leftMirrored
        case .landscapeLeft:
            return .upMirrored
        case .landscapeRight:
            return .downMirrored
        default:
            return .rightMirrored
        }
    }
}
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions = [VNImageOption: Any]()
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics: camData]
        }
        
        let orientation = UIDevice.current.orientation.cgImagePropertyOrientation
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: requestOptions)
        
        try? imageRequestHandler.perform([rectangleRequest])
        
        guard let observation = rectangleRequest.results?.first as? VNRectangleObservation else { return }
        
        let op = BlockOperation { [weak self] in
            guard let `self` = self else { return }
            let ciimage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)
            if let numbers = ciimage.preprocessor
                .perspectiveCorrection(boundingBox: observation.boundingBox,
                                       topLeft: observation.topLeft,
                                       topRight: observation.topRight,
                                       bottomLeft: observation.bottomLeft,
                                       bottomRight: observation.bottomRight)
                .mapValue({Value($0.image.oriented(orientation), $0.bounds)})
                .correctionByFace()
                .cropChineseIDCardNumberArea()
                .process()
                .divideText()
                .value?.map({ $0.image }), numbers.count == 18 {
                if let result = try? self.evil?.prediction(numbers) {
                    if let cardnumber = result?.flatMap({ $0 }).joined() {
                        self.operationQueue.cancelAllOperations()
                        DispatchQueue.main.async {
                            self.stopScan()
                            self.tipLabel.text = cardnumber
                        }
                    }
                }
            }
        }
        op.queuePriority = .veryHigh
        operationQueue.addOperation(op)
        
        DispatchQueue.main.async {
            let layer = CAShapeLayer()
            layer.frame = self.previewView.layer.frame
            let size = self.previewView.frame.size
            let path = UIBezierPath()
            path.move(to: observation.topLeft.scaled(to: size))
            path.addLine(to: observation.bottomLeft.scaled(to: size))
            path.addLine(to: observation.bottomRight.scaled(to: size))
            path.addLine(to: observation.topRight.scaled(to: size))
            path.addLine(to: observation.topLeft.scaled(to: size))
            layer.path = path.cgPath
            layer.opacity = 1.0
            layer.fillColor = UIColor.red.withAlphaComponent(0.4).cgColor
            self.previewView.layer.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }
            self.previewView.layer.addSublayer(layer)
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            else { fatalError("no image from picker") }
        
        tipLabel.text = "recoginzing..."
        DispatchQueue.global(qos: .utility).async {
            let cardNumber = self.evil?.recognize(image)
            DispatchQueue.main.async {
                self.tipLabel.text = cardNumber ?? "recognize failed."
            }
        }
    }
}

