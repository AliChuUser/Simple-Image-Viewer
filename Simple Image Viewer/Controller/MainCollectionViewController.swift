//
//  MainCollectionViewController.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 08/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import UIKit
import Kingfisher
import SwiftyJSON
import RealmSwift

// cell id
private let reuseIdentifier = "viewCell"

class MainCollectionViewController: UICollectionViewController {
    
    // get the default Realm
    let realm = try! Realm()
    
    // container for data of images to download
    var imagesDataArray: Results<Image>?
    
    // net resource with data of images
    let jsonWithPhotos = "https://pixabay.com/api/?key=12925092-56f91107b881b95d2f175794e"
    
    // refreshControl property
    let refreshControl = UIRefreshControl()
    
    // alert property
    var alert = UIAlertController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetching data from cache or loading from net if needed
        fetchData()
        
        // pull to refresh configure method
        configureRefreshContorl()
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
                alert = UIAlertController(onViewController: self, withTitle: "No internet", withMessage: "Check internet connection!")
                refreshControl.endRefreshing()
            }
        } else {
            // loading image data from net
            loadImageData(from: jsonWithPhotos)
        }
    }
    
    // loading image data from net
    func loadImageData(from url: String) {
        
        // network request
        APIRequest.getData(from: url, result: { json in
            self.parseJSON(json)
            self.imagesDataArray = self.realm.objects(Image.self)
            self.collectionView.reloadData()
            self.refreshControl.endRefreshing()
        }) { error in
            print("Alert! Unable to retrieve data from URL: \(error.localizedDescription)")
            self.alert = UIAlertController(onViewController: self, withTitle: "Unable to retrieve data from server!", withMessage: "Try again later")
        }
    }
    
    // parse JSON and save to Realm
    func parseJSON(_ json: JSON) {
        
        // clear Realm from old data
        if !realm.objects(Image.self).isEmpty {
            do {
                try realm.write {
                    realm.deleteAll()
                }
            } catch {
                print("Error cleaning Realm: \(error.localizedDescription)")
            }
        }
        
        // parse JSON and save new data from JSON to Realm
        for i in 0..<json[0]["hits"].count {
            let jsonPath = json[0]["hits"][i]
            let image = Image()
            image.id = jsonPath["id"].intValue
            image.user = jsonPath["user"].stringValue
            image.imageWidth = jsonPath["imageWidth"].intValue
            image.imageHeight = jsonPath["imageHeight"].intValue
            image.imageSize = jsonPath["imageSize"].intValue
            image.previewURL = jsonPath["previewURL"].stringValue
            image.largeImageURL = jsonPath["largeImageURL"].stringValue
            image.pageURL = jsonPath["pageURL"].stringValue
            image.userAvatar = jsonPath["userImageURL"].stringValue
            image.date = Date()
            self.save(imageData: image)
        }
    }
    
    // save data to Realm
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

    // MARK: UICollectionViewDataSource

extension MainCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imagesDataArray?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
        return cell
    }
    
    // loading images only at displayed cells
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! MainCollectionViewCell
        
        guard let imageData = imagesDataArray?[indexPath.row] else { return }
        
        // set the author of the photo
        cell.metaDataCell.text = imageData.user ?? "NoName"
        cell.metaDataCell.layer.cornerRadius = 7
        cell.metaDataCell.clipsToBounds = true
        
        // image pre-settings (using Kingfisher lib)
        let processor = RoundCornerImageProcessor(cornerRadius: 7)
        
        // activity indicator (using Kingfisher lib)
        cell.imageViewCell.kf.indicatorType = .activity
        
        // fetch the URL of image to download
        let url = URL(string: imageData.previewURL ?? "")
        
        // set image from cache or from net if needed (using Kingfisher lib)
        cell.imageViewCell.kf.setImage(with: url,
                                       options: [.processor(processor),
                                                 .transition(.fade(0.8)),
                                                 .originalCache(.default)])
        { result in
            switch result {
            case .success(let value):
                print("Task done: \(value.source.url?.absoluteString ?? "")")
                print(value.cacheType)
            case .failure(let error):
                print("Loading the image takes some more time: \(error.localizedDescription)")
            }
        }
        
    }
    
    // cancel loading images into non-displayable cells
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = cell as! MainCollectionViewCell
        cell.imageViewCell.kf.cancelDownloadTask()
    }
}

    // MARK: UICollectionViewDelegate

extension MainCollectionViewController {
    
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
    
}
