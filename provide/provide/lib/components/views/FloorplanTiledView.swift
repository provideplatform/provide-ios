//
//  FloorplanTiledLayer.swift
//  provide
//
//  Created by Kyle Thomas on 5/16/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import UIKit
import CoreGraphics

class FloorplanTiledView: UIView {

    weak var floorplan: Floorplan! {
        didSet {
            if let floorplan = floorplan {
                let layer = self.layer as! CATiledLayer
                layer.tileSize = CGSize(width: floorplan.tileSize, height: floorplan.tileSize)
                layer.levelsOfDetail = 1
            }
        }
    }

    var zoomLevel: Int! {
        didSet {
            if let zoomLevel = zoomLevel {
                if oldValue == nil || zoomLevel != oldValue {
                    setNeedsDisplay()
                }
            }
        }
    }

    fileprivate var baseUrl: URL! {
        if let floorplan = floorplan {
            if let tilingBaseUrl = floorplan.tilingBaseUrl {
                return URL(string: "\(tilingBaseUrl.absoluteString)")
            }
        }
        return nil
    }

    override class var layerClass : AnyClass {
        return CATiledLayer.self
    }

    override func draw(_ rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let ctm = ctx?.ctm
        let scaleX = ctm?.a
        let scaleY = ctm?.d

        let tileSize = CGSize(width: (layer as! CATiledLayer).tileSize.width / scaleX!,
                              height: (layer as! CATiledLayer).tileSize.height / (scaleY! * -1.0))

        let z = zoomLevel ?? 0
        let x = Int(rect.origin.x / tileSize.width)
        let y = Int(rect.origin.y / tileSize.height)

        let tilePoint = CGPoint(x: CGFloat(x) * CGFloat(rect.width),
                                y: CGFloat(y) * CGFloat(rect.height))

        let url = URL(string: "\(baseUrl.absoluteString)/\(z)-\(x)-\(y).png")

        if let image = ImageService.sharedService().fetchImageSync(url!) {
            image.draw(at: tilePoint)
        } else {
            ctx?.setFillColor(UIColor.clear.cgColor)
            ctx?.fill(rect)

            ImageService.sharedService().fetchImage(url!, cacheOnDisk: true,
                onDownloadSuccess: { image in
                    self.layer.setNeedsDisplayIn(rect)
                },
                onDownloadFailure: { error in
                    // no-op -- expect failure for "empty" tiles
                },
                onDownloadProgress: { receivedSize, expectedSize in
                    if expectedSize != -1 {
                        let percentage: Float = Float(receivedSize) / Float(expectedSize)
                        if percentage == 1.0 {
                            self.layer.setNeedsDisplayIn(rect)
                        }
                    }
                }
            )
        }
    }

    func applyOffsetCorrection(_ scrollView: UIScrollView) {
        if let floorplan = floorplan {
            if zoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[zoomLevel] as? [String : AnyObject] {
                    let width = (CGFloat(level["width"] as! Double) / contentScaleFactor)
                    let height = (CGFloat(level["height"] as! Double) / contentScaleFactor)
                    let tileSize = CGFloat(level["size"] as! Double)
                    let xOffset = (CGFloat(level["x"] as! Double) / contentScaleFactor) - scrollView.contentOffset.x
                    let yOffset = (CGFloat(level["y"] as! Double) / contentScaleFactor) - scrollView.contentOffset.y

                    let origin = CGPoint(x: -xOffset, y: -yOffset)
                    let size = CGSize(width: width, height: height)

                    scrollView.contentSize = size

                    frame = CGRect(origin: origin,
                                   size: CGSize(width: tileSize, height: tileSize))
                }
            }
        }
    }
}
