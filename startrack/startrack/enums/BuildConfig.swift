//
//  BuildConfig.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/15.
//  Copyright (c) 2015 Provide Technologies Inc. All rights reserved.
//

import Foundation

#if DEBUG
    let CurrentBuildConfig = BuildConfig.Debug
#elseif AD_HOC
    let CurrentBuildConfig = BuildConfig.AdHoc
#elseif APP_STORE
    let CurrentBuildConfig = BuildConfig.AppStore
#endif

enum BuildConfig {
    case Debug, AdHoc, AppStore
}
