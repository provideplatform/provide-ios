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

    private static let sharedInstance = ImageService()

    class func sharedService() -> ImageService {
        return sharedInstance
    }

    func clearCache() {
        let cache = SDImageCache.sharedImageCache()
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
        let cache = SDImageCache.sharedImageCache()

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
                        cache.removeImageForKey(cacheKey)

                        let downloader = SDWebImageDownloader.sharedDownloader()
                        downloader.downloadImageWithURL(url, options: .ContinueInBackground,
                            progress: { receivedSize, expectedSize in
                                if let onDownloadProgress = onDownloadProgress {
                                    onDownloadProgress(receivedSize: receivedSize, expectedSize: expectedSize)
                                }
                            },
                            completed: { image, data, error, finished in
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
