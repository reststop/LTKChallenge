//
//  LTKDetailViewController.swift
//  LTK Challenge
//
//  Created by carl on 3/21/22.
//

import Foundation
import UIKit
import WebKit

class SheetViewController: UIViewController {
}

class LTKDetailViewController: UIViewController,
                               UICollectionViewDelegate,
                               UICollectionViewDataSource,
                               UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var profileImageView: UIImageView!
    
    var ltk: LTKItem = LTKItem()

    var products: [LTKProduct] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        products = ltk.products
        for index in 0...(products.count - 1) {
            LTKImage.download(products[index].ID, products[index].imageURL)
        }
        refreshImages()

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        self.collectionView.reloadData()
    }

    func refreshImages() {

        var image = LTKImage.get(ltk.ID, ltk.heroURL)
        //debugPrint("URL: \(ltk.heroURL)")
        if image != nil {
            let hSize = self.heroImageView.frame.size
            let iSize = image!.size
            let newHeight = (hSize.width * iSize.height) / iSize.width
            self.heroImageView.frame.size.height = newHeight
            self.heroImageView.bounds.size.height = newHeight

            let vWidth = self.view.frame.size.width
            let iWidth = self.heroImageView.frame.size.width
            let newX = (vWidth - iWidth) / 2
            self.heroImageView.frame.origin.x = newX

            self.heroImageView.image = image
        }

        image = LTKImage.get(ltk.profileID, ltk.profileURL)
        if image != nil {
            let hSize = self.profileImageView.frame.size
            let iSize = image!.size
            let newHeight = (hSize.width * iSize.height) / iSize.width
            self.profileImageView.frame.size.height = newHeight
            self.profileImageView.bounds.size.height = newHeight

            let vWidth = self.view.frame.size.width
            let iWidth = self.profileImageView.frame.size.width
            let newX = (vWidth - iWidth) / 2
            self.profileImageView.frame.origin.x = newX

            self.profileImageView.image = image
        }
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // add notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(updateResults), name: RESULTNOTIFICATION, object: nil)
    }


    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: RESULTNOTIFICATION, object: nil)
        super.viewDidDisappear(animated)
    }

    @objc private func updateResults() {
        refreshImages()
        self.collectionView.reloadData()
    }




    private func loadMyPage(_ urlString: String) {

        // Create the view controller.
        let sheetViewController =  SheetViewController(nibName: nil, bundle: nil)

        // ready for the URL
        let webView = WKWebView.init(frame: self.view.frame)
        let request = URLRequest(url: URL(string: urlString)!)
        webView.load(request)

        sheetViewController.view.addSubview(webView)
        // Present it w/o any adjustments so it uses the default sheet presentation.
        present(sheetViewController, animated: true, completion: nil)
        sheetViewController.sheetPresentationController?.prefersGrabberVisible = true
    }


    //
    // MARK: - Delegate Methods
    //


    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        return CGSize(width: 128, height: 128)
    }


    func collectionView(_: UICollectionView, numberOfItemsInSection: Int) -> Int {
        return self.products.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let product = products[indexPath.row]

        let cell : LTKProductViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "productCell", for: indexPath) as! LTKProductViewCell

        let image : UIImage? = LTKImage.get(product.ID, product.imageURL)
        if image != nil {
            cell.imageView.image = image
        }
        else {
            debugPrint("Using placeholder")
            cell.imageView.image = LTKImage.placeHolderImage
        }

        cell.setNeedsDisplay()
        return cell
    }


    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let urlString = products[indexPath.row].hyperlink
        loadMyPage(urlString)
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let urlString = products[indexPath.row].hyperlink
        loadMyPage(urlString)
    }


}



class LTKProductViewCell : UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

}

