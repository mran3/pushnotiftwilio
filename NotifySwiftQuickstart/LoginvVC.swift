//
//  LoginvVC.swift
//  NotifySwiftQuickstart
//
//  Created by Andres Acevedo on 21/03/21.
//  Copyright © 2021 Twilio, Inc. All rights reserved.
//

import UIKit

class LoginVC: UIViewController {
    
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var usernameText: UITextField!
    var serverURL = "http://localhost:5000"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func logIn(_ sender: Any) {
        let name = usernameText.text ?? ""
        let password = passwordText.text ?? ""
        loginRequest(name: name, password: password)
    }
    
    func registerDeviceRequest(id: String) {
        let session = URLSession.shared
        let url = URL(string: serverURL + "/api/devices/token")
        var request = URLRequest(url: url!, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30.0)
        request.httpMethod = "POST"

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let params = ["identity": id]

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
                        
                        }
                    }
                    print("JSON: \(responseObject)")
                } catch let error {
                    print("Error: \(error)")
                }
            }
        })

        task.resume()
    }
    
//    func addCookiesToUrl(with url: URL) -> URLRequest {
//        var request = URLRequest(url: url)
//
//        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
//            return request
//        }
//
//        request.allHTTPHeaderFields = HTTPCookie.requestHeaderFields(with: cookies)
//        return request
//    }
    
    func loginRequest(name: String, password: String) {
        let session = URLSession.shared
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
                            self.registerDeviceRequest(id: receivedId)
                            
//                            var httpResponse: HTTPURLResponse = response as! HTTPURLResponse
                            
//                            if let url = httpResponse.url,
//                               let allHeaderFields = httpResponse.allHeaderFields as? [String : String] {
//                                let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
//                                let cookie = cookies.first
//                                let jar = HTTPCookieStorage.shared
////                                jar.setCookies(cookies, for: nil, mainDocumentURL: nil)
//                                jar.setCookie(cookie!)
//                                let deviceUrl = URL(string: self.serverURL + "/api/devices/token/")!
//                                self.addCookiesToUrl(with: deviceUrl)
//                            }

                        }
                    }
                    print("JSON: \(responseObject)")
                } catch let error {
                    print("Error: \(error)")
                }
            }
        })
        
        task.resume()
    }
    
}
