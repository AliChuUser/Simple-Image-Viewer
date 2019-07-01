//
//  Images.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 08/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import Foundation
import RealmSwift

// Image model
class Image: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var user: String? = nil
    @objc dynamic var imageWidth: Int = 0
    @objc dynamic var imageHeight: Int = 0
    @objc dynamic var imageSize: Int = 0
    @objc dynamic var previewURL: String? = nil
    @objc dynamic var largeImageURL: String? = nil
    @objc dynamic var pageURL: String? = nil
    @objc dynamic var userAvatar: String? = nil
    @objc dynamic var date: Date? = nil
}
