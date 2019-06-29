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

// cell id
private let reuseIdentifier = "viewCell"

class MainCollectionViewController: UICollectionViewController {
    
    // container for URLs of images to download
    var imageURLArray = [Images]()
    
    // container and key for saving UserDefoults data
    var keysDict = [String: String]()
    let userDefKey = "cachedURLs"
    
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
        return imageURLArray.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
    
        // Configure the cell
        
        // set the author of the photo
        cell.metaDataCell.text = imageURLArray[indexPath.row].author ?? ""
        cell.metaDataCell.layer.cornerRadius = 7
        cell.metaDataCell.clipsToBounds = true
        
        // set the date of loading
        imageURLArray[indexPath.row].date = Date()
        
        // default image size for pre-settings
        let previewImageSize = CGSize(width: 196, height: 135)
        
        // image pre-settings (size, cornerRadius) (using Kingfisher lib)
        let processor = DownsamplingImageProcessor(size: previewImageSize)
                        >> RoundCornerImageProcessor(cornerRadius: 7)
        
        // activity indicator (using Kingfisher lib)
        cell.imageViewCell.kf.indicatorType = .activity
        
        // fetch the URL of image to download
        let url = URL(string: imageURLArray[indexPath.row].downloadUrl ?? "")
        
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
                let image = sender as? Images
                detailVC.image = image
            }
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // passing image data at indexPath
        let image = imageURLArray[indexPath.row]
        performSegue(withIdentifier: "detailVCSegue", sender: image)
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    // MARK: Fethcing and loading images
    
    // fetching data from cache or loading from net if needed
    func fetchData() {
        
        // fetching image URLs from cache
        if let keysDict = UserDefaults.standard.dictionary(forKey: userDefKey) as? [String : String] {
            
            if !keysDict.isEmpty {
                for (author, url) in keysDict {
                    let image = Images()
                    image.author = author
                    image.downloadUrl = url
                    imageURLArray.append(image)
                }
                collectionView.reloadData()
            } else {
                loadImageURLs(from: jsonWithPhotoURLs)
            }
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
                        let image = Images()
                        image.downloadUrl = json[0][i]["download_url"].stringValue
                        image.author = json[0][i]["author"].stringValue
                        self.imageURLArray.append(image)
                        
                        // creating keys to access the cache in future
                        if let urlKey = image.downloadUrl,
                            let authorKey = image.author {
                            self.keysDict[authorKey] = urlKey
                        }
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
                
                // save URLs keys in UserDefaults to access the cache in future
                UserDefaults.standard.set(self.keysDict, forKey: self.userDefKey)
                
                self.collectionView.reloadData()
                self.refreshControl.endRefreshing()
            }
        } else {
            print("Alert! No internet connection!")
            refreshControl.endRefreshing()
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
