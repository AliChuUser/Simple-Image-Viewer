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
    @objc dynamic var author: String? = nil
    @objc dynamic var width: Int = 0
    @objc dynamic var height: Int = 0
    @objc dynamic var url: String? = nil
    @objc dynamic var downloadUrl: String? = nil
    @objc dynamic var date: Date? = nil
}
