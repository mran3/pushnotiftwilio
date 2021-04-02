//
//  LoginvVC.swift
//  NotifySwiftQuickstart
//
//  Created by Andres Acevedo on 21/03/21.
//  Copyright © 2021 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVerify

class RegisterVC: UIViewController {
    
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var logInButton: UIButton!
    
    var serverURL = "https://tuilio.herokuapp.com"
    var pushToken: String = ""
    var twilioVerify: TwilioVerify?
    let session = URLSession.shared
    var pushDeviceToken: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        self.hideKeyboardWhenTappedAround()
        self.activityIndicator.isHidden = true
        self.activityIndicator.hidesWhenStopped = true
    }
    
    @IBAction func logIn(_ sender: Any) {
        activityIndicator.startAnimating()
        let name = usernameText.text ?? ""
        let password = passwordText.text ?? ""
        logInButton.isEnabled = false
        loginRequest(name: name, password: password)
    }
    
    func createFactor(accessToken: String, serviceSid:String, identity: String) {
        do {
            twilioVerify = try TwilioVerifyBuilder().build()
        } catch let error {
            print("Error creating factor: \(error)")
            self.finishLoading()
            return
        }
        DispatchQueue.main.async {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            guard let pushDeviceToken =  appDelegate.devToken else {
                print("No device token. Push Notifications doesn't work on simulator")
                return
            }
            
            let payload = PushFactorPayload(
                friendlyName: "iphone3113770",
                serviceSid: serviceSid,
                identity: identity,
                pushToken: pushDeviceToken,
                accessToken: accessToken
            )
            self.twilioVerify!.createFactor(withPayload: payload, success: { factor in
                print("Success creating factor")
                self.verifyFactor(identity: factor.identity, factorSid: factor.sid)
            }) { error in
                print("Error creating factor. (Could be due to max 20 factors allowance).")
                self.finishLoading()
            }
        }
        
    }
    
    func verifyFactor(identity:String, factorSid: String){
        let payload = VerifyPushFactorPayload(sid: factorSid)
        twilioVerify!.verifyFactor(withPayload: payload, success: {[weak self] factor in
            print("suces verifying factor")
            guard let self = self else {
                return
            }
            self.registerFactor(userId: identity, factorSid: factor.sid)
            
        }) { error in
            print("erro verifying factor")
            self.finishLoading()
        }
        
    }
    
    func getNewFactorPayload(userId: String) {
        let url = URL(string: serverURL + "/api/devices/token/")
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = ["identity": userId]
        
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
                        guard let token = responseDictionary["token"] as? String else {
                            print("return")
                            return
                        }
                        guard let serviceSid = responseDictionary["serviceSid"] as? String else {
                            print("return")
                            return
                        }
                        guard let identity = responseDictionary["identity"] as? String else {
                            print("return")
                            return
                        }
                        self.createFactor(accessToken: token, serviceSid: serviceSid, identity: identity)
                    }
                    //                    print("JSON: \(responseObject)")
                } catch let error {
                    print("Error: \(error)")
                    self.finishLoading()
                }
            }
        })
        task.resume()
    }
    
    
    func registerFactor(userId: String, factorSid: String) {
        let url = URL(string: serverURL + "/api/devices/register/")
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = "POST"
        
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let params = ["identity": userId,
                      "sid": factorSid]
        
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
                        if let done = responseDictionary["done"] as? Bool, done == true {
                            print("Device sucessfully registered for 2FA.")
                            self.notifyRegistered()                            
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
    
    func finishLoading() {
        DispatchQueue.main.async {
            self.logInButton.isEnabled = true
            self.activityIndicator.stopAnimating()
            self.passwordText.text = ""
            self.usernameText.text = ""
        }
    }
    func notifyRegistered(){
        finishLoading()        
        let content = UNMutableNotificationContent()
        
        //adding title, subtitle, body and badge
        content.title = "Twilio 2FA"
        content.subtitle = "Device registered"
        content.body = "Now you can enjoy Push 2FA"
        content.badge = 1
        
        //getting the notification trigger
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        //getting the notification request
        let request = UNNotificationRequest(identifier: "SuccessRegistering2FA", content: content, trigger: trigger)
        
        //adding the notification to notification center
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    func loginRequest(name: String, password: String) {
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
                            print("Id: \(receivedId)")
                            self.getNewFactorPayload(userId: receivedId)
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}
