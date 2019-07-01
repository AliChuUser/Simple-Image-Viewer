//
//  MainCollectionViewController.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 08/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import UIKit
import Kingfisher
import Alamofire
import SwiftyJSON
import RealmSwift

// cell id
private let reuseIdentifier = "viewCell"

class MainCollectionViewController: UICollectionViewController {
    
    // get the default Realm
    let realm = try! Realm()
    
    // container for data of images to download
    var imagesDataArray: Results<Image>?
    
    // net resourse with URLs of images
    let jsonWithPhotoURLs = "https://picsum.photos/v2/list"
    
    // refreshControl property
    let refreshControl = UIRefreshControl()
    
    var alert = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetching data from cache or loading from net if needed
        fetchData()
        
        // pull to refresh configure method
        configureRefreshContorl()
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesDataArray?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! MainCollectionViewCell
        
        guard let imageData = imagesDataArray?[indexPath.row] else { return }
        
        // set the author of the photo
        cell.metaDataCell.text = imageData.author ?? "NoName"
        cell.metaDataCell.layer.cornerRadius = 7
        cell.metaDataCell.clipsToBounds = true
        
        // default image size for pre-settings
        let previewImageSize = CGSize(width: 196, height: 135)
        
        // image pre-settings (size, cornerRadius) (using Kingfisher lib)
        let processor = DownsamplingImageProcessor(size: previewImageSize)
            >> RoundCornerImageProcessor(cornerRadius: 7)
        
        // activity indicator (using Kingfisher lib)
        cell.imageViewCell.kf.indicatorType = .activity
        
        // fetch the URL of image to download
        let url = URL(string: imageData.downloadUrl ?? "")
        
        // set image from cache or from net if needed (using Kingfisher lib)
        cell.imageViewCell.kf.setImage(with: url,
                                       options: [.processor(processor),
                                                 .transition(.fade(0.8)),
                                                 .originalCache(.default)])
        { (result) in
            switch result {
            case .success(let value):
                print("Task done: \(value.source.url?.absoluteString ?? "")")
                print(value.cacheType)
            case .failure(let error):
                print("Loading the image takes some more time: \(error.localizedDescription)")
            }
        }
        
    }
    
    // loading images only at displayed cells
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! MainCollectionViewCell
        cell.imageViewCell.kf.cancelDownloadTask()
    }
    
    // MARK: UICollectionViewDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // prepare and passing image data to detailVC
        if segue.identifier == "detailVCSegue" {
            if let detailVC = segue.destination as? DetailViewController {
                let image = sender as? Image
                detailVC.image = image
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // passing image data at indexPath
        guard let imageData = imagesDataArray?[indexPath.row] else { return }
        performSegue(withIdentifier: "detailVCSegue", sender: imageData)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: Fethcing and loading images
    
    // fetching data from cache or loading from net if needed
    func fetchData() {
        
        if !InternetConnect.isConnected {
            // fetching image data from Realm
            if !realm.objects(Image.self).isEmpty {
                imagesDataArray = realm.objects(Image.self)
                collectionView.reloadData()
                refreshControl.endRefreshing()
            } else {
                alert = UIAlertController(onViewController: self, withTitle: "No internet", withMessage: "Check internet connecion!")
                refreshControl.endRefreshing()
            }
        } else {
            // loading image URLs from net
            loadImageURLs(from: jsonWithPhotoURLs)
        }
        
    }
    
    // loading image URLs from net
    func loadImageURLs(from url: String) {
        
        APIRequest.getData(from: url, result: { (json) in
            self.parseJSON(json)
            self.imagesDataArray = self.realm.objects(Image.self)
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
        }) { (error) in
            print("Alert! Cannot get data from URL: \(error.localizedDescription)")
            self.alert = UIAlertController(onViewController: self, withTitle: "Cannot get data from server!", withMessage: "Try again later")
        }
    }
    
    func parseJSON(_ json: JSON) {
        if !realm.objects(Image.self).isEmpty {
            do {
                try realm.write {
                    realm.deleteAll()
                }
            } catch {
                print("Error cleaning Realm: \(error.localizedDescription)")
            }
        }
        
        for i in 0..<json[0].count {
            let jsonPath = json[0][i]
            let image = Image()
            image.id = jsonPath["id"].intValue
            image.author = jsonPath["author"].stringValue
            image.width = jsonPath["width"].intValue
            image.height = jsonPath["height"].intValue
            image.url = jsonPath["url"].stringValue
            image.downloadUrl = json[0][i]["download_url"].stringValue
            image.date = Date()
            self.save(imageData: image)
        }
    }
    
    func save(imageData: Image) {
        do {
            try realm.write {
                realm.add(imageData)
            }
        } catch {
            print("Error saving imageData: \(error.localizedDescription)")
        }
    }
    
    // MARK: Refreshing methods
    
    // pull to refresh configure method
    func configureRefreshContorl() {
        
        collectionView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
    }
    
    // refresh action
    @objc func refreshData(_ sender: Any) {
        
        fetchData()
    }

}
