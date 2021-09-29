//
//  ViewController+Ext.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/29.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import Vision

extension ViewController {
    
    func handle(with predictions: [VNRecognizedObjectObservation]) {
        
        let personUUIDs = predictions
            .flatMap(\.labels)
            .filter { $0.identifier == "person" }
            .map(\.uuid.uuidString)
        
        if personUUIDs.isEmpty {
            videoCapture.saveFileWhenIdle()
        } else {
            videoCapture.saveFileWhenDetected(ids: personUUIDs)
        }
        
    }
    
}


