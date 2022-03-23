//
//  LTKImage.swift
//  LTK Challenge
//
//  Created by carl on 3/21/22.
//

import Foundation
import AlamofireImage
import UIKit

//
// This module implements image caching
// using a URL and a key, using the id for
// the image from the LTK data
//

class LTKImage {

    static let selectAlamofire: Bool = true
    static var imageCache = AutoPurgingImageCache(
        memoryCapacity: 200_000_000,
        preferredMemoryUsageAfterPurge: 150_000_000
    )
    static var downloader = ImageDownloader()
    static var placeHolderImage = UIImage(named: "placeholder")

    static var cache: [String:UIImage] = [:]

    class func initialize() {
        if selectAlamofire {
            imageCache = AutoPurgingImageCache(
                memoryCapacity: 200_000_000,
                preferredMemoryUsageAfterPurge: 150_000_000
            )
            downloader = ImageDownloader(
                configuration: ImageDownloader.defaultURLSessionConfiguration(),
                downloadPrioritization: .fifo,
                maximumActiveDownloads: 8,
                imageCache: imageCache
            )
        }
        else {
            cache = [:]
        }
        placeHolderImage = UIImage(named: "placeholder")
    }

    class func notifyResult(_ key: String, _ url: String, success: Bool) {
        NotificationCenter.default.post(name: RESULTNOTIFICATION, object: [key, url, success])
        //debugPrint("LTKImage Posted: \(key) \(url) \(success)")
    }


    class func add(_ image: UIImage, _ key: String, _ url: String) {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            imageCache.add(image, for: urlRequest, withIdentifier: key)
        }
        else {
            let newKey = "\(key),\(url)"
            cache[newKey] = image
        }
    }

    class func get(_ key: String, _ url: String) -> UIImage? {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            let image = imageCache.image(for: urlRequest, withIdentifier: key)
            if image == nil {
                debugPrint("Could not get image for: ",key,", ",url)
                // start a download for any missing image
                download(key, url)
            }
            return image
        }
        else {
            let newKey = "\(key),\(url)"
            let image = cache[newKey]
            return image
        }
    }

    class func remove(_ key: String, _ url: String) {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            imageCache.removeImage(for: urlRequest, withIdentifier: key)
        }
        else {
            let newKey = "\(key),\(url)"
            cache[newKey] = nil
        }
    }

    class func download(_ key: String, _ url: String) {
        let urlRequest = URLRequest(url: URL(string: url)!)
        if imageCache.image(for: urlRequest, withIdentifier: key) != nil {
            debugPrint("Already loaded: ",key," ",url)
            return
        }

        downloader.download(urlRequest, cacheKey: key, completion:  { response in

            if case .success(let image) = response.result {
                add(image, key, url)
                notifyResult(key, url, success: true)
            }
            else {
                notifyResult(key, url, success: false)
            }

        })
    }

}
