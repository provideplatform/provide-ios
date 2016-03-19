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

    private var cache: SDImageCache!

    class func sharedService() -> ImageService {
        return sharedInstance
    }

    required init() {
        cache = SDImageCache.sharedImageCache()
    }

    func clearCache() {
        cache.clearMemory()
        cache.clearDisk()
        cache.cleanDisk()
    }

    func fetchImage(url: NSURL,
                    cacheOnDisk: Bool = false,
                    downloadOptions: SDWebImageDownloaderOptions = .ContinueInBackground,
                    onDownloadSuccess: OnImageDownloadSuccess,
                    onDownloadFailure: OnImageDownloadFailure!,
                    onDownloadProgress: OnDownloadProgress!)
    {
        let urlComponents = NSURLComponents()
        urlComponents.scheme = url.scheme
        urlComponents.host = url.host
        urlComponents.path = url.path

        if let cacheUrl = urlComponents.URL {
            let cacheKey = cacheUrl.absoluteString

            if let image = cache.imageFromMemoryCacheForKey(cacheKey) {
                 onDownloadSuccess(image: image)
            } else {
                cache.queryDiskCacheForKey(cacheKey,
                    done: { image, cacheType in
                        if image != nil {
                            onDownloadSuccess(image: image)
                        } else {
                            let downloader = SDWebImageDownloader.sharedDownloader()
                            downloader.shouldDecompressImages = false
                            downloader.downloadImageWithURL(url, options: downloadOptions,
                                progress: { receivedSize, expectedSize in
                                    if let onDownloadProgress = onDownloadProgress {
                                        onDownloadProgress(receivedSize: receivedSize, expectedSize: expectedSize)
                                    }
                                },
                                completed: { image, data, error, finished in
                                    if image != nil && finished {
                                        dispatch_async_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT) {
                                            self.cache.storeImage(image, forKey: cacheKey)
                                        }
                                        
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
}
