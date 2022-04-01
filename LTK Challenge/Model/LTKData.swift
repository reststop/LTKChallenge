//
//  LTKData.swift
//  LTK Challenge
//
//  Created by carl on 3/21/22.
//

import Foundation
import UIKit


struct LTKProduct {
    var ID : String = ""
    var imageURL : String = ""
    var hyperlink : String = ""
}

struct LTKItem {
    var ID : String = ""
    var heroURL : String = ""
    var heroWidth : Int = 0
    var heroHeight : Int = 0
    var caption : String = ""
    var products : [ LTKProduct ] = []
    var profileID : String = ""
    var profileURL : String = ""
}


class LTKData {

    // primary items
    static let itemCount : Int = 10
    static var itemPages : Int = 0
    static var itemMax : Int = 0

    static var items : [LTKItem] = []

    // meta values needed for next URL
    static var lastID : String = ""
    static var seed : String = ""
    static var nextURL : String = ""

    //
    // MARK: - Data Methods
    //

    class func loadNextPage(_ completion: @escaping (Bool) -> Void) {
        if LTKData.items.count <= LTKData.itemMax {
            let page = LTKData.items.count / LTKData.itemCount
            Network.loadPage(page) { success, page, pageItems in
                if (pageItems != nil) {
                    completion(processData(page, pageItems!))
                }
                else {
                    completion(success)
                }
            }
        }
    }

    
    private class func processData(_ page: Int, _ pageItems: [String:Any]) -> Bool {

        // grab items from data in more useful chunks
        let ltks = pageItems["ltks"] as! [[String:Any]]
        var products = pageItems["products"] as! [[String:Any]]
        let profiles = pageItems["profiles"] as! [[String:Any]]
        let ltkMeta = pageItems["meta"] as! [String:Any]

        // process the big chunk -- each picture group
        if (ltks.count == itemCount) {
            var baseIndex = itemCount * page
            for entry in ltks {

                // only process data if count syncs with needed entries
                if items.count == baseIndex {
                    var ltk : LTKItem = LTKItem()
                    ltk.ID = entry["id"] as! String

                    // hero image and caption
                    ltk.heroURL = entry["hero_image"] as! String
                    ltk.caption = entry["caption"] as! String

                    // asynchronously get hero image
                    LTKImage.download(.hero, ltk.ID, ltk.heroURL)

                    // need width and height for custom image cell size
                    ltk.heroWidth = entry["hero_image_width"] as! Int
                    ltk.heroHeight = entry["hero_image_height"] as! Int

                    //
                    // product id found in products, needed for detail screen
                    // assumption is that products are used only once
                    // if that isnt true, then we can NOT remove them
                    // removing them so we don't check them more than needed
                    //
                    let productIDs = entry["product_ids"] as! [String]
                    for pid : String in productIDs {
                        for index in 0...products.count {
                            let product = products[index]
                            if pid == (product["id"] as! String) {
                                // found a match, setup product element
                                var prod = LTKProduct()
                                prod.ID = pid
                                prod.imageURL = product["image_url"] as! String
                                prod.hyperlink = product["hyperlink"] as! String

                                // asynchronously get product images
                                // skip product images until detail page
                                // LTKImage.download(pid, prod.imageURL)

                                // append record to more permanent storage
                                ltk.products.append(prod)
                                products.remove(at: index)
                                break
                            }
                        }
                    } // each pid

                    // process profile info needed for detail screen
                    ltk.profileID = entry["profile_id"] as! String
                    for index in 0...profiles.count {
                        let profile = profiles[index]
                        if ltk.profileID == (profile["id"] as! String) {
                            ltk.profileURL = profile["avatar_url"] as! String

                            // asynchronously get profile image
                            LTKImage.download(.profile, ltk.profileID, ltk.profileURL)
                            break
                        }
                    } // each profile

                    // debugPrint(ltk)
                    // add entry and bump index to match
                    items.append(ltk)
                    baseIndex = baseIndex + 1
                }
            } // each ltks

            // each page info needed for next page request
            seed = ltkMeta["seed"] as! String
            lastID = ltkMeta["last_id"] as! String
            nextURL = ltkMeta["next_url"] as! String
            itemMax = ltkMeta["total_results"] as! Int
            return true
        }
        return false
    }


}
