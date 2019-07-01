//
//  Alert.swift
//  Simple Image Viewer
//
//  Created by Aleksei Chudin on 01/07/2019.
//  Copyright © 2019 Aleksei Chudin. All rights reserved.
//

import UIKit

//extension UIAlertController {
//    convenience init(alertWith title: String, message: String) {
//        self.init(title: title, message: message, preferredStyle: .alert)
//    }
//
//}

extension UIAlertController {
    
    convenience init(alertWith title: String, message: String) {
        self.init(title: title, message: message, preferredStyle: .alert)
    }
    
    convenience init(onViewController: UIViewController,
                     withTitle title: String,
                     withMessage message: String,
                     handler: (() -> Void)? = nil,
                     completion: (() -> Void)? = nil) {
        
        let title = title
        let message = message
        
        self.init(alertWith: title, message: message)
        
        self.addActionWith(title: "OK", style: .default) { action in
            if handler != nil {
                handler!()
            }
        }
        if handler != nil {
            self.addActionWith(title: "Cancel", style: .cancel)
        }
        
        onViewController.present(self, animated: true, completion: completion)
    }
    
    func addActionWith(title: String,
                       style: UIAlertAction.Style = .default,
                       handler: ((UIAlertAction) -> Void)? = nil) {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        self.addAction(action)
    }
    
}

