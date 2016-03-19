//
//  ImageService.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation

typealias OnDownloadProgress = (receivedSize: Int, expectedSize: Int) -> ()
typealias OnImageDownloadSuccess = (image: UIImage) -> ()
typealias OnImageDownloadFailure = (error: NSError) -> ()

class ImageService {

    private let defaultImageCacheNamespace = "images"

    private static let sharedInstance = ImageService()

    class func sharedService() -> ImageService {
        return sharedInstance
    }

    func clearCache() {
        let cache = SDImageCache(namespace: defaultImageCacheNamespace)
        cache.clearMemory()
        cache.clearDisk()
        cache.cleanDisk()
    }

    func fetchImage(url: NSURL,
                    cacheOnDisk: Bool = false,
                    onDownloadSuccess: OnImageDownloadSuccess,
                    onDownloadFailure: OnImageDownloadFailure!,
                    onDownloadProgress: OnDownloadProgress!)
    {
        let cache = SDImageCache(namespace: defaultImageCacheNamespace)

        let urlComponents = NSURLComponents()
        urlComponents.scheme = url.scheme
        urlComponents.host = url.host
        urlComponents.path = url.path

        if let cacheUrl = urlComponents.URL {
            let cacheKey = cacheUrl.absoluteString
            cache.queryDiskCacheForKey(cacheKey,
                done: { image, cacheType in
                    if image != nil {
                        onDownloadSuccess(image: image)
                    } else {
                        let manager = SDWebImageManager.sharedManager()
                        manager.downloadImageWithURL(url, options: .RetryFailed, progress: onDownloadProgress,
                            completed: { image, error, cacheType, finished, imageUrl in
                                if image != nil && finished {
                                    cache.storeImage(image, forKey: cacheKey, toDisk: cacheOnDisk)
                                    onDownloadSuccess(image: image)
                                } else if error != nil {
                                    if let onDownloadFailure = onDownloadFailure {
                                        onDownloadFailure(error: error)
                                    }
                                }
                            }
                        )
                    }
                }
            )
        }
    }
}
