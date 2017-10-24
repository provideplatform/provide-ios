//
//  Logmoji.swift
//  provide
//
//  Created by Jawwad Ahmad on 10/24/17.
//  Copyright © 2017 Provide Technologies Inc. All rights reserved.
//

import Foundation


// **Uncomment** any items that you don't want to log
let skipList: [Character] = [
//    "↗️", // request
//    "✅", // response
//    "🌎", // location
//    "🛑", // stopped checkin service
//    "✴️", // websocket message
//    "⚛️", // status
//    "📝", // status
//    "🐵", // monkey did something
//    "🚗", // Added provider annotation
//    "👱", // user did something
//    "📌", // checkin
//    "✳️", // started location service updates
//    "📍", // location resolved
//    "🚦", // started checkin service
//    "💰", // tip
//    "🗺", // map rendered
]


func logmoji(_ emoji: Character, _ item: Any) {
    if !skipList.contains(emoji) {
        print(emoji, item, emoji)
    }
}
