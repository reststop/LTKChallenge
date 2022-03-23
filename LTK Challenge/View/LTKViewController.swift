//
//  LTKViewController.swift
//  LTK Challenge
//
//  Created by carl on 3/21/22.
//

import Foundation
import UIKit

class LTKViewController: UIViewController,
                         UICollectionViewDelegate,
                         UICollectionViewDataSource,
                         UICollectionViewDelegateFlowLayout {


    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var nextButton: UIBarButtonItem!

    var pageIndex: Int = 0
    var baseIndex: Int = 0

    var refresh: Int = 0
    var selectedLTK: LTKItem = LTKItem()


    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        debugPrint("Items/page: \(LTKData.itemCount)")
        self.backButton.tintColor = UIColor.clear

        self.pageIndex = 0
        self.baseIndex = 0

        self.collectionView.delegate = self
        self.collectionView.dataSource = self

        loadNextPage()
    }

    func loadNextPage() {
        LTKData.loadNextPage() { success  in
            if success {
                self.collectionView.reloadData()
            }
            else {
                // give error
                debugPrint("Failed to load page")
            }
        }
    }

   override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       self.baseIndex = self.pageIndex * LTKData.itemCount
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // add notification observers
        NotificationCenter.default.addObserver(self, selector: #selector(updateResults), name: RESULTNOTIFICATION, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(pageLoaded), name: PAGELOADEDNOTIFICATION, object: nil)
    }


    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: RESULTNOTIFICATION, object: nil)
        NotificationCenter.default.removeObserver(self, name: PAGELOADEDNOTIFICATION, object: nil)
        super.viewDidDisappear(animated)
    }

    // Notifications

    @objc private func updateResults() {
        self.collectionView.reloadData()
    }
    @objc private func pageLoaded() {
        debugPrint("Page Loaded Notification: \(LTKData.items.count) items.")
        self.collectionView.reloadData()
        checkPreloading()
    }

    func checkPreloading() {
        // if not near the end, preload a couple of pages ahead
        if ((self.pageIndex + 3) * LTKData.itemCount) >= LTKData.items.count {
            loadNextPage()
        }

    }

    // Back-Next buttons

    @IBAction func backButtonAction(_ sender: UIBarButtonItem) {
        debugPrint("back: ", sender)
        if self.pageIndex > 0 {
            self.pageIndex = self.pageIndex - 1
            self.baseIndex = self.pageIndex * LTKData.itemCount
            self.collectionView.reloadData()
        }
        if self.pageIndex == 0 {
            sender.tintColor = UIColor.clear
        }

    }

    @IBAction func nextButtonAction(_ sender: UIBarButtonItem) {
        debugPrint("next: ", sender)
        self.pageIndex = self.pageIndex + 1
        checkPreloading()

        self.baseIndex = self.pageIndex * LTKData.itemCount
        self.backButton.tintColor = UIColor.tintColor
        self.collectionView.reloadData()
    }


    //
    // MARK: - CollectionView Delegate Methods
    //

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {

        // to get image width and height
        // scale the size using hero w/h against actual width
        let ltk = LTKData.items[indexPath.row]
        let width = Int(self.collectionView.frame.width) - 20
        let height = (Int(width) * ltk.heroHeight) / ltk.heroWidth
        //debugPrint("Row: \(indexPath.row) size = \(width)x\(height)")
        return CGSize(width: width, height: height)
    }


    func collectionView(_: UICollectionView, numberOfItemsInSection: Int) -> Int {
        // if we have full pages and this is not the last page
        // use itemCount, otherwise if on the last
        // page use itemMax % itemCount
        var count = LTKData.itemCount
        if LTKData.itemMax > 0 {
            if ((self.pageIndex + 1) * LTKData.itemCount) > LTKData.itemMax {
                count = LTKData.itemMax % LTKData.itemCount
            }
        }
        else {
            // return 0 until we actually have data
            return 0
        }
        let greater = LTKData.items.count - (self.pageIndex * LTKData.itemCount)
        if greater >= count {
            return count
        }
        else {
            return greater
        }
    }


    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell : LTKImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! LTKImageViewCell

        let row = (LTKData.itemCount * self.pageIndex) + indexPath.row
        if row >= LTKData.items.count {
            debugPrint("Item Index out of range")
            return cell
        }

        let ltk = LTKData.items[row]

        cell.imageView.frame.size = cell.frame.size

        let image : UIImage? = LTKImage.get(ltk.ID, ltk.heroURL)
        if image != nil {
            //let size: CGSize = image!.size
            //debugPrint("Using: \(ltk.ID), \(ltk.heroURL)  \(Int(size.width))x\(Int(size.height))")
            cell.imageView.image = image
        }
        else {
            //debugPrint("Using placeholder")
            cell.imageView.image = LTKImage.placeHolderImage
        }

        cell.setNeedsDisplay()
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = (LTKData.itemCount * self.pageIndex) + indexPath.row
        selectedLTK = LTKData.items[row]
        //debugPrint("DidSelectItem showDetail")
        performSegue(withIdentifier: "showDetail", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let vc = segue.destination as! LTKDetailViewController
            vc.ltk = selectedLTK
        }
    }

}



class LTKImageViewCell : UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!

}

