//
//  InternetConnect.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 29/06/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import Foundation
import Alamofire

// Check internet connection status
class InternetConnect {
    
    static var isConnected: Bool {
        guard let networkManager = NetworkReachabilityManager() else {
            print("Unable to get internet connection status")
            return false}
        return networkManager.isReachable
    }
}
