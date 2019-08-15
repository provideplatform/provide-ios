//
//  Monkey.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/22/17.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

func monkey(_ doWhat: String, after seconds: Double = 0.75, block: @escaping VoidBlock) {
    guard ProcessInfo.processInfo.environment["ENABLE_MONKEY"] != nil else { return }

    logmoji("🐵", doWhat)

    let milliseconds = Int(1000 * seconds)
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
        block()
    }
}
