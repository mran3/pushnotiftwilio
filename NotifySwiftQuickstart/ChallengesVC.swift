//
//  ChallengesVC.swift
//  NotifySwiftQuickstart
//
//  Created by Andres Acevedo on 28/03/21.
//  Copyright © 2021 Twilio, Inc. All rights reserved.
//

import UIKit
import TwilioVerify

class ChallengesVC: UIViewController{
    var challengeSid: String?
    var factorSid: String?
    var twilioVerify: TwilioVerify?
    @IBOutlet weak var challengeDescription: UILabel!
    @IBOutlet weak var challengeExpiration: UILabel!
    @IBOutlet weak var approveBtn: UIButton!
    @IBOutlet weak var denyBtn: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.startAnimating()
        self.activityIndicator.hidesWhenStopped = true
        do {
            twilioVerify = try TwilioVerifyBuilder().build()
        } catch let error {
            print("Error instantiating TwilioVerify: \(error)")
            return
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        getChallengeDetails()
    }
    
    @IBAction func approveChallengeTapped(_ sender: Any) {
        updateChallenge(approve: .approved)
    }
    
    @IBAction func denyChallengeTapped(_ sender: Any) {
        updateChallenge(approve: .denied)
        self.navigationController?.popViewController(animated: false)
    }
    
    func getChallengeDetails() {
        guard let twilioVerify = twilioVerify, let challengeSid = challengeSid, let factorSid = factorSid else {
            showInvalidChallenge()
            return
        }
        twilioVerify.getChallenge(challengeSid: challengeSid, factorSid: factorSid, success: { challenge in
            print(challenge)
            let dateFormatterPrint = DateFormatter()
            dateFormatterPrint.dateFormat = "MMM dd,yyyy HH:mm"

            let formattedDate = dateFormatterPrint.string(from: challenge.expirationDate)
            
            DispatchQueue.main.async {
                self.challengeDescription.text = challenge.challengeDetails.message
                self.challengeExpiration.text = formattedDate
                self.activityIndicator.stopAnimating()
            }
            // Success
        }) { error in
            // Error
        }
    }
    
    func showInvalidChallenge(){
        let alert = UIAlertController(title: "Alert", message: "Invalid Challenge", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in
            self.dismiss(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func updateChallenge(approve: ChallengeStatus){
        guard let twilioVerify = twilioVerify, let challengeSid = challengeSid, let factorSid = factorSid else {
            showInvalidChallenge()
            return
        }
        
        let payload = UpdatePushChallengePayload(
            factorSid: factorSid,
            challengeSid: challengeSid,
            status: approve
        )
        twilioVerify.updateChallenge(withPayload: payload, success: {
            // Success
            print("Challenge updated")
            DispatchQueue.main.async {
                let message = payload.status == .approved ? "Authenticated" : "Rejected"
                let alert = UIAlertController(title: message, message: "Thank you!", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in
                    self.dismiss(animated: true)
                }))
                self.present(alert, animated: true, completion: nil)
            }
        }) { error in
            // Error
        }
    }
    
}
