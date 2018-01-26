//
//  ViewController.swift
//  iOS Example
//
//  Created by GongXiang on 1/25/18.
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

class TagLayer: CALayer {
    public convenience init(frame: CGRect) {
        self.init()
        self.frame = frame
        self.borderColor = UIColor.red.withAlphaComponent(0.4).cgColor
        self.borderWidth = 1
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var tipLabel: UILabel!
    @IBOutlet weak var previewView: PreviewView!
    
    lazy var recognizer = ChineseIDCardRecognizer.`default`
    lazy var session = AVCaptureSession()
    lazy var rectangleRequest: VNDetectRectanglesRequest = {
       let request =  VNDetectRectanglesRequest()
        request.maximumObservations = 1
        return request
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            session.stopRunning()
            sender.title = "Scan IDCard"
        } else {
            session.startRunning()
            sender.title = "Stop Scan"
        }
        
    }
    
    private func setupPreView() {
        //1
        session.sessionPreset = .high
        let captureDevice = AVCaptureDevice.default(for: .video)
        
        //2
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
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
        
        do {
            try imageRequestHandler.perform([rectangleRequest])
        } catch {
            fatalError(error.localizedDescription)
        }
        
        guard let observation = rectangleRequest.results?.first as? VNRectangleObservation else { return }
        
        DispatchQueue.main.async {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            self.previewView.layer.sublayers?.filter { $0 is CAShapeLayer }.forEach { $0.removeFromSuperlayer() }
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
            layer.lineWidth = 2.0
            layer.opacity = 1.0
            layer.fillColor = nil
            layer.strokeColor = UIColor.red.cgColor
            self.previewView.layer.addSublayer(layer)
            CATransaction.commit()
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
            let cardNumber = self.recognizer?.do(image)
            DispatchQueue.main.async {
                self.tipLabel.text = cardNumber ?? "recognize failed."
            }
        }
    }
}
