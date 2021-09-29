//
//  LiveVideoViewController.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import CoreMedia
import CoreML
import UIKit
import Vision

class LiveVideoViewController: ZWLogViewController {
    
    // MARK: Properties
    
    @IBOutlet var videoPreview: UIView!
    private lazy var boundingBoxViews = [BoundingBoxView]()
    private lazy var viewModel = LiveVideoViewModel()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBoundingBoxViews()
        setUpViewModel()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    // MARK: Functions
    
    private func setUpBoundingBoxViews() {
        boundingBoxViews = (0..<viewModel.maxBoundingBoxViews).map { _ in BoundingBoxView() }
        
    }
    
    private func setUpViewModel() {
        viewModel.delegate = self
        viewModel.genColors()
        viewModel.setUpCamera(completion: {
            
            if let previewLayer = self.viewModel.videoCapture.previewLayer {
                self.videoPreview.layer.addSublayer(previewLayer)
                self.resizePreviewLayer()
            }
            
            // Add the bounding box layers to the UI, on top of the video preview.
            self.boundingBoxViews.forEach { box in box.addToLayer(self.videoPreview.layer) }
            
        })
        
    }
    
    private func resizePreviewLayer() {
        viewModel.videoCapture.previewLayer?.frame = videoPreview.bounds
    }
    
}

extension LiveVideoViewController: VideoViewModelDelegate {
    
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
