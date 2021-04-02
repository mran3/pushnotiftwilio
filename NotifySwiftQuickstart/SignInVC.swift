//
//  SignInVC.swift
//  NotifySwiftQuickstart
//
//  Created by Andres Acevedo on 1/04/21.
//  Copyright © 2021 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVerify

class SignInVC: UIViewController {
    
    //    MARK: Class properties
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signInBUtton: UIButton!
    
    var serverURL = "https://tuilio.herokuapp.com"
    var pushToken: String = ""
    var twilioVerify: TwilioVerify?
    let session = URLSession.shared
    var pushDeviceToken: String?
    
    //    MARK: Basic UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
        self.activityIndicator.isHidden = true
        self.activityIndicator.hidesWhenStopped = true
    }
    
    
    @IBAction func SignInTapped(_ sender: Any) {
        activityIndicator.startAnimating()
        let name = usernameText.text ?? ""
        let password = passwordText.text ?? ""
        signInBUtton.isEnabled = false
        signInRequest(name: name, password: password)
    }
    
    func finishLoading() {
        DispatchQueue.main.async {
            self.signInBUtton.isEnabled = true
            self.activityIndicator.stopAnimating()
            self.passwordText.text = ""
            self.usernameText.text = ""
        }
    }
    
    //    MARK: Sign In Process
    func signInRequest(name: String, password: String) {
        let url = URL(string: serverURL + "/api/login")
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = ["name": name,
                      "password" : password]
        
        let jsonData = try! JSONSerialization.data(withJSONObject: params, options: [])
        request.httpBody = jsonData
        
        let task = session.dataTask(with: request, completionHandler: {
            (responseData, response, error) in
            
            if let responseData = responseData {
                let responseString = String(data: responseData, encoding: String.Encoding.utf8)
                print("Response Body: \(responseString ?? "")")
                do {
                    let responseObject = try JSONSerialization.jsonObject(with: responseData, options: [])
                    if let responseDictionary = responseObject as? [String: Any] {
                        if let receivedId = responseDictionary["id"] as? String {
                            print("Login request successful: \(receivedId)")
                            DispatchQueue.main.async {
                                let alert = UIAlertController(title: "Success!", message: "Your credentials are correct, if you have 2FA you will be challenged to confirm this sign in attempt in your registered devices.", preferredStyle: UIAlertController.Style.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                                self.present(alert, animated: true, completion: nil)
                            }                            
                            self.finishLoading()
                        }
                    }
                    print("JSON: \(responseObject)")
                } catch let error {
                    print("Error: \(error)")
                    self.finishLoading()
                }
            }
        })
        
        task.resume()
    }
    
    
}
