//
//  Logger.swift
//  ObjectDetection
//
//  Created by zwc on 2021/9/28.
//  Copyright © 2021 MachineThink. All rights reserved.
//

import Foundation
import UIKit

class ZWLogger {
    static func log(
        _ items: @autoclosure (() -> [Any]) = [],
        separator: @autoclosure (() -> String) = " ",
        terminator: @autoclosure (() -> String) = "\n",
        file: @autoclosure (() -> String) = #file,
        line: @autoclosure (() -> Int) = #line,
        method: @autoclosure (() -> String) = #function) {
            #if DEBUG
            let contaxt = [method()] + items()
            print(contaxt, separator: separator(), terminator: terminator())
            #endif
        }
    
    static func report(
        _ e: Error,
        file: @autoclosure (() -> String) = #file,
        line: @autoclosure (() -> Int) = #line) {
            // Firebase Crashlytics
            let text = e.localizedDescription
            ZWLogger.log([text], file: file(), line: line())
    }
}

class ZWLogViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ZWLogger.log([self])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ZWLogger.log([self])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ZWLogger.log([self])
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ZWLogger.log([self])
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        ZWLogger.log()
    }
    
}
