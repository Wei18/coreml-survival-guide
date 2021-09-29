//
//  PreviewVideoViewModel.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import UIKit
import CoreMedia
import CoreML
import Vision

protocol VideoViewModelDelegate: AnyObject {
    func show(predictions: [VNRecognizedObjectObservation])
}

class PreviewVideoViewModel {
    
    // MARK: Properties
    
    weak var delegate: VideoViewModelDelegate?
    
    private var currentBuffer: CVPixelBuffer?
    
    private let coreMLModel = MobileNetV2_SSDLite()
    
    private lazy var visionModel: VNCoreMLModel = {
        do {
            return try VNCoreMLModel(for: coreMLModel.model)
        } catch {
            fatalError("Failed to create VNCoreMLModel: \(error)")
        }
    }()
    
    private lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        
        // NOTE: If you use another crop/scale option, you must also change
        // how the BoundingBoxView objects get scaled when they are drawn.
        // Currently they assume the full input image is used.
        request.imageCropAndScaleOption = .scaleFill
        return request
    }()
    
    let maxBoundingBoxViews = 10
    
    private(set) var colors: [String: UIColor] = [:]
    
    // MARK: Functions
    
    func genColors() {
        
        // The label names are stored inside the MLModel's metadata.
        let metaData = coreMLModel.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey]
        
        guard
            let userDefined = metaData as? [String: String],
            let allLabels = userDefined["classes"]
        else {
            fatalError("Missing metadata")
        }
        
        colors = allLabels
            .components(separatedBy: ",")
            .reduce(into: [:]) { (dict, label) in
                dict[label] = UIColor(red: CGFloat.random(in: 0...1),
                                      green: CGFloat.random(in: 0...1),
                                      blue: CGFloat.random(in: 0...1),
                                      alpha: 1)
                
            }
        
    }
    
#warning("todo")
    private func predict(sampleBuffer: CMSampleBuffer) {
        guard
            currentBuffer == nil,
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }
        
        currentBuffer = pixelBuffer
        
        // Get additional info from the camera.
        var options: [VNImageOption : Any] = [:]
        if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            options[.cameraIntrinsics] = cameraIntrinsicMatrix
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: options)
        do {
            try handler.perform([self.visionRequest])
        } catch {
            print("Failed to perform Vision request: \(error)")
        }
        
        currentBuffer = nil
        
    }
    
    private func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.delegate?.show(predictions: results)
            } else {
                self.delegate?.show(predictions: [])
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
