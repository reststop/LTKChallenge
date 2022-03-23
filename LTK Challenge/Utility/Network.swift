//
//  Network.swift
//  LTK Challenge
//
//  Created by carl on 3/21/22.
//

import Foundation
import UIKit
import Alamofire
import AlamofireImage

let RESULTNOTIFICATION = Notification.Name("NETWORK-RESULT-NOTIFICATION")
let PAGELOADEDNOTIFICATION = Notification.Name("PAGE-LOADED-NOTIFICATION")


class Network {

    // https://api-gateway.rewardstyle.com/api/ltk/v2/ltks/?featured=true&limit=20

    class func notifyResult() {
        NotificationCenter.default.post(name: RESULTNOTIFICATION, object: nil)
    }

    class func pageLoaded() {
        NotificationCenter.default.post(name: PAGELOADEDNOTIFICATION, object: nil)
    }


    class func loadPage(_ page: Int, complete: @escaping (Bool, Int, [String:Any]?) -> Void) {
        let urlString = "https://api-gateway.rewardstyle.com/api/ltk/v2/ltks/"
        let count = LTKData.lastID.count
        if page == 0 {
            // first page
            let parameters = ["featured": "true",
                              "limit": "\(LTKData.itemCount)"]

            AF.request(urlString, method: .get, parameters: parameters).responseJSON { response in

                if case .success(let json) = response.result {
                    complete(true, page, json as? [String : Any])
                    //Network.notifyResult()
                    Network.pageLoaded()
                }

            }
        }
        else {
            // additional pages require last_id and seed
            if count > page {
                // good we have an ID
                if count > (page + 1) {
                    // we already processed this page
                    complete(true, page, nil)
                }
                // else get the data
                let parameters = ["featured": "true",
                                  "limit": "\(LTKData.itemCount)",
                                  "last_id": "\(LTKData.lastID)",
                                  "seed": "\(LTKData.seed)"
                ]
                AF.request(urlString, method: .get, parameters: parameters).responseJSON { response in

                    if case .success(let json) = response.result {
                        complete(true, page, json as? [String : Any])
                        //Network.notifyResult()
                        Network.pageLoaded()
                    }
                }

            }
            else {
                complete(false, page, nil)
            }
        }
    }

    class func getImage(_ urlString: String, key: String, completion: @escaping (UIImage?) -> Void) {
        AF.request(urlString, method: .get).responseImage { response in
            if case .success(let image) = response.result {
                LTKImage.add(image, key, urlString)
                completion(image)
                Network.notifyResult()
            }
            else {
                getImage(urlString, key: key) { image in
                    completion(image)
                }
            }
        }
    }

}
