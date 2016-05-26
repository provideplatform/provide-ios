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
                layer.levelsOfDetail = floorplan.maxZoomLevel + 1
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

    override func drawRect(rect: CGRect) {
        let ctx = UIGraphicsGetCurrentContext()
        
        let ctm = CGContextGetCTM(ctx)
        let scaleX = ctm.a
        let scaleY = ctm.d

        let tileSize = CGSize(width: (layer as! CATiledLayer).tileSize.width / scaleX,
                              height: (layer as! CATiledLayer).tileSize.height / -scaleY)

        let z = zoomLevel ?? 0
        let x = Int(rect.origin.x / tileSize.width)
        let y = Int(rect.origin.y / tileSize.height)

        let tilePoint = CGPoint(x: CGFloat(x) * CGFloat(rect.width),
                                y: CGFloat(y) * CGFloat(rect.height))

        let url = NSURL("\(baseUrl.absoluteString)/\(z)-\(x)-\(y).png")

        if let image = ImageService.sharedService().fetchImageSync(url) {
            image.drawAtPoint(tilePoint)
        } else {
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextFillRect(ctx, rect)

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { image in
                    self.layer.setNeedsDisplayInRect(rect)
                },
                onDownloadFailure: { error in
                    // no-op -- expect failure for "empty" tiles
                },
                onDownloadProgress: { receivedSize, expectedSize in
                    if expectedSize != -1 {
                        let percentage: Float = Float(receivedSize) / Float(expectedSize)
                        if percentage == 1.0 {
                            self.layer.setNeedsDisplayInRect(rect)
                        }
                    }
                }
            )
        }
    }

    func scrollViewDidZoom(scrollView: UIScrollView) {
        if let floorplan = floorplan {
            let scale = scrollView.zoomScale / scrollView.maximumZoomScale
            let newZoomLevel = min(Int(round((Double(scale) * Double(floorplan.maxZoomLevel + 1)))), (layer as! CATiledLayer).levelsOfDetail)
            let zoomLevel = newZoomLevel

            if zoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[zoomLevel] as? [String : AnyObject] {
                    let size = CGFloat(level["size"] as! Double) / contentScaleFactor

                    let xOffset = CGFloat(level["x"] as! Double) / contentScaleFactor
                    let yOffset = CGFloat(level["y"] as! Double) / contentScaleFactor
                    let origin = CGPoint(x: -xOffset, y: -yOffset)

                    scrollView.contentSize = CGSize(width: size, height: size)
                    frame = CGRect(origin: origin, size: scrollView.contentSize)

//                    scrollView.contentOffset.x = xOffset
//                    scrollView.contentOffset.y = -yOffset

//                    print("\(scrollView.minimumZoomScale)/\(scrollView.maximumZoomScale)")
//                    print("scroll view content size: \(scrollView.contentSize)")
//                    print("tiled view frame: \(frame)")
                }

                if self.zoomLevel == nil || zoomLevel != self.zoomLevel {
                    self.zoomLevel = zoomLevel

                    dispatch_after_delay(0.0) {
                        scrollView.flashScrollIndicators()
                    }
                }
            }
        }
    }
}
