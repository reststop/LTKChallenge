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

enum ImageType: String, CaseIterable, Identifiable {
    case hero
    case profile
    case product

    var id: String { self.rawValue }
}



final class LTKImage {

    private static let selectAlamofire: Bool = true
    private static let separateImageCache: Bool = true


    private static var imageCacheHero = AutoPurgingImageCache(
        memoryCapacity: 1_000_000_000,
        preferredMemoryUsageAfterPurge: 950_000_000
    )
    private static var imageCacheProfile = imageCacheHero
    private static var imageCacheProduct = imageCacheHero

    private static var downloaderHero    = ImageDownloader()
    private static var downloaderProfile = downloaderHero
    private static var downloaderProduct = downloaderHero

    private static var cache: [String:UIImage] = [:]
    private static var toDownload: [String:String] = [:]


    class func initialize() {
        if selectAlamofire {
            imageCacheHero = AutoPurgingImageCache(
                memoryCapacity: 500_000_000,
                preferredMemoryUsageAfterPurge: 450_000_000
            )
            if separateImageCache {
                imageCacheProfile = AutoPurgingImageCache(
                    memoryCapacity: 400_000_000,
                    preferredMemoryUsageAfterPurge: 350_000_000
                )
                imageCacheProduct = AutoPurgingImageCache(
                    memoryCapacity: 300_000_000,
                    preferredMemoryUsageAfterPurge: 250_000_000
                )
            }
            else {
                imageCacheProfile = imageCacheHero
                imageCacheProduct = imageCacheHero
            }
            downloaderHero = ImageDownloader(
                configuration: ImageDownloader.defaultURLSessionConfiguration(),
                downloadPrioritization: .fifo,
                maximumActiveDownloads: 10,
                imageCache: imageCacheHero
            )
            if separateImageCache {
                downloaderProfile = ImageDownloader(
                    configuration: ImageDownloader.defaultURLSessionConfiguration(),
                    downloadPrioritization: .fifo,
                    maximumActiveDownloads: 5,
                    imageCache: imageCacheProfile
                )
                downloaderProduct = ImageDownloader(
                    configuration: ImageDownloader.defaultURLSessionConfiguration(),
                    downloadPrioritization: .fifo,
                    maximumActiveDownloads: 8,
                    imageCache: imageCacheProduct
                )
            }
            else {
                downloaderProfile = downloaderHero
                downloaderProduct = downloaderHero
            }
        }
        else {
            cache = [:]
        }
        placeHolderImage = Image(named: "placeholder")
        toDownload = [:]
    }

    private class func notifyResult(_ key: String, _ url: String, success: Bool) {
        NotificationCenter.default.post(name: RESULTNOTIFICATION, object: [key, url, success])
        //debugPrint("LTKImage Posted: \(key) \(url) \(success)")
    }

    private class func imageCacheFor(_ type: ImageType) -> AutoPurgingImageCache {
        switch type {
        case .hero:
            return imageCacheHero
        case .profile:
            return imageCacheProfile
        case .product:
            return imageCacheProduct
        }
    }

    private class func downloaderFor(_ type: ImageType) -> ImageDownloader {
        switch type {
        case .hero:
            return downloaderHero
        case .profile:
            return downloaderProfile
        case .product:
            return downloaderProduct
        }
    }

    //
    // MARK: Public functions
    //

    public static var placeHolderImage  = Image(named: "placeholder")


    public class func add(_ type: ImageType, _  image: Image, _ key: String, _ url: String) {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            let imageCache =  LTKImage.imageCacheFor(type)
            imageCache.add(image, for: urlRequest, withIdentifier: key)
        }
        else {
            let newKey = "\(key),\(url)"
            cache[newKey] = image
        }
    }

    public class func get(_ type: ImageType, _ key: String, _ url: String) -> Image? {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            let imageCache =  LTKImage.imageCacheFor(type)
            let image = imageCache.image(for: urlRequest, withIdentifier: key)

            if image == nil {
                debugPrint("Could not get image for: \(key), \(url)")
                // start a download for any missing image
                download(type, key, url)
            }
            return image
        }
        else {
            let newKey = "\(key),\(url)"
            let image = cache[newKey]
            return image
        }
    }

    public class func remove(_ type: ImageType, _ key: String, _ url: String) {
        if selectAlamofire {
            let urlRequest = URLRequest(url: URL(string: url)!)
            let imageCache =  LTKImage.imageCacheFor(type)
            imageCache.removeImage(for: urlRequest, withIdentifier: key)
        }
        else {
            let newKey = "\(key),\(url)"
            cache[newKey] = nil
        }
    }

    public class func download(_ type: ImageType, _ key: String, _ url: String) {
        let urlRequest = URLRequest(url: URL(string: url)!)
        let imageCache =  LTKImage.imageCacheFor(type)
        if imageCache.image(for: urlRequest, withIdentifier: key) != nil {
            debugPrint("Already loaded: \(key) \(url)")
            return
        }

        let useKey = "\(key)-\(url)"
        if toDownload[useKey] != nil {
            return
        }
        else {
            toDownload[useKey] = "trying"
        }

        let downloader = LTKImage.downloaderFor(type)
        downloader.download(urlRequest, cacheKey: key, completion:  { response in

            if case .success(let image) = response.result {
                toDownload[useKey] = nil
                if imageCache.image(for: urlRequest, withIdentifier: key) != nil {
                    debugPrint("Downloaded already: \(key) \(url)")
                }
                else {
                    debugPrint("Download complete:  \(key) \(url)")
                    add(type, image, key, url)
                }
                notifyResult(key, url, success: true)
            }
            else {
                notifyResult(key, url, success: false)
            }

        })
    }

}
