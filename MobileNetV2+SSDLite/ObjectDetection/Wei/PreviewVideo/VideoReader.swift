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
        queue.async {
            ZWLogger.log()
            guard let assetReader = try? AVAssetReader(asset: asset) else {
                ZWLogger.report(DebugError())
                return
            }
            self.assetReader?.cancelReading()
            self.assetReader = assetReader
            let output = AVAssetReaderVideoCompositionOutput(
                videoTracks: asset.tracks(withMediaType: .video),
                videoSettings: nil)
            self.output = output
            assetReader.add(output)
            assetReader.startReading()
        }
    }
    
    func repeatedlyDispalyBuffer() {
        ZWLogger.log()
        bufferDisplayLayer.requestMediaDataWhenReady(on: self.queue) { [weak self] in
            guard let self = self else { return }
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
