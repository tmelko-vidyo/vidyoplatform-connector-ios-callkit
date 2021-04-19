//
//  HomeViewController.swift
//  VidyoConnector
//
//  Created by taras.melko on 01.03.2021.
//

import UIKit

struct ConnectParams {
    let portal: String
    let roomKey: String
    let displayName: String
    let pin: String
    
    let autoJoin: Bool
}

class HomeViewController: UIViewController {
    
    let presetParams = ConnectParams(portal: "*.vidyocloud.com",
                                   roomKey: "*.room.key",
                                   displayName: "John Doe",
                                   pin: "",
                                   autoJoin: true)

    @IBOutlet weak var portal: UITextField!
    @IBOutlet weak var roomKey: UITextField!
    @IBOutlet weak var displayName: UITextField!
    @IBOutlet weak var pin: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Once per app lifecycle. */
        VCConnectorPkg.vcInitialize()

        portal.text = presetParams.portal
        roomKey.text = presetParams.roomKey
        displayName.text = presetParams.displayName
        pin.text = presetParams.pin
                
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleCallStateNotification(notification:)),
                                               name: CallManager.CallsChangedNotification,
                                               object: nil)
    }
    
    @IBAction func onOutgoingCallRequested(_ sender: Any) {
        print("Start outgoing call")

        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("appdelegate is missing")
            return
        }
        
        appdelegate.callManager.startCall(handle: "Vidyo User Outgoing")
    }
    
    @IBAction func onIncomingCallRequestedWithDelay(_ sender: Any) {
        print("Start incoming call in 3 sec...")
        
        guard let appdelegate = UIApplication.shared.delegate as? AppDelegate else {
            print("appdelegate is missing")
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            appdelegate.displayIncomingCall(uuid: UUID(), handle: "Vidyo User Incoming")
        }
    }
    
    @objc func handleCallStateNotification(notification: NSNotification) {
        if let action = notification.userInfo?["action"] as? String, action == CallManager.CallState.startVideoCall.rawValue {
            startConference()
        }
    }
    
    func startConference() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let conference = storyboard.instantiateViewController(withIdentifier: "Conference") as! ConferenceViewController
        if #available(iOS 13.0, *) {
            conference.isModalInPresentation = true
        } else {
            // Fallback on earlier versions
        }
        
        conference.connectParams = ConnectParams(portal: self.portal.text!,
                                                 roomKey: self.roomKey.text!,
                                                 displayName: self.displayName.text!,
                                                 pin: self.pin.text!,
                                                 autoJoin: true)
        
        self.present(conference, animated: true)
    }
}
