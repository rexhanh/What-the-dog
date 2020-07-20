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
    
    var imagePicker: UIImagePickerController!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupImagepicker()
        setuplabel()
        setupgestures()
    }
    
    
    private func setupgestures() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swiperight))
        right.direction = .right
        self.view.addGestureRecognizer(right)
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeleft))
        left.direction = .left
        self.view.addGestureRecognizer(left)
    }
    
    @objc func swiperight(sender: UISwipeGestureRecognizer) {
        if self.modelSegment.selectedSegmentIndex == 0 {
            self.modelSegment.selectedSegmentIndex += 1
        }
    }
    @objc func swipeleft(sender: UISwipeGestureRecognizer) {
        if self.modelSegment.selectedSegmentIndex == 1 {
            self.modelSegment.selectedSegmentIndex -= 1
        }
    }
    private func setupImagepicker() {
        self.imagePicker = UIImagePickerController()
        self.imagePicker.delegate = self
        self.imagePicker.sourceType = .photoLibrary
    }
    
    
    private func setuplabel() {
        classifyLabel.font = UIFont(name: "Chalkboard SE", size: 20)!
        classifyLabel.textAlignment = .center
        classifyLabel.numberOfLines = 0
        classifyLabel.text = ""
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dogmodel = DogClassifier()
        catmodel = CatClassifier()
    }

    @IBAction func addimage(_ sender: UIBarButtonItem) {
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = sender
            popover.sourceView = self.view
            popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {action in
            self.present(self.imagePicker, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: {action in
            if !UIImagePickerController.isSourceTypeAvailable(.camera) {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.imagePicker.sourceType = .camera
            self.present(self.imagePicker, animated: true)
        }))
        self.present(alert, animated: true)
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
        let segmentindex = self.modelSegment.selectedSegmentIndex
        if segmentindex == 0 {
            guard let prediction = try? dogmodel.prediction(image: pixelBuffer!) else{return}
            let topprediction = prediction.classLabel
            let toppredictionConf = prediction.classLabelProbs[topprediction] ?? 2
            var predictionStr = ""
            if toppredictionConf <= 0.95 {
                predictionStr.append("Not sure what dog he/she is. \n The highest chance he/she is a \(topprediction) dog with confidence \(Int(toppredictionConf * 100)) %.\n")
                for (key, value) in prediction.classLabelProbs {
                    if key != topprediction && value >= 0.2{
                        predictionStr.append("It might also be a \(key) dog with confidence of \(Int(value * 100))%.\n")
                    }
                }
            } else {
                predictionStr.append("I am \(Int(toppredictionConf * 100)) percent sure it is a \(topprediction) dog!")
            }
            self.classifyLabel.text = predictionStr
        } else if segmentindex == 1{
            guard let prediction = try? catmodel.prediction(image: pixelBuffer!) else{return}
            let topprediction = prediction.classLabel
            let toppredictionConf = prediction.classLabelProbs[topprediction] ?? 2
            var predictionStr = ""
            if toppredictionConf <= 0.95 {
                predictionStr.append("Not sure what cat he/she is. \n The highest chance he/she is a \(topprediction) cat with confidence \(Int(toppredictionConf * 100)) %.\n")
                for (key, value) in prediction.classLabelProbs {
                    if key != topprediction && value >= 0.2{
                        predictionStr.append("It might also be a \(key) cat with confidence of \(Int(value * 100))%.\n")
                    }
                }
            } else {
                predictionStr.append("I am \(Int(toppredictionConf * 100)) percent sure it is a \(topprediction) cat!")
            }
            self.classifyLabel.text = predictionStr
        }
        self.imageView.image = newImage
        dismiss(animated: true, completion: nil)
    }
}




