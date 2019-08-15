//
//  BuildConfig.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright © 2019 Provide Technologies Inc. All rights reserved.
//

import Foundation

#if DEBUG
let CurrentBuildConfig = BuildConfig.debug
#elseif AD_HOC
let CurrentBuildConfig = BuildConfig.adHoc
#elseif APP_STORE
let CurrentBuildConfig = BuildConfig.appStore
#endif

enum BuildConfig {
    case debug, adHoc, appStore
}
