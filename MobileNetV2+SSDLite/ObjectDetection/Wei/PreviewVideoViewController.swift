//
//  PreviewVideoViewController.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import UIKit
import Vision

class PreviewVideoViewController: ZWLogViewController & PreviewVideoViewModelDelegate {
    
    @IBOutlet var videoPreview: UIView!
    
    private lazy var boundingBoxViews = [BoundingBoxView]()
    
    private lazy var viewModel = PreviewVideoViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBoundingBoxViews()
        setUpViewModel()
    }
    
    private func setUpViewModel() {
        viewModel.delegate = self
        viewModel.genColors()
    }
    
    private func setUpBoundingBoxViews() {
        for _ in 0..<viewModel.maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        for box in self.boundingBoxViews {
            box.addToLayer(self.videoPreview.layer)
        }
    }
    
    func show(predictions: [VNRecognizedObjectObservation]) {
        for i in 0..<boundingBoxViews.count {
            if i < predictions.count {
                let prediction = predictions[i]
                
                /*
                 The predicted bounding box is in normalized image coordinates, with
                 the origin in the lower-left corner.
                 
                 Scale the bounding box to the coordinate system of the video preview,
                 which is as wide as the screen and has a 16:9 aspect ratio. The video
                 preview also may be letterboxed at the top and bottom.
                 
                 Based on code from https://github.com/Willjay90/AppleFaceDetection
                 
                 NOTE: If you use a different .imageCropAndScaleOption, or a different
                 video resolution, then you also need to change the math here!
                 */
                
                let width = view.bounds.width
                let height = width * 16 / 9
                let offsetY = (view.bounds.height - height) / 2
                let scale = CGAffineTransform.identity.scaledBy(x: width, y: height)
                let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -height - offsetY)
                let rect = prediction.boundingBox.applying(scale).applying(transform)
                
                // The labels array is a list of VNClassificationObservation objects,
                // with the highest scoring class first in the list.
                let bestClass = prediction.labels[0].identifier
                let confidence = prediction.labels[0].confidence
                
                // Show the bounding box.
                let label = String(format: "%@ %.1f", bestClass, confidence * 100)
                let color = viewModel.colors[bestClass] ?? UIColor.red
                boundingBoxViews[i].show(frame: rect, label: label, color: color)
            } else {
                boundingBoxViews[i].hide()
            }
        }
    }
}

#warning("Extract the video frame (CVPixelBuffer) from video file and using it for object detection inference[2]")
//extension PreviewVideoViewController: VideoCaptureDelegate {
//    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
//        viewModel.predict(sampleBuffer: sampleBuffer)
//    }
//}

#warning("Able to load a video file (.mp4 with person in content)")
//
