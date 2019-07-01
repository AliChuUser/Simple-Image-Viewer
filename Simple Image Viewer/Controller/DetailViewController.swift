//
//  DetailViewController.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 08/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import UIKit
import Kingfisher
//import Alamofire

class DetailViewController: UIViewController {
    
    var image: Image?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadFullImage()
    }
    
    // load image from cache or from net if needed
    func loadFullImage() {
        
        // check if image has data
        guard let downloadUrl = image?.downloadUrl,
              let url = URL(string: downloadUrl)
            else {
                print("There is no imageURL in image!")
                return
        }
        
        imageView.kf.indicatorType = .activity
        
        // set image from cache or load from net if needed (using Kingfisher lib)
        let cache = ImageCache.default
        
        // memory image expires after 1 day
        cache.memoryStorage.config.expiration = .days(1)
        // disk image expires afetr 30 days
        cache.diskStorage.config.expiration = .days(30)
        
        if cache.isCached(forKey: url.absoluteString) {
            cache.retrieveImage(forKey: url.absoluteString) { (result) in
                switch result {
                case .success(let value):
                    guard let image = value.image else {
                        print("There is no image in cache")
                        return
                    }
                    print("Got from cache")
                    DispatchQueue.main.async {
                        self.imageView.image = image
                    }
                case .failure(let error):
                    print("Cannot retrieve image from cache: \(error.localizedDescription)")
                }
            }
        } else {
            print("Getting from net")
            
            if InternetConnect.isConnected {
                imageView.kf.setImage(with: url)
            } else {
                print("Alert! No internet connection!")
            }
            
        }
        
        // set the autor label
        label.text = image?.author
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        
        // set the date
        guard let date = image?.date else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        dateLabel.text = dateFormatter.string(from: date)
        dateLabel.layer.cornerRadius = 8
        dateLabel.clipsToBounds = true
    }
}
