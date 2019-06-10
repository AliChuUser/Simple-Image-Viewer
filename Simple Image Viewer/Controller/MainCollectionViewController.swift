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
    
    // net resourse with URLs of image
    let jsonWithPhotoURLs = "https://picsum.photos/v2/list"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // fetching data from cache or loading from net if needed
        fetchData()
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageURLArray.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! MainCollectionViewCell
    
        // Configure the cell
        
        // fetch the URL of image to download
        let url = URL(string: imageURLArray[indexPath.row].imageURL ?? "")
        
        // set the author of the photo
        cell.metaDataCell.text = imageURLArray[indexPath.row].author ?? ""
        cell.metaDataCell.layer.cornerRadius = 7
        cell.metaDataCell.clipsToBounds = true
        
        // set the date of loading
        imageURLArray[indexPath.row].date = Date()
        
        // default image size for pre-settings
        let defaultImageSize = CGSize(width: 100, height: 80)
        
        // image pre-settings (size, cornerRadius) (using Kingfisher lib)
        let processor = DownsamplingImageProcessor(size: cell.imageViewCell.image?.size ?? defaultImageSize)
                        >> RoundCornerImageProcessor(cornerRadius: 7)
        
        // activity indicator (using Kingfisher lib)
        cell.imageViewCell.kf.indicatorType = .activity
        
        // set image from cache or from net if needed (using Kingfisher lib)
        cell.imageViewCell.kf.setImage(with: url,
                                       placeholder: UIImage(named: "photo"),
                                       options: [.processor(processor), .transition(.fade(0.8)), .cacheOriginalImage])
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
        if let keysDict = UserDefaults.standard.persistentDomain(forName: userDefKey) as? [String : String] {
            
            if !keysDict.isEmpty {
                for (author, url) in keysDict {
                    let image = Images()
                    image.author = author
                    image.imageURL = url
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
        
        // net request with Alamofire
        AF.request(url).validate().responseJSON { (response) in
            
            // data handling with SwiftyJSON
            switch response.result {
            case .success(let data):
                
                let json = JSON(arrayLiteral: data)
                for i in 0..<json[0].count {
                    let image = Images()
                    image.imageURL = json[0][i]["download_url"].stringValue
                    image.author = json[0][i]["author"].stringValue
                    self.imageURLArray.append(image)
                    
                    // creating keys to access the cache in future
                    if let urlKey = image.imageURL,
                       let authorKey = image.author {
                        self.keysDict[authorKey] = urlKey
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
            
            // save URLs keys in UserDefaults to access the cache in future
            UserDefaults.standard.setPersistentDomain(self.keysDict, forName: self.userDefKey)
            
            self.collectionView.reloadData()
        }
    }

}
