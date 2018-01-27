//
//  DebugViewController.swift
//  iOS Example
//
//  Created by GongXiang on 1/27/18.
//  Copyright © 2018 Gix. All rights reserved.
//

import UIKit
import Evil

class DebugViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var images = [UIImage]()
    
    lazy var evil = try! Evil(recognizer: .chineseIDCard)
    lazy var context = CIContext(mtlDevice: MTLCreateSystemDefaultDevice()!)
    
    var size = CGSize.zero
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        size = self.collectionView.frame.size.applying(CGAffineTransform(scaleX: 0.8, y: 0.8))
    }
    
    @IBAction func touchClose(sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchChoose(sender: UIBarButtonItem) {
        let vc = UIImagePickerController()
        vc.delegate = self
        self.show(vc, sender: nil)
    }
    
    func insertImage(_ image: CIImage) {
        DispatchQueue.global().async {
            let image = image.resize(self.size)
            if let cgImage = self.context.createCGImage(image, from: image.extent) {
                self.images.append(UIImage(cgImage: cgImage))
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
        }
    }
}

extension DebugViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        images.removeAll()
        collectionView.reloadData()
        
        DispatchQueue.global().async {
            
            guard let uiImage = info[UIImagePickerControllerOriginalImage] as? UIImage
                else { fatalError("no image from picker") }
            
            guard var image = uiImage.preprocessor.ciImage else {
                fatalError("can't convert to ciimage")
            }
            
            self.self.insertImage(image)
            
            // find max rectangle
            guard let value = image.preprocessor.croppedMaxRectangle().value else {
                debugPrint("find max rectangle failed")
                return
            }
            
            if let debug = draw(retangle: value.bounds, on: image) {
                self.insertImage(debug)
            }
            self.insertImage(value.image)
            
            let maxRectange = value.image
            
            // correction by face
            guard let faceValue = maxRectange.preprocessor.correctionByFace().value else {
                debugPrint("corretion by face failed")
                return
            }
            
            if let debug = draw(retangle: faceValue.bounds, on: faceValue.image) {
                self.insertImage(debug)
            }
            
            let numberValue = faceValue.image.cropChineseIDCardNumberArea()
            if let image = draw(retangle: numberValue.bounds, on: faceValue.image) {
                self.insertImage(image)
            }
            self.insertImage(numberValue.image)
            
            let processed = numberValue.image.preprocessor.process() {
                self.insertImage($0)
            }.value?.image
            guard let p = processed else {
                debugPrint("process failed.")
                return
            }
            image = p
            self.insertImage(p)
            
            let values = image.preprocessor.divideText {
                self.insertImage($0)
                }
            guard let images = values.value?.map({$0.image}) else {
                debugPrint("divide failed")
                return
            }
            do {
                let r = try self.evil.prediction(images)
                debugPrint(r)
            } catch {
                debugPrint(error)
            }
        }
    }
}

extension DebugViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return images[indexPath.item].size
    }
    
}

extension DebugViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! PreviewImageCollectionViewCell
        cell.previewImageView.image = images[indexPath.item]
        cell.layer.borderColor = UIColor.red.cgColor
        cell.layer.borderWidth = 2
        return cell
    }
}

class PreviewImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewImageView: UIImageView!
    
    override func prepareForReuse() {
        previewImageView.image = nil
    }
}

