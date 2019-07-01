//
//  APIRequest.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 01/07/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

// network request
class APIRequest {
    
    static func getData(from url: String,
                        result resultCallback: @escaping (JSON) -> Void,
                        error errorCallback: @escaping (Error) -> Void) {
        
        AF.request(url).validate().responseJSON { (response) in
            switch response.result {
            case .success(let data):
                let json = JSON(arrayLiteral: data)
                resultCallback(json)
            case .failure(let error):
                errorCallback(error)
            }
        }
    }
}
