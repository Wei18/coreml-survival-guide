//
//  VideoWritter.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit

class VideoWritter {
    
    struct Config {
        static let fileExtension: String = ".mp4"
        var isRecording = false
        var dateName: String { Date().timeIntervalSince1970.description }
        lazy var fileUrl: URL? = {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard var fileUrl = path.first else {
                ZWLogger.report(DebugError())
                return nil
            }
            return fileUrl
        }()
        /// The duration of one or more person detected.
        var activeDuration: TimeInterval = 10
        /// The duration of no more person detected.
        var idleDuration: TimeInterval = 5
        /// The name is represented to the name.
        var currentFilePath: URL?
        var atSourceTime: CMTime?
    }
    
    // MARK: Properties
    
    private var config = Config()
    private var activeTimer: Timer?
    private let queue = DispatchQueue(label: "VideoWritter")
    private var assetWriter: AVAssetWriter!
    private lazy var assetWriterInput: AVAssetWriterInput = {
        let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
            AVVideoCodecKey : AVVideoCodecType.h264,
            AVVideoWidthKey : 720,
            AVVideoHeightKey : 1280,
            AVVideoCompressionPropertiesKey : [
                AVVideoAverageBitRateKey : 2300000,
            ],
        ])
        assetWriterInput.expectsMediaDataInRealTime = true
        return assetWriterInput
    }()
    
    // MARK: Functions
    
    private func startRecord(with filename: String, fileExtension: String = Config.fileExtension) {
        queue.async {
            guard var fileUrl = self.config.fileUrl else {
                ZWLogger.report(DebugError())
                return
            }
            fileUrl.appendPathComponent(filename + fileExtension)
            self.config.currentFilePath = fileUrl
            guard let assetWriter = try? AVAssetWriter(outputURL: fileUrl, fileType: .mp4) else {
                ZWLogger.report(DebugError())
                return
            }
            self.assetWriter = assetWriter
            if assetWriter.canAdd(self.assetWriterInput) {
                assetWriter.add(self.assetWriterInput)
            }
            guard self.config.isRecording == false else { return }
            ZWLogger.log()
            self.config.isRecording = true
            assetWriter.startWriting()
        }
    }
    
    private func stopRecord() {
        queue.async {
            guard self.config.isRecording == true else { return }
            ZWLogger.log()
            self.config.isRecording = false
            self.assetWriterInput.markAsFinished()
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                self.config.atSourceTime = nil
                if let name = self.config.currentFilePath {
                    UISaveVideoAtPathToSavedPhotosAlbum(name.path, nil, nil, nil)
                }
            }
        }
    }
    
    /// Once one or more persons are detected.
    ///
    /// The app should start record video and save it into another seconds duration video file
    /// Seconds is according to config.activeDuration, and the file extension as onfig.fileExtension.
    func saveFileWhenDetected() {
        guard self.config.isRecording == false else { return }
        ZWLogger.log()
        startRecord(with: config.dateName)
        activeTimer = Timer.scheduledTimer(withTimeInterval: config.activeDuration, repeats: false, block: { [weak self] _ in
            self?.stopRecord()
        })
    }
    
    /// Stop video recording automatically
    ///
    /// If no more person detected after the time of last detected video frame over than seconds according to config.idleDuration.
    func saveFileWhenIdle() {
        //ZWLogger.log()
        #warning("todo")
    }
    
//    private func remove(with filename: String, fileExtension: String = Config.fileExtension) {
//        guard var fileUrl = self.config.fileUrl else {
//            ZWLogger.report(DebugError())
//            return
//        }
//        let name = filename + fileExtension
//        ZWLogger.log([name])
//        fileUrl.appendPathComponent(name)
//        try? FileManager.default.removeItem(at: fileUrl)
//    }
    
    func append(_ sampleBuffer: CMSampleBuffer) {
        queue.async {
            guard
                self.assetWriterInput.isReadyForMoreMediaData,
                self.assetWriter.status == .writing,
                self.config.isRecording == true
            else { return }
            if self.config.atSourceTime == nil {
                let sourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
                self.config.atSourceTime = sourceTime
                self.assetWriter.startSession(atSourceTime: sourceTime)
            }
            self.assetWriterInput.append(sampleBuffer)
        }
    }
    
}
