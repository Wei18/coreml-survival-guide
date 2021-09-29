//
//  VideoReader.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

protocol VideoReaderDelegate: AnyObject {
    func videoRead(_ reader: VideoReader, didReadVideoFrame sampleBuffer: CMSampleBuffer)
}

class VideoReader {
    
    private let queue = DispatchQueue(label: "VideoReader")
    private(set) lazy var bufferDisplayLayer = AVSampleBufferDisplayLayer()
    private var output: AVAssetReaderVideoCompositionOutput?
    private var assetReader: AVAssetReader?
    weak var delegate: VideoReaderDelegate?
    
    func read(asset: AVAsset) {
        ZWLogger.log()
        do {
            let assetReader = try AVAssetReader(asset: asset)
            
            self.assetReader?.cancelReading()
            self.assetReader = assetReader
            let output = AVAssetReaderVideoCompositionOutput(
                videoTracks: asset.tracks(withMediaType: .video),
                videoSettings: nil)
            output.alwaysCopiesSampleData = false
            output.videoComposition = AVVideoComposition(propertiesOf: asset)
            self.output = output
            assetReader.add(output)
            assetReader.startReading()
            self.repeatedlyDispalyBuffer()
        } catch let e {
            ZWLogger.report(e)
        }
    }
    
    private func repeatedlyDispalyBuffer() {
        bufferDisplayLayer.stopRequestingMediaData()
        bufferDisplayLayer.requestMediaDataWhenReady(on: self.queue) { [weak self] in
            guard let self = self else { return }
            ZWLogger.log()
            if self.assetReader?.status == .reading, let buffer = self.output?.copyNextSampleBuffer() {
                self.bufferDisplayLayer.enqueue(buffer)
                self.delegate?.videoRead(self, didReadVideoFrame: buffer)
            } else {
                self.bufferDisplayLayer.stopRequestingMediaData()
                self.assetReader?.cancelReading()
            }
        }
    }
    
}
