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
    
    // container and key for saving UserDefoults data
//    var keysDict = [String: String]()
//    let userDefKey = "cachedURLs"
    
    // net resourse with URLs of images
    let jsonWithPhotoURLs = "https://picsum.photos/v2/list"
    
    // refreshControl property
    let refreshControl = UIRefreshControl()
    
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
    
        // Configure the cell
        
        guard let imageData = imagesDataArray?[indexPath.row] else { return cell }
        
        // set the author of the photo
        cell.metaDataCell.text = imageData.author ?? "NoName"
        cell.metaDataCell.layer.cornerRadius = 7
        cell.metaDataCell.clipsToBounds = true
        
        // set the date of loading -> This not allow by Realm - need to be set during save func
        //imageData.date = Date()
        
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
                                       placeholder: UIImage(named: "photo"),
                                       options: [.processor(processor), .transition(.fade(0.8)), .originalCache(.default)])
        { (result) in
            switch result {
            case .success(let value):
                print("Task done: \(value.source.url?.absoluteString ?? "")")
                print(value.cacheType)
            case .failure(let error):
                print("Loading the image takes some more time: \(error.localizedDescription)")
            }
        }
    
        return cell
    }

    // MARK: UICollectionViewDelegate
    
    // loading images only at displayed cells
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
        
        cell.imageViewCell.kf.cancelDownloadTask()
    }
    
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
        
        // fetching image data from Realm
        if !realm.objects(Image.self).isEmpty {
            imagesDataArray = realm.objects(Image.self)
            collectionView.reloadData()
        } else {
            loadImageURLs(from: jsonWithPhotoURLs)
        }
        
        // loading image URLs from net
        loadImageURLs(from: jsonWithPhotoURLs)
    }
    
    // loading image URLs from net
    func loadImageURLs(from url: String) {
        
        if InternetConnect.isConnected {
            
            // net request with Alamofire
            AF.request(url).validate().responseJSON { (response) in
                
                // data handling with SwiftyJSON
                switch response.result {
                case .success(let data):
                    
                    let json = JSON(arrayLiteral: data)
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
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
                self.imagesDataArray = self.realm.objects(Image.self)
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        } else {
            print("Alert! No internet connection!")
            refreshControl.endRefreshing()
        }
    }
    
    func save(imageData: Image) {
        do {
            try realm.write {
                realm.add(imageData)
            }
        } catch {
            print("Error saving imageData \(error.localizedDescription)")
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
