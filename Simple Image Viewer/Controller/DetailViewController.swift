//
//  DetailViewController.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 08/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import UIKit
import Kingfisher

class DetailViewController: UIViewController {
    
    var image: Images?
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadImage()
    }
    
    // load image from cache or from net if needed
    func loadImage() {
        
        // check if image has data
        guard let imageURL = image?.imageURL,
              let url = URL(string: imageURL)
            else {
                print("There is no imageURL in image!")
                return
        }
        
        // set image from cache or load from net if needed (using Kingfisher lib)
        imageView.kf.setImage(with: url)
        
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
