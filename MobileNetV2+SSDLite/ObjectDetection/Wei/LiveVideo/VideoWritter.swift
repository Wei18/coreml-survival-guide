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
        
        var dateName: String { Date().timeIntervalSince1970.description }
        
        lazy var fileUrl: URL? = {
            let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard var fileUrl = path.first else {
                ZWLogger.report(NSError())
                return nil
            }
            return fileUrl
        }()
        
        /// The duration of one or more person detected.
        var activeDuration: TimeInterval = 10
        
        /// The names are used to start new video file.
        var activeNames: Set<String> = []
        
        /// The duration of no more person detected.
        var idleDuration: TimeInterval = 5
        
        /// The name is represented to the name of idle file.
        var currentIdleName: String?
        
    }
    
    private var config = Config()
    private var activeTimer: Timer?
    private var idleTimer: Timer?
    
    private func startRecord(with filename: String, fileExtension: String = Config.fileExtension) {
        ZWLogger.log()
        guard var fileUrl = self.config.fileUrl else { return }
        fileUrl.appendPathComponent(filename + fileExtension)
        //movieOutput.startRecording(to: fileUrl, recordingDelegate: self)
    }
    
    private func stopRecord() {
        ZWLogger.log()
        //movieOutput.stopRecording()
    }
    
    /// Once one or more persons are detected.
    ///
    /// The app should start record video and save it into another seconds duration video file
    /// Seconds is according to config.activeDuration, and the file extension as onfig.fileExtension.
    func saveFileWhenDetected(ids: [String]) {
        ZWLogger.log(ids)
        
        let newValues = Set(ids).subtracting(config.activeNames)
        let deferValues = config.activeNames.subtracting(newValues)
        
        for i in newValues.indices {
            config.activeNames.update(with: newValues[i])
            startRecord(with: config.dateName + "_\(i)")
        }
        
        activeTimer = Timer(timeInterval: config.activeDuration, repeats: false, block: { [weak self] _ in
            guard let self = self else { return }
            self.stopRecord()
            self.config.activeNames = deferValues
        })
        
    }
    
    /// Stop video recording automatically
    ///
    /// If no more person detected after the time of last detected video frame over than seconds according to config.idleDuration.
    func saveFileWhenIdle() {
        ZWLogger.log()
        
        idleTimer?.invalidate()
        
        if let existName = config.currentIdleName {
            remove(with: existName)
        }
        
        let name: String = {
            let name = config.dateName
            config.currentIdleName = name
            return name
        }()
        
        startRecord(with: name)
        idleTimer = Timer(timeInterval: config.idleDuration, repeats: false, block: { [weak self] _ in
            self?.stopRecord()
        })
        
    }
    
    private func remove(with filename: String, fileExtension: String = Config.fileExtension) {
        ZWLogger.log()
        guard var fileUrl = self.config.fileUrl else { return }
        fileUrl.appendPathComponent(filename + fileExtension)
        try? FileManager.default.removeItem(at: fileUrl)
    }
    
}
//
//extension VideoRecorder: AVCaptureFileOutputRecordingDelegate {
//
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        if let error = error {
//            ZWLogger.report(error)
//        } else {
//            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
//        }
//    }
//
//}
