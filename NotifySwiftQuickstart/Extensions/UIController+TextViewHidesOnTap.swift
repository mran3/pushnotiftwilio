//
//  UIController+TextViewHidesOnTap.swift
//  NotifySwiftQuickstart
//
//  Created by Andres Acevedo on 1/04/21.
//  Copyright © 2021 Twilio, Inc. All rights reserved.
//

import UIKit

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
