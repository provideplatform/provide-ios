//: Playground - noun: a place where people can play

import UIKit
import CoreLocation
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let address = "1 Hacker Way, Menlo Park, 94025"
let name = "Facebook"
let filename = "\(name.lowercased()).gpx"

// NOTE: Must create the dir to write to
// mkdir ~/Documents/Shared\ Playground\ Data

CLGeocoder().geocodeAddressString(address) { placemarks, error in
    let coordinate = placemarks!.first!.location!.coordinate
    let latitude = coordinate.latitude
    let longitude = coordinate.longitude

    let gpxString = """
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx>
    <wpt lat="\(latitude)" lon="\(longitude)">
        <desc>\(address)</desc>
        <name>\(name)</name>
    </wpt>
</gpx>
"""

    let fileURL = playgroundSharedDataDirectory.appendingPathComponent("/\(filename)")
    try! gpxString.write(to: fileURL, atomically: true, encoding: .utf8)

    print("File has been written to ~/Documents/Shared\\ Playground\\ Data. Move to gpx folder in project manually.\n")
    // open ~/Documents/Shared\ Playground\ Data

    print(gpxString)
    PlaygroundPage.current.finishExecution()
}
