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
import PhotosUI


class PreviewVideoViewController: ZWLogViewController {
    
    // MARK: Properties
    
    @IBOutlet var videoPreview: UIView!
    private lazy var boundingBoxViews = [BoundingBoxView]()
    private lazy var viewModel = PreviewVideoViewModel()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpViews()
        setUpViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        showPhotoLibrary()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        resizePreviewLayer()
    }
    
    // MARK: Functions
    
    private func setUpViewModel() {
        viewModel.delegate = self
        viewModel.genColors()
    }
    
    private func setUpViews() {
        videoPreview.layer.addSublayer(viewModel.videoReader.bufferDisplayLayer)
        boundingBoxViews = (0..<viewModel.maxBoundingBoxViews).map { _ in BoundingBoxView() }
        boundingBoxViews.forEach { box in box.addToLayer(self.videoPreview.layer) }
    }
    
    private func showPhotoLibrary() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func resizePreviewLayer() {
        viewModel.videoReader.bufferDisplayLayer.frame = videoPreview.bounds
    }
    
}

extension PreviewVideoViewController: VideoViewModelDelegate, PHPickerViewControllerDelegate {
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        guard let itemProvider = results.first?.itemProvider else { return }
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.mpeg4Movie.identifier) { [weak self] url, error in
            if let error = error {
                ZWLogger.report(error)
            } else if let url = url {
                self?.viewModel.setVideoUrl(url)
            }
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
