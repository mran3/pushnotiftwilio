//
//  AppDelegate.swift
//  notifications
//
//  Created by Siraj Raval on 2/24/16.
//  Copyright © 2016 twilio. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var devToken: String?
    var environment: APNSEnvironment?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        if #available(iOS 10, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (granted, error) in
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            })
            center.delegate = self
        } else {
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            UIApplication.shared.registerForRemoteNotifications()
        }
        
        self.environment = ProvisioningProfileInspector().apnsEnvironment()
        var envString = "Unknown"
        if environment != APNSEnvironment.unknown {
            if environment == APNSEnvironment.development {
                envString = "Development"
            } else {
                envString = "Production"
            }
        }
        print("APNS Environment detected as: \(envString) ");
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenChars = (deviceToken as NSData).bytes.bindMemory(to: CChar.self, capacity: deviceToken.count)
        var tokenString = ""
        for i in 0..<deviceToken.count {
            tokenString += String(format: "%02.2hhx", arguments: [tokenChars[i]])
        }
        print("Received device push token data! \(tokenString)")
        devToken = tokenString
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Couldn't register: \(error)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        print("Message received.")
        if let aps = userInfo[AnyHashable("aps")] as? [AnyHashable: Any] {
            if let alert = aps[AnyHashable("alert")] as? String {
                let alertController = UIAlertController(title: "Incoming Notification", message: alert, preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                self.window?.rootViewController?.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
}


extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // called if app is running in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if notification.request.identifier == "SuccessRegistering2FA" {
            completionHandler(.alert)
            return
        }
        guard let payload = notification.request.content.userInfo as? [String: Any] else {
            completionHandler(.alert)
            return
        }
        showChallenge(payload: payload)
        completionHandler(.sound)
    }
    
    // called if app is running in background
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        defer { completionHandler() }
        
        if response.actionIdentifier == "SuccessRegistering2FA" {
            return
        }
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let payload = response.notification.request.content.userInfo as? [String: Any] else {
            return
        }
        
        showChallenge(payload: payload)
    }
}

private extension AppDelegate {
    func showChallenge(payload: [String: Any]) {
        dismissAnyAlertControllerIfPresent(payload: payload, withCompletionHandler: { [weak self]
            (payload) in
            guard let self = self else {
                return
            }
            guard let challengeSid = payload["challenge_sid"] as? String,
                  let factorSid = payload["factor_sid"] as? String,
                  let type = payload["type"] as? String, type == "verify_push_challenge" else {
                return
            }
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            guard let challengesVC = storyboard.instantiateViewController(withIdentifier: "challengesVC") as? ChallengesVC else {
                print("No challengesVC controller")
                return
            }
            challengesVC.challengeSid = challengeSid
            challengesVC.factorSid = factorSid
    
            self.window?.rootViewController?.present(challengesVC, animated: true)
            
        })
        
        
    }
    
    func dismissAnyAlertControllerIfPresent(payload: [String: Any], withCompletionHandler completionHandler: @escaping ([String: Any]) -> Void) {
        guard let window :UIWindow = UIApplication.shared.keyWindow , var topVC = window.rootViewController?.presentedViewController else {return}
        while topVC.presentedViewController != nil  {
            topVC = topVC.presentedViewController!
        }
        if topVC.isKind(of: UIAlertController.self) {
            topVC.dismiss(animated: false, completion: {
                completionHandler(payload)
            })
        }
    }
    
}
