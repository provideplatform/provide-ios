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
                //layer.masksToBounds = true
                layer.tileSize = CGSize(width: floorplan.tileSize, height: floorplan.tileSize)
                layer.levelsOfDetail = floorplan.maxZoomLevel + 1
                //layer.levelsOfDetailBias = floorplan.maxZoomLevel + 1
                //layer.drawsAsynchronously = true
                //layer.shouldRasterize = true
            }
        }
    }

    weak var image: UIImage!

    var zoomLevel: Int! {
        didSet {
            if let zoomLevel = zoomLevel {
                if oldValue == nil || zoomLevel != oldValue {
//                    let zoomScale = CGFloat(zoomLevel / floorplan.maxZoomLevel)
//
//                    let x = CGRectGetWidth(layer.bounds) * layer.anchorPoint.x
//                    let y = CGRectGetWidth(layer.bounds) * layer.anchorPoint.y

                    //layer.position = CGPoint(x: x * zoomScale, y: y * zoomScale)
                    //layer.transform = CATransform3DMakeScale(zoomScale, zoomScale, 1.0)

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

        let transform = CGContextGetCTM(ctx)
        let scaleX = transform.a
        let scaleY = transform.d

        let tileSize = CGSize(width: (layer as! CATiledLayer).tileSize.width / scaleX,
                              height: (layer as! CATiledLayer).tileSize.height / -scaleY)

        let z = zoomLevel ?? 0
        let x = Int(rect.origin.x / tileSize.width)
        let y = Int(rect.origin.y / tileSize.height)

        let tilePoint = CGPoint(x: x * Int(tileSize.width), y: y * Int(tileSize.height))

        let url = NSURL("\(baseUrl.absoluteString)/\(z)-\(x)-\(y).png")

        if let image = ImageService.sharedService().fetchImageSync(url) {
            image.drawAtPoint(tilePoint)
        } else {
            CGContextSetFillColorWithColor(ctx, UIColor.clearColor().CGColor)
            CGContextFillRect(ctx, rect)

            ImageService.sharedService().fetchImage(url, cacheOnDisk: true,
                onDownloadSuccess: { image in
                    self.setNeedsDisplay()
                },
                onDownloadFailure: { error in
                    // no-op -- expect failure for "empty" tiles
                    //logWarn("Floorplan image tile download failed (\(url.absoluteString)); \(error)")
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

    func scrollViewDidZoom(scrollView: UIScrollView) {
        if let floorplan = floorplan {
            let scale = scrollView.zoomScale / scrollView.maximumZoomScale
            let newZoomLevel = min(Int(round((Double(scale) * Double(floorplan.maxZoomLevel + 1)))), (layer as! CATiledLayer).levelsOfDetail)
            zoomLevel = newZoomLevel

            //let tileAmount = pow(4.0, CGFloat(zoomLevel))

            //let xOffset = CGFloat(round(scrollView.contentSize.width / 2.0) - (tileAmount / 2.0) * CGFloat(floorplan.tileSize))
            //scrollView.contentOffset.x = -xOffset //scrollView.contentOffset.x FIXME

            //let yOffset = CGFloat(round(scrollView.contentSize.height / 2.0) - (tileAmount / 2.0) * CGFloat(floorplan.tileSize))
            //scrollView.contentOffset.y = -yOffset //scrollView.contentOffset.x FIXME

            //print("x/y offset @ zoom level \(zoomLevel): \(xOffset), \(yOffset)")
            //print("floorplan x/y offset \(floorplan.tilingXOffset)%/\(floorplan.tilingYOffset)")

//            let xOffset = scrollView.contentSize.width * CGFloat(floorplan.tilingXOffset)
//            scrollView.contentInset.left = -xOffset //scrollView.contentOffset.x FIXME
//
//            let yOffset = scrollView.contentSize.height * CGFloat(floorplan.tilingYOffset)
//            scrollView.contentInset.top = -yOffset //scrollView.contentOffset.x FIXME

            if zoomLevel < floorplan.zoomLevels.count {
                if let level = floorplan.zoomLevels[zoomLevel] as? [String : AnyObject] {
                    let width = level["width"] as! Double
                    let height = level["height"] as! Double

                    var xOffset = level["x"] as! Double
                    var yOffset = level["y"] as! Double

                    if xOffset > yOffset {
                        xOffset /= 2.0
                    } else {
                        yOffset /= 2.0
                    }

                    //scrollView.contentSize = CGSize(width: width, height: height)
//                    frame = CGRect(origin: CGPointZero, size: scrollView.contentSize)
                    frame = CGRect(origin: CGPointZero, size: CGSize(width: width, height: height))

                    scrollView.contentOffset.x = CGFloat(xOffset)
                    scrollView.contentOffset.y = CGFloat(yOffset)

                    print("floorplan x/y offset \(xOffset)/\(yOffset)")
                    print("scroll view size: \(scrollView.contentSize)")
                    print("tiled view frame: \(frame)")
                }
            }

        }
    }
}
