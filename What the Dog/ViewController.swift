//
//  ViewController.swift
//  What the Dog
//
//  Created by Yuanrong Han on 7/15/20.
//  Copyright © 2020 Yuanrong Han. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate {

    @IBOutlet weak var modelSegment: UISegmentedControl!
    
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var classifyLabel: UILabel!
    
    var dogmodel: DogClassifier!
    var catmodel: CatClassifier!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        classifyLabel.textAlignment = .center
        classifyLabel.text = ""
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dogmodel = DogClassifier()
        catmodel = CatClassifier()
    }
    @IBAction func camera(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera) {
            return
        }
        
        let cameraPicker = UIImagePickerController()
        cameraPicker.delegate = self
        cameraPicker.sourceType = .camera
        cameraPicker.allowsEditing = false
        
        present(cameraPicker, animated: true)
    }
    
    @IBAction func library(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerOriginalImage")] as? UIImage else {
            return
        }
        print("image width \(image.size.width), height \(image.size.height)")
        UIGraphicsBeginImageContextWithOptions(CGSize(width: image.size.width, height: image.size.height), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        switch modelSegment.selectedSegmentIndex {
        case 0:
            guard let prediction = try? dogmodel.prediction(image: pixelBuffer!) else {
                return
            }
            classifyLabel.text = "I think this is a \(prediction.classLabel) dog with\n \(Int((prediction.classLabelProbs[prediction.classLabel] ?? 0) * 100)) % confidence."
        case 1:
            guard let prediction = try? catmodel.prediction(image: pixelBuffer!) else {
                return
            }
            classifyLabel.text = "I think this is a \(prediction.classLabel) cat with\n \(Int((prediction.classLabelProbs[prediction.classLabel] ?? 0) * 100)) % confidence."
        default:
            guard let prediction = try? dogmodel.prediction(image: pixelBuffer!) else {
                return
            }
            classifyLabel.text = "I think this is a \(prediction.classLabel) dog with\n \(Int((prediction.classLabelProbs[prediction.classLabel] ?? 0) * 100)) % confidence."
        }
        self.imageView.image = newImage
        dismiss(animated: true, completion: nil)
    }
    
    
}
