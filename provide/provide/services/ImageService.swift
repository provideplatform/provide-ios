//
//  ImageService.swift
//  provide
//
//  Created by Kyle Thomas on 3/19/16.
//  Copyright © 2016 Provide Technologies Inc. All rights reserved.
//

import Foundation
import SDWebImage
import KTSwiftExtensions

typealias OnDownloadProgress = (_ receivedSize: Int, _ expectedSize: Int) -> Void
typealias OnImageDownloadSuccess = (_ image: UIImage) -> Void
typealias OnImageDownloadFailure = (_ error: NSError) -> Void

class ImageService {

    fileprivate static let sharedInstance = ImageService()

    fileprivate var cache: SDImageCache!

    class func sharedService() -> ImageService {
        return sharedInstance
    }

    required init() {
        cache = SDImageCache.shared()
    }

    func clearCache() {
        cache.clearMemory()
        cache.clearDisk()
        cache.cleanDisk()
    }

    func fetchImage(_ url: URL,
                    cacheOnDisk: Bool = false,
                    downloadOptions: SDWebImageDownloaderOptions = .continueInBackground,
                    onDownloadSuccess: @escaping OnImageDownloadSuccess,
                    onDownloadFailure: OnImageDownloadFailure!,
                    onDownloadProgress: OnDownloadProgress!)
    {
        var urlComponents = URLComponents()
        urlComponents.scheme = url.scheme
        urlComponents.host = url.host
        urlComponents.path = url.path

        let cacheUrl: URL! = url

        if let cacheUrl = cacheUrl { // urlComponents.URL {
            let cacheKey = cacheUrl.absoluteString

            if let image = cache.imageFromMemoryCache(forKey: cacheKey) {
                 onDownloadSuccess(image)
            } else {
                cache.queryDiskCache(forKey: cacheKey,
                    done: { image, cacheType in
                        if image != nil {
                            onDownloadSuccess(image!)
                        } else {
                            let downloader = SDWebImageDownloader.shared()
                            downloader?.shouldDecompressImages = false
                            _ = downloader?.downloadImage(with: url, options: downloadOptions,
                                progress: { receivedSize, expectedSize in
                                    if let onDownloadProgress = onDownloadProgress {
                                        onDownloadProgress(receivedSize, expectedSize)
                                    }
                                },
                                completed: { image, data, error, finished in
                                    if image != nil && finished {
                                        dispatch_async_global_queue(DispatchQoS.default.qosClass) {
                                            self.cache.store(image, forKey: cacheKey)
                                        }

                                        onDownloadSuccess(image!)
                                    } else if error != nil {
                                        if let onDownloadFailure = onDownloadFailure {
                                            onDownloadFailure(error! as NSError)
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

    func fetchImageSync(_ url: URL) -> UIImage! {
        var urlComponents = URLComponents()
        urlComponents.scheme = url.scheme
        urlComponents.host = url.host
        urlComponents.path = url.path

        let cacheUrl: URL! = url

        if let cacheUrl = cacheUrl { // urlComponents.URL {
            let cacheKey = cacheUrl.absoluteString

            if let image = cache.imageFromMemoryCache(forKey: cacheKey) {
                return image
            } else if let image = cache.imageFromDiskCache(forKey: cacheKey) {
                return image
            }
        }

        return nil
    }
}
