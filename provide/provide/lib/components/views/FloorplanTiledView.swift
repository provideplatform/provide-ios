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
                layer.levelsOfDetail = floorplan.maxZoomLevel
//                layer.levelsOfDetailBias = floorplan.maxZoomLevel
                //layer.drawsAsynchronously = true
                //layer.shouldRasterize = false
            }
        }
    }

    weak var image: UIImage!

    private var baseUrl: NSURL! {
        if let floorplan = floorplan {
            if let tilingBaseUrl = floorplan.tilingBaseUrl {
                return NSURL("\(tilingBaseUrl.absoluteString)")
            }
        }
        return nil
    }

    override class func layerClass() -> AnyClass {
        return CATiledLayer.self
    }

    override func drawLayer(layer: CALayer, inContext ctx: CGContext) {
        let boundingRect = CGContextGetClipBoundingBox(ctx)
        let contentsScale = layer.contentsScale
        let tileSize = (layer as! CATiledLayer).tileSize

        if floorplan == nil {
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextFillRect(ctx, boundingRect)
            return
        }

        let z = 1
        let x = Int(boundingRect.origin.x * contentsScale / tileSize.width)
        let y = Int(boundingRect.origin.y * contentsScale / tileSize.height)

        let tilePoint = CGPoint(x: x * Int(tileSize.width), y: y * Int(tileSize.height))
        let imageRect = CGRect(origin: tilePoint, size: tileSize)

        let url = NSURL("\(baseUrl.absoluteString)/\(z)-\(x)-\(y).png")

//        if let image = image {
//            CGContextDrawImage(ctx, boundingRect, image.crop(imageRect).CGImage)
//
//            CGContextSetFillColorWithColor(ctx, UIColor(patternImage: image.crop(imageRect)).CGColor)
//            CGContextFillRect(ctx, boundingRect)
//        }

        if let image = ImageService.sharedService().fetchImageSync(url) {
            CGContextDrawImage(ctx, boundingRect, image.CGImage)
//            CGContextSetFillColorWithColor(ctx, UIColor(patternImage: image).CGColor)
//            CGContextFillRect(ctx, boundingRect)
        } else {
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextFillRect(ctx, boundingRect)

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { image in
                    self.setNeedsDisplay()
                },
                onDownloadFailure: { error in
                    logWarn("Floorplan image tile download failed; \(error)")
                },
                onDownloadProgress: { receivedSize, expectedSize in
                    if expectedSize != -1 {
                        let percentage: Float = Float(receivedSize) / Float(expectedSize)
                        if percentage == 1.0 {
                            self.setNeedsDisplay()
                        }
                    }
                }
            )
        }
    }
}
